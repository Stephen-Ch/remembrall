Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-NormalizedRelativePath {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $trimmed = $Path.Trim()
    if ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'")) {
        $trimmed = $trimmed.Substring(1, $trimmed.Length - 2)
    } elseif ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        $trimmed = $trimmed.Substring(1, $trimmed.Length - 2)
    }

    $trimmed = $trimmed -replace '\\', '/'
    $trimmed = $trimmed.Trim()
    $trimmed = $trimmed.TrimEnd('/')

    return $trimmed
}

function Get-VibePacketConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $configPath = Join-Path $RepoRoot '.vibekit/config.yml'
    if (-not (Test-Path $configPath)) {
        return [pscustomobject]@{
            Exists = $false
            Path = $configPath
            DocsRoot = $null
            PacketEnabled = $null
            PacketPath = $null
            LegacyPath = $null
        }
    }

    $docsRoot = $null
    $packetEnabled = $null
    $packetPath = $null
    $legacyPath = $null
    $inPacketSection = $false

    foreach ($rawLine in (Get-Content -LiteralPath $configPath)) {
        $line = $rawLine.TrimEnd()
        if (-not $line) { continue }
        if ($line -match '^\s*#') { continue }

        if ($line -match '^\s*docsRoot\s*:\s*(.+?)\s*$') {
            $docsRoot = ConvertTo-NormalizedRelativePath -Path $Matches[1]
            continue
        }

        if ($line -match '^\s*packetForExternalAI\s*:\s*$') {
            $inPacketSection = $true
            continue
        }

        if ($line -match '^\S') {
            $inPacketSection = $false
        }

        if ($inPacketSection -and $line -match '^\s*(enabled|path|legacyPath)\s*:\s*(.+?)\s*$') {
            $key = $Matches[1]
            $valueRaw = $Matches[2].Trim()
            if ($key -eq 'enabled') {
                $value = ($valueRaw -replace "'", '' -replace '"', '').Trim().ToLowerInvariant()
                if ($value -eq 'true') { $packetEnabled = $true }
                elseif ($value -eq 'false') { $packetEnabled = $false }
            } elseif ($key -eq 'path') {
                $packetPath = ConvertTo-NormalizedRelativePath -Path $valueRaw
            } elseif ($key -eq 'legacyPath') {
                $legacyPath = ConvertTo-NormalizedRelativePath -Path $valueRaw
            }
        }
    }

    return [pscustomobject]@{
        Exists = $true
        Path = $configPath
        DocsRoot = $docsRoot
        PacketEnabled = $packetEnabled
        PacketPath = $packetPath
        LegacyPath = $legacyPath
    }
}

function Resolve-VibePacketPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$DocsRoot
    )

    $config = Get-VibePacketConfig -RepoRoot $RepoRoot

    $legacyDefault = if ($DocsRoot -eq '.') { 'forGPT' } else { "$DocsRoot/forGPT" }
    $futureDefault = if ($DocsRoot -eq '.') { 'packet-for-external-ai' } else { "$DocsRoot/packet-for-external-ai" }

    $legacyPath = if ($config.LegacyPath) { $config.LegacyPath } else { $legacyDefault }
    $configPath = if ($config.PacketPath) { $config.PacketPath } else { $null }
    $futurePath = $futureDefault

    $enabled = if ($null -eq $config.PacketEnabled) { $true } else { [bool]$config.PacketEnabled }

    $selectedPath = $legacyPath
    $source = 'legacy-default'
    $exists = Test-Path (Join-Path $RepoRoot ($legacyPath -replace '/', '\'))
    $notes = [System.Collections.Generic.List[string]]::new()

    if ($config.Exists -and $config.DocsRoot -and $config.DocsRoot -ne $DocsRoot) {
        $notes.Add("Config docsRoot ($($config.DocsRoot)) differs from resolved docsRoot ($DocsRoot); keeping resolved docsRoot.")
    }

    if (-not $enabled) {
        $source = 'disabled'
        $selectedPath = $legacyPath
        $exists = Test-Path (Join-Path $RepoRoot ($selectedPath -replace '/', '\'))
        $notes.Add('packetForExternalAI.enabled=false in config; packet remains disabled.')
    } else {
        if ($configPath) {
            $configExists = Test-Path (Join-Path $RepoRoot ($configPath -replace '/', '\'))
            if ($configExists) {
                $selectedPath = $configPath
                $source = 'config'
                $exists = $true
            } else {
                $notes.Add("Configured packet path '$configPath' not found on disk; falling back by compatibility rules.")
            }
        }

        if ($source -ne 'config') {
            $legacyExists = Test-Path (Join-Path $RepoRoot ($legacyPath -replace '/', '\'))
            if ($legacyExists) {
                $selectedPath = $legacyPath
                $source = 'legacy'
                $exists = $true
            } else {
                $futureExists = Test-Path (Join-Path $RepoRoot ($futurePath -replace '/', '\'))
                if ($futureExists) {
                    $selectedPath = $futurePath
                    $source = 'future-default'
                    $exists = $true
                } else {
                    $selectedPath = $legacyPath
                    $source = 'missing'
                    $exists = $false
                }
            }
        }
    }

    return [pscustomobject]@{
        DocsRoot = $DocsRoot
        PacketPath = $selectedPath
        PacketPathSource = $source
        PacketEnabled = $enabled
        Exists = $exists
        ConfigExists = $config.Exists
        ConfigPath = $config.Path
        ConfigPacketPath = $configPath
        LegacyPath = $legacyPath
        FutureDefaultPath = $futurePath
        Notes = @($notes)
    }
}
