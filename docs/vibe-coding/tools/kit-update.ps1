<#
.SYNOPSIS
  Explicit consumer kit update/repair path with strict preflight gates.
.DESCRIPTION
  Run this from a consumer repo that embeds vibe-coding-kit via git subtree.
  This command verifies the upstream ref, hard-stops on unsafe repo state,
  performs a controlled subtree pull only after verification, and then
  re-checks local parity. Packet sync is intentionally out of scope.
.PARAMETER RemoteName
  Optional remote name override. When omitted, the script auto-discovers a
  likely vibe-coding-kit remote from local git config.
.PARAMETER Ref
    Remote ref to verify and pull. Defaults to release/consumer-payload.
.PARAMETER WhatIf
  Print the verified mutation plan without running the subtree pull.
#>
[CmdletBinding()]
param(
    [string]$RemoteName,
    [string]$Ref = "release/consumer-payload",
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-GitSafe {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & git @GitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            $ErrorActionPreference = $prevEAP
            $errText = ($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | Out-String).Trim()
            if (-not $errText) { $errText = ($output | Out-String).Trim() }
            throw "git $($GitArgs -join ' ') failed (exit $LASTEXITCODE): $errText"
        }
        return $output
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

function Normalize-RepoPath {
    param([string]$Path)

    if (-not $Path) { return "" }
    return (($Path -replace '\\', '/') -replace '^\./', '').TrimStart('/')
}

function Get-StatusPath {
    param([string]$StatusLine)

    $path = $StatusLine.Substring(3).Trim()
    if ($path -match ' -> (.+)$') {
        $path = $Matches[1]
    }
    return Normalize-RepoPath $path
}

function Read-KitVersionData {
    param([string]$VersionFile)

    $result = [ordered]@{
        Version   = "(unknown)"
        Effective = "(unknown)"
        Raw       = ""
    }

    if (Test-Path $VersionFile) {
        $content = Get-Content $VersionFile -Raw
        $result.Raw = $content
        if ($content -match '\*\*Version:\*\*\s*(v[\d.]+)') {
            $result.Version = $Matches[1]
        }
        if ($content -match '\*\*Effective Date:\*\*\s*(\d{4}-\d{2}-\d{2})') {
            $result.Effective = $Matches[1]
        }
    }

    return [pscustomobject]$result
}

function Write-RequiredActions {
    param([string[]]$Actions)

    if (-not $Actions -or $Actions.Count -eq 0) { return }

    Write-Host ""
    Write-Host "Required Actions:" -ForegroundColor Yellow
    $Actions | Select-Object -Unique | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

function Fail-KitUpdate {
    param(
        [string]$Summary,
        [string[]]$Actions,
        [string[]]$Details
    )

    Write-Host "HARD STOP: $Summary" -ForegroundColor Red
    if ($Details) {
        foreach ($detail in $Details) {
            Write-Host "  $detail" -ForegroundColor Yellow
        }
    }
    Write-RequiredActions $Actions
    throw "__KIT_UPDATE_STOP__"
}

function Get-DirtyPacketClassification {
    param(
        [string[]]$RelativePaths,
        [System.Collections.Generic.HashSet[string]]$GeneratedPaths,
        [string]$ManifestRelative,
        [string]$RepoRoot
    )

    $classification = [ordered]@{
        MirrorDrift    = @()
        PreserveWorthy = @()
    }

    foreach ($path in $RelativePaths) {
        if ($path -eq $ManifestRelative -or -not $GeneratedPaths.Contains($path)) {
            $classification.PreserveWorthy += $path
            continue
        }

        $fullPath = Join-Path $RepoRoot $path
        if (Test-Path $fullPath) {
            try {
                $marker = Select-String -Path $fullPath -Pattern '<<<<<<<|=======|>>>>>>>' -SimpleMatch:$false -ErrorAction Stop
                if ($marker) {
                    $classification.PreserveWorthy += $path
                    continue
                }
            } catch {
                $classification.PreserveWorthy += $path
                continue
            }
        }

        $classification.MirrorDrift += $path
    }

    return [pscustomobject]$classification
}

function Invoke-SnapshotIsolationEnforcement {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$DocsRoot,
        [Parameter(Mandatory)][string]$SubtreePrefix,
        [switch]$WhatIf
    )

    $candidates = @(
        (Join-Path $RepoRoot (Join-Path $DocsRoot "forGPT/VIBE-KIT-SNAPSHOT.md")),
        (Join-Path $RepoRoot (Join-Path $DocsRoot "VIBE-KIT-SNAPSHOT.md")),
        (Join-Path $RepoRoot "VIBE-KIT-SNAPSHOT.md"),
        (Join-Path $RepoRoot (Join-Path $SubtreePrefix "docs/forGPT/VIBE-KIT-SNAPSHOT.md"))
    )

    $existing = @()
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $existing += $path
        }
    }

    $existing = @($existing | Select-Object -Unique)
    if ($existing.Count -eq 0) {
        return "ABSENT"
    }

    if ($WhatIf) {
        foreach ($path in $existing) {
            Write-Host "[WhatIf] Would remove owner-only snapshot artifact: $path" -ForegroundColor Cyan
        }
        return "WHATIF(found=$($existing.Count))"
    }

    $removed = 0
    foreach ($path in $existing) {
        try {
            Remove-Item -Path $path -Force
            $removed++
            Write-Host "WARN: Removed owner-only snapshot artifact: $path" -ForegroundColor Yellow
        } catch {
            Write-Host "WARN: Failed to remove owner-only snapshot artifact: $path" -ForegroundColor Yellow
        }
    }

    if ($removed -gt 0) {
        return "REMOVED($removed)"
    }
    return "WARN(remove failed)"
}

try {
    $repoRoot = (git rev-parse --show-toplevel 2>&1) -replace '/', '\\'
} catch {
    Write-Error "HARD STOP: Not inside a git repository."
    exit 1
}

if (-not (Test-Path $repoRoot)) {
    Write-Error "HARD STOP: git rev-parse returned invalid path: $repoRoot"
    exit 1
}

Push-Location $repoRoot

try {
    $branch = (git branch --show-current 2>$null) -join ""
    $gitDirRaw = (git rev-parse --git-dir 2>$null) -join ""
    $gitDir = if ([System.IO.Path]::IsPathRooted($gitDirRaw)) { $gitDirRaw } else { Join-Path $repoRoot $gitDirRaw }

    $docsRoot = $null
    $docsReason = ""

    $kitHead = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    if ((Split-Path $kitHead -Leaf) -eq "vibe-coding") {
        $docsRootFull = (Resolve-Path (Join-Path $kitHead "..")).Path
        $repoRootNorm = $repoRoot -replace '/', '\\'
        $docsRootNorm = $docsRootFull -replace '/', '\\'
        if ($docsRootNorm.Length -gt $repoRootNorm.Length -and $docsRootNorm.StartsWith($repoRootNorm)) {
            $docsRoot = ($docsRootNorm.Substring($repoRootNorm.Length).TrimStart('\\')) -replace '\\', '/'
            $docsReason = "script-relative (vibe-coding parent)"
        } elseif ($docsRootNorm -eq $repoRootNorm) {
            $docsRoot = "."
            $docsReason = "script-relative (vibe-coding at repo root)"
        }
    }

    if (-not $docsRoot) {
        $deDir = Join-Path $repoRoot "docs-engineering"
        $docsDir = Join-Path $repoRoot "docs"
        if ((Test-Path $deDir) -and ((Test-Path (Join-Path $deDir "vibe-coding")) -or (Test-Path (Join-Path $deDir "forGPT")))) {
            $docsRoot = "docs-engineering"
            $docsReason = "docs-engineering/ contains vibe-coding or forGPT"
        } elseif (Test-Path $docsDir) {
            $docsRoot = "docs"
            $docsReason = "docs/ exists"
        } else {
            Fail-KitUpdate "Neither docs-engineering/ nor docs/ found at repo root: $repoRoot" @(
                "You need to run kit update from a consumer repo that embeds vibe-coding-kit via docs-engineering/ or docs/."
            ) @()
        }
    }

    $subtreePrefix = if ($docsRoot -eq ".") { "vibe-coding" } else { "$docsRoot/vibe-coding" }
    if (-not (Test-Path (Join-Path $repoRoot $subtreePrefix))) {
        Fail-KitUpdate "Subtree prefix $subtreePrefix does not exist." @(
            "You need to run kit update from a consumer repo that already contains the vibe-coding subtree."
        ) @("Has the kit been added as a subtree?")
    }

    $inProgressSignals = @()
    foreach ($name in @("MERGE_HEAD", "REBASE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD")) {
        if (Test-Path (Join-Path $gitDir $name)) {
            $inProgressSignals += $name
        }
    }
    foreach ($name in @("rebase-apply", "rebase-merge")) {
        if (Test-Path (Join-Path $gitDir $name)) {
            $inProgressSignals += $name
        }
    }
    if ($inProgressSignals.Count -gt 0) {
        Fail-KitUpdate "In-progress git operation detected." @(
            "You need to finish or abort the current git operation before running kit update."
        ) $inProgressSignals
    }

    $unmergedPaths = @((git diff --name-only --diff-filter=U 2>$null) | ForEach-Object { Normalize-RepoPath $_ } | Where-Object { $_ })
    if ($unmergedPaths.Count -gt 0) {
        Fail-KitUpdate "Unmerged files detected." @(
            "You need to resolve all unmerged files and finish or abort the current git operation before kit update."
        ) $unmergedPaths
    }

    $trackedStatus = @(git status --porcelain | Where-Object { $_ -and $_ -notmatch '^\?\?' })
    $forGptPrefix = if ($docsRoot -eq ".") { "forGPT/" } else { "$docsRoot/forGPT/" }
    $manifestRelative = if ($docsRoot -eq ".") { "forGPT/forgpt.manifest.json" } else { "$docsRoot/forGPT/forgpt.manifest.json" }
    $versionManifestRelative = if ($docsRoot -eq ".") { "forGPT/VERSION-MANIFEST.md" } else { "$docsRoot/forGPT/VERSION-MANIFEST.md" }

    $generatedPacketPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $null = $generatedPacketPaths.Add($versionManifestRelative)
    $manifestPath = Join-Path $repoRoot $manifestRelative
    if (Test-Path $manifestPath) {
        try {
            $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
            foreach ($entry in $manifest.files) {
                $dest = Normalize-RepoPath $entry.dest
                if ($dest) {
                    $fullRelative = if ($docsRoot -eq ".") { "forGPT/$dest" } else { "$docsRoot/forGPT/$dest" }
                    $null = $generatedPacketPaths.Add($fullRelative)
                }
            }
        } catch {
            # Classification falls back to preserve-worthy if the manifest cannot be trusted.
        }
    }

    $subtreeDirty = @()
    $stagedSubtreeDirty = @()
    $outOfScopeDirty = @()
    $forGptDirty = @()
    foreach ($line in $trackedStatus) {
        $path = Get-StatusPath $line
        $statusCode = $line.Substring(0, 2)
        if ($path.StartsWith("$subtreePrefix/", [System.StringComparison]::OrdinalIgnoreCase)) {
            $subtreeDirty += $line
            if ($statusCode[0] -ne ' ') {
                $stagedSubtreeDirty += $line
            }
        } elseif ($path.StartsWith($forGptPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $forGptDirty += $path
        } else {
            $outOfScopeDirty += $line
        }
    }

    if ($outOfScopeDirty.Count -gt 0) {
        Fail-KitUpdate "Out-of-scope tracked changes detected." @(
            "You need to clean non-kit tracked changes before running kit update."
        ) $outOfScopeDirty
    }

    if ($stagedSubtreeDirty.Count -gt 0) {
        Fail-KitUpdate "Unfinished prior subtree update state detected." @(
            "You need to clean up the unfinished prior subtree update state before retrying kit update."
        ) $stagedSubtreeDirty
    }

    if ($subtreeDirty.Count -gt 0) {
        Fail-KitUpdate "Tracked changes inside the kit subtree detected." @(
            "You need to remove or explicitly preserve local edits inside the kit subtree before kit update."
        ) $subtreeDirty
    }

    if ($forGptDirty.Count -gt 0) {
        $packetClassification = Get-DirtyPacketClassification -RelativePaths $forGptDirty -GeneratedPaths $generatedPacketPaths -ManifestRelative $manifestRelative -RepoRoot $repoRoot
        if ($packetClassification.PreserveWorthy.Count -gt 0) {
            Fail-KitUpdate "Preserve-worthy forGPT edits or conflict residue detected." @(
                "You need to preserve forGPT edits or resolve conflict residue before kit update."
            ) $packetClassification.PreserveWorthy
        }
        if ($packetClassification.MirrorDrift.Count -gt 0) {
            Fail-KitUpdate "forGPT mirror-drift candidate detected." @(
                "You need to review these forGPT changes before running kit update. Step 2 does not clean packet drift automatically."
            ) $packetClassification.MirrorDrift
        }
    }

    $localVersionFile = Join-Path $repoRoot (Join-Path $subtreePrefix "VIBE-CODING.VERSION.md")
    $localVersionData = Read-KitVersionData $localVersionFile
    if ($localVersionData.Version -eq "(unknown)") {
        Fail-KitUpdate "Could not read local kit version from $subtreePrefix/VIBE-CODING.VERSION.md." @(
            "You need to restore the embedded kit version file before running kit update."
        ) @()
    }

    $remoteFetchLines = @(git remote -v 2>$null | Where-Object { $_ -match '\(fetch\)$' })
    $selectedRemoteLine = $null
    $selectedRemoteName = $RemoteName
    if ($selectedRemoteName) {
        $selectedRemoteLine = $remoteFetchLines | Where-Object { $_ -match "^$([regex]::Escape($selectedRemoteName))\s+" } | Select-Object -First 1
        if (-not $selectedRemoteLine) {
            Fail-KitUpdate "Configured remote '$selectedRemoteName' was not found." @(
                "You need to provide a valid kit upstream ref that can be verified before update can proceed."
            ) @()
        }
    } else {
        $matchingRemotes = @($remoteFetchLines | Where-Object { $_ -match 'vibe-coding-kit' })
        if ($matchingRemotes.Count -eq 0) {
            Fail-KitUpdate "No candidate vibe-coding-kit remote was found in local git config." @(
                "You need to provide a valid kit upstream ref that can be verified before update can proceed."
            ) @("Rerun with -RemoteName <configured-remote> if the remote name does not include vibe-coding-kit.")
        }
        if ($matchingRemotes.Count -gt 1) {
            Fail-KitUpdate "Multiple candidate kit remotes were found." @(
                "You need to provide a valid kit upstream ref that can be verified before update can proceed."
            ) $matchingRemotes
        }
        $selectedRemoteLine = $matchingRemotes[0]
        if ($selectedRemoteLine -match '^(\S+)\s+') {
            $selectedRemoteName = $Matches[1]
        }
    }

    if (-not $selectedRemoteName) {
        Fail-KitUpdate "Unable to determine the target remote name." @(
            "You need to provide a valid kit upstream ref that can be verified before update can proceed."
        ) @()
    }

    Write-Host ""
    Write-Host "========== KIT UPDATE PLAN ==========" -ForegroundColor Cyan
    Write-Host "RepoRoot      = $repoRoot"
    Write-Host "DOCS_ROOT     = $docsRoot | Reason=$docsReason"
    Write-Host "Branch        = $branch"
    Write-Host "SubtreePrefix = $subtreePrefix"
    Write-Host "Target        = $selectedRemoteName/$Ref"
    Write-Host "LocalVersion  = $($localVersionData.Version) (Effective $($localVersionData.Effective))"
    if ($WhatIf) {
        Write-Host "Mode          = WhatIf (verification only; no subtree pull)"
    }
    Write-Host "=====================================" -ForegroundColor Cyan

    try {
        Invoke-GitSafe ls-remote --exit-code --heads $selectedRemoteName $Ref | Out-Null
    } catch {
        Fail-KitUpdate "Target upstream ref '$selectedRemoteName/$Ref' could not be verified." @(
            "You need to provide a valid kit upstream ref that can be verified before update can proceed."
        ) @("Verification failed: $_")
    }

    try {
        Invoke-GitSafe fetch $selectedRemoteName $Ref | Out-Null
    } catch {
        Fail-KitUpdate "Verification fetch failed for '$selectedRemoteName/$Ref'." @(
            "You need to restore remote verification capability before kit update can proceed."
        ) @("Fetch failed: $_")
    }

    $remoteVersionText = ""
    try {
        $remoteVersionText = (Invoke-GitSafe show "FETCH_HEAD:VIBE-CODING.VERSION.md" | Out-String).Trim()
    } catch {
        Fail-KitUpdate "Fetched upstream ref did not expose VIBE-CODING.VERSION.md." @(
            "You need to provide a valid kit upstream ref that can be verified before update can proceed."
        ) @()
    }

    $remoteVersionData = [pscustomobject]@{ Version = "(unknown)"; Effective = "(unknown)" }
    if ($remoteVersionText -match '\*\*Version:\*\*\s*(v[\d.]+)') {
        $remoteVersionData.Version = $Matches[1]
    }
    if ($remoteVersionText -match '\*\*Effective Date:\*\*\s*(\d{4}-\d{2}-\d{2})') {
        $remoteVersionData.Effective = $Matches[1]
    }
    if ($remoteVersionData.Version -eq "(unknown)") {
        Fail-KitUpdate "Fetched upstream ref did not expose a parseable kit version." @(
            "You need to provide a valid kit upstream ref that can be verified before update can proceed."
        ) @()
    }

    $sentinelFiles = @("VIBE-CODING.VERSION.md", "protocol/protocol-v7.md", "protocol-lite.md")
    foreach ($sentinel in $sentinelFiles) {
        try {
            Invoke-GitSafe rev-parse "FETCH_HEAD:$sentinel" | Out-Null
        } catch {
            Fail-KitUpdate "Fetched upstream ref is missing required sentinel '$sentinel'." @(
                "You need to provide a valid kit upstream ref that can be verified before update can proceed."
            ) @()
        }
    }

    if ($localVersionData.Version -eq $remoteVersionData.Version) {
        $divergentFiles = @()
        foreach ($sentinel in $sentinelFiles) {
            try {
                $localBlob = (Invoke-GitSafe rev-parse "HEAD:${subtreePrefix}/$sentinel" | Out-String).Trim()
                $remoteBlob = (Invoke-GitSafe rev-parse "FETCH_HEAD:$sentinel" | Out-String).Trim()
                if ($localBlob -and $remoteBlob -and $localBlob -ne $remoteBlob) {
                    $divergentFiles += $sentinel
                }
            } catch {
                $divergentFiles += $sentinel
            }
        }
        if ($divergentFiles.Count -gt 0) {
            Fail-KitUpdate "Divergent subtree contamination detected for the current kit version." @(
                "You need to remove local kit subtree contamination before update can proceed."
            ) $divergentFiles
        }

        Write-Host "KitUpdate=NOOP(Current)" -ForegroundColor Green
        Write-Host "Target kit version matches local subtree and sentinel parity checks passed." -ForegroundColor Green
        $snapshotStatus = Invoke-SnapshotIsolationEnforcement -RepoRoot $repoRoot -DocsRoot $docsRoot -SubtreePrefix $subtreePrefix -WhatIf:$WhatIf
        Write-Host "SnapshotIsolation = $snapshotStatus" -ForegroundColor White
        Write-Host "Packet sync remains optional for full forGPT mirror refresh." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "You need to update the kit now. Preconditions passed and the target ref was verified." -ForegroundColor Yellow
    Write-Host "TargetVersion = $($remoteVersionData.Version) (Effective $($remoteVersionData.Effective))" -ForegroundColor Yellow

    if ($WhatIf) {
        Write-Host "[WhatIf] Would run: git subtree pull --prefix $subtreePrefix $selectedRemoteName $Ref --squash" -ForegroundColor Cyan
        Write-Host "You need to run packet sync separately if you require a current handoff packet." -ForegroundColor Yellow
        exit 0
    }

    $pullText = ""
    try {
        $pullOutput = Invoke-GitSafe subtree pull --prefix $subtreePrefix $selectedRemoteName $Ref --squash
        $pullText = ($pullOutput | Out-String).Trim()
    } catch {
        Fail-KitUpdate "Subtree pull failed." @(
            "You need to resolve the subtree update failure before retrying kit update."
        ) @("Pull failed: $_")
    }

    $postUnmergedPaths = @((git diff --name-only --diff-filter=U 2>$null) | ForEach-Object { Normalize-RepoPath $_ } | Where-Object { $_ })
    if ($postUnmergedPaths.Count -gt 0) {
        Fail-KitUpdate "Unmerged files remain after subtree pull." @(
            "You need to resolve all unmerged files and finish or abort the current git operation before kit update is considered complete."
        ) $postUnmergedPaths
    }

    $postVersionData = Read-KitVersionData $localVersionFile
    if ($postVersionData.Version -ne $remoteVersionData.Version) {
        Fail-KitUpdate "Post-update kit version does not match the verified target version." @(
            "You need to inspect the subtree update result before proceeding."
        ) @("Expected $($remoteVersionData.Version) but found $($postVersionData.Version).")
    }

    $postDivergentFiles = @()
    foreach ($sentinel in $sentinelFiles) {
        try {
            $localBlob = (Invoke-GitSafe rev-parse "HEAD:${subtreePrefix}/$sentinel" | Out-String).Trim()
            $remoteBlob = (Invoke-GitSafe rev-parse "FETCH_HEAD:$sentinel" | Out-String).Trim()
            if ($localBlob -and $remoteBlob -and $localBlob -ne $remoteBlob) {
                $postDivergentFiles += $sentinel
            }
        } catch {
            $postDivergentFiles += $sentinel
        }
    }
    if ($postDivergentFiles.Count -gt 0) {
        Fail-KitUpdate "Post-update sentinel parity check failed." @(
            "You need to inspect the subtree update result before proceeding."
        ) $postDivergentFiles
    }

    Write-Host ""
    Write-Host "========== KIT UPDATE RESULT ==========" -ForegroundColor Green
    Write-Host "KitUpdate    = DONE"
    Write-Host "Target       = $selectedRemoteName/$Ref"
    Write-Host "LocalVersion = $($postVersionData.Version) (Effective $($postVersionData.Effective))"
    $snapshotStatus = Invoke-SnapshotIsolationEnforcement -RepoRoot $repoRoot -DocsRoot $docsRoot -SubtreePrefix $subtreePrefix -WhatIf:$WhatIf
    Write-Host "SnapshotIsolation = $snapshotStatus"
    if ($pullText) {
        Write-Host "PullOutput:" -ForegroundColor Gray
        Write-Host $pullText -ForegroundColor Gray
    }
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "Packet sync remains optional for full forGPT mirror refresh." -ForegroundColor Yellow
} catch {
    if ($_.Exception.Message -eq "__KIT_UPDATE_STOP__") {
        exit 1
    }

    Write-Host "HARD STOP: Kit update failed unexpectedly." -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Required Actions:" -ForegroundColor Yellow
    Write-Host "  - You need to inspect the kit update failure before retrying." -ForegroundColor Yellow
    exit 1
} finally {
    Pop-Location
}