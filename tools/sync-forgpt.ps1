<#
.SYNOPSIS
    Syncs the forGPT packet from canonical docs using forgpt.manifest.json

.DESCRIPTION
    Reads <DOCS_ROOT>/forGPT/forgpt.manifest.json and copies each source
    file to the forGPT folder. Generates VERSION-MANIFEST.md with SHA256 hashes
    to prove freshness.

    DOCS_ROOT DETECTION (Deterministic Precedence):
    1. If docs-engineering/ exists at project root -> DOCS_ROOT = docs-engineering
    2. Else if docs/ exists at project root -> DOCS_ROOT = docs
    3. Else STOP with error
    
    This precedence is deterministic: even if BOTH folders exist, docs-engineering
    always wins. No override parameter exists; rename/remove folders to change.
    
    Manifest src paths are DOCS_ROOT-relative (e.g., "project/VISION.md"),
    not absolute or repo-root-relative. The script prepends detected DOCS_ROOT
    when resolving, making manifests portable across repos with different folder names.

.PARAMETER WhatIf
    Show what would be copied without actually copying files.

.PARAMETER Force
    Continue even if git working tree has uncommitted changes.
    Without -Force, the script STOPS on dirty tree (safety default).

.NOTES
    SAFETY:
    - Only modifies files inside <DOCS_ROOT>/forGPT/
    - Only copies files listed in the manifest
    - Never deletes forgpt.manifest.json
    - Stops immediately if any source file is missing
    - Stops on dirty working tree unless -Force is provided

.EXAMPLE
    .\sync-forgpt.ps1
    Run from project root or any subdirectory. STOPS if git tree is dirty.

.EXAMPLE
    .\sync-forgpt.ps1 -Force
    Run even if there are uncommitted changes.

.EXAMPLE
    .\sync-forgpt.ps1 -WhatIf
    Preview what would be synced without making changes.
#>

param(
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$packetResolverScript = Join-Path $PSScriptRoot 'packet-path-resolver.ps1'
if (-not (Test-Path $packetResolverScript)) {
    Write-Error "STOP: Missing packet resolver script at $packetResolverScript"
    exit 1
}
. $packetResolverScript

# Find the project root by looking for docs-engineering or docs folder
# (more reliable than .git for nested project structures)
function Find-ProjectRoot {
    $current = Get-Location
    while ($current -ne $null) {
        # Check for docs-engineering at current level
        $docsEng = Join-Path $current "docs-engineering"
        if (Test-Path $docsEng) {
            return $current
        }
        # Check for docs at current level (but not if it's a nested folder like ExampleProject/docs)
        $docs = Join-Path $current "docs"
        $hasGit = Test-Path (Join-Path $current ".git")
        if ((Test-Path $docs) -and $hasGit) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $null
}

# Detect DOCS_ROOT (docs-engineering or docs)
function Find-DocsRoot {
    param([string]$ProjectRoot)
    
    # Priority 1: docs-engineering at project root
    $docsEng = Join-Path $ProjectRoot "docs-engineering"
    if (Test-Path $docsEng) {
        return "docs-engineering"
    }
    
    # Priority 2: docs at project root
    $docs = Join-Path $ProjectRoot "docs"
    if (Test-Path $docs) {
        return "docs"
    }
    
    return $null
}

$projectRoot = $null
$docsRoot = $null

# -- Script-relative DOCS_ROOT detection (PS 5.1 safe) ---------
# Preferred: tools/ -> vibe-coding/ (kit head) -> DOCS_ROOT
$kitHead = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ((Split-Path $kitHead -Leaf) -eq "vibe-coding") {
    $docsRootFull = (Resolve-Path (Join-Path $kitHead "..")).Path
    try {
        $projectRoot = (git rev-parse --show-toplevel 2>&1) -replace '/', '\'
    } catch { }
    if ($projectRoot -and (Test-Path $projectRoot)) {
        $repoRootNorm = $projectRoot -replace '/', '\'
        $docsRootNorm = $docsRootFull -replace '/', '\'
        if ($docsRootNorm.Length -gt $repoRootNorm.Length -and $docsRootNorm.StartsWith($repoRootNorm)) {
            $docsRoot = ($docsRootNorm.Substring($repoRootNorm.Length).TrimStart('\')) -replace '\\', '/'
        } elseif ($docsRootNorm -eq $repoRootNorm) {
            $docsRoot = "."
        }
    }
}

# Fallback: walk up from CWD (original logic for kit source repo or unusual layout)
if (-not $projectRoot -or -not $docsRoot) {
    $projectRoot = Find-ProjectRoot
    if (-not $projectRoot) {
        Write-Error "STOP: Cannot find project root (no docs-engineering or docs folder found). Run from inside a project with docs."
        exit 1
    }
    $docsRoot = Find-DocsRoot -ProjectRoot $projectRoot
    if (-not $docsRoot) {
        Write-Error "STOP: Cannot detect DOCS_ROOT. Expected 'docs-engineering' or 'docs' folder in project root."
        exit 1
    }
}

Write-Host "Project root: $projectRoot" -ForegroundColor Cyan
Write-Host "DOCS_ROOT: $docsRoot" -ForegroundColor Cyan

$packetResolution = Resolve-VibePacketPath -RepoRoot $projectRoot -DocsRoot $docsRoot
$packetPathRel = $packetResolution.PacketPath
$packetPathSource = $packetResolution.PacketPathSource
$packetDirName = Split-Path $packetPathRel -Leaf
Write-Host "Packet path: $packetPathRel (source=$packetPathSource)" -ForegroundColor Cyan

# Paths (using detected DOCS_ROOT)
$manifestPath = Join-Path $projectRoot (($packetPathRel + '/forgpt.manifest.json') -replace '/', '\\')
$forGptDir = Join-Path $projectRoot ($packetPathRel -replace '/', '\\')
$versionManifestPath = Join-Path $forGptDir "VERSION-MANIFEST.md"
$ownerSnapshotPath = Join-Path $forGptDir "VIBE-KIT-SNAPSHOT.md"
$snapshotIsolationStatus = "ABSENT"

# New-install compatibility bootstrap:
# If packet path is missing with no config, create legacy forGPT path and seed a default manifest.
$legacyBootstrapApplied = $false
$legacyBootstrapExpectedPath = if ($docsRoot -eq '.') { 'forGPT' } else { "$docsRoot/forGPT" }
$shouldBootstrapLegacy = ($packetPathSource -eq 'missing') -and (-not $packetResolution.ConfigExists) -and ($packetPathRel -eq $legacyBootstrapExpectedPath)

# Safety: Check working tree status (STOP by default, unless -Force or -WhatIf)
Write-Host "`nChecking working tree..." -ForegroundColor Yellow
$isDirty = $false
try {
    Push-Location $projectRoot
    $gitStatus = git status --porcelain 2>$null
    Pop-Location
    if ($gitStatus) {
        $isDirty = $true
        if ($WhatIf) {
            Write-Host "  WARNING: Working tree has uncommitted changes (-WhatIf mode, continuing)" -ForegroundColor Yellow
        } elseif ($Force) {
            Write-Host "  WARNING: Working tree has uncommitted changes (-Force specified, continuing)" -ForegroundColor Yellow
        } else {
            Write-Host "  STOP: Working tree has uncommitted changes" -ForegroundColor Red
            Write-Host "  Commit or stash your changes first, or use -Force to override." -ForegroundColor Red
            Write-Host "`n  Why? Syncing on a dirty tree can make it unclear what changed." -ForegroundColor Gray
            exit 1
        }
    } else {
        Write-Host "  Working tree is clean" -ForegroundColor Green
    }
} catch {
    Write-Host "  Warning: Could not check git status (not a git repo?)" -ForegroundColor Yellow
}

if ($shouldBootstrapLegacy) {
    if (-not $WhatIf) {
        if (-not (Test-Path $forGptDir)) {
            New-Item -ItemType Directory -Path $forGptDir -Force | Out-Null
            Write-Host "NOTE: Created legacy Packet for External AI directory at $packetPathRel for compatibility" -ForegroundColor Yellow
            $legacyBootstrapApplied = $true
        }

        if (-not (Test-Path $manifestPath)) {
            $defaultManifest = @{
                files = @(
                    @{ src = 'project/VISION.md'; dest = 'VISION.md'; tier = 'core' },
                    @{ src = 'project/EPICS.md'; dest = 'EPICS.md'; tier = 'core' },
                    @{ src = 'project/NEXT.md'; dest = 'NEXT.md'; tier = 'core' },
                    @{ src = 'research/ResearchIndex.md'; dest = 'ResearchIndex.md'; tier = 'core' },
                    @{ src = 'vibe-coding/README.md'; dest = 'VIBE-CODING-KIT-README.md'; tier = 'extra' },
                    @{ src = 'vibe-coding/protocol-lite.md'; dest = 'protocol-lite.md'; tier = 'extra' },
                    @{ src = 'vibe-coding/QUICKSTART.md'; dest = 'QUICKSTART.md'; tier = 'extra' }
                )
            }
            $defaultManifestJson = $defaultManifest | ConvertTo-Json -Depth 6
            Set-Content -Path $manifestPath -Value $defaultManifestJson -Encoding UTF8
            Write-Host "NOTE: Seeded default packet manifest at $packetPathRel/forgpt.manifest.json for first-run compatibility" -ForegroundColor Yellow
            $legacyBootstrapApplied = $true
        }
    } else {
        if (-not (Test-Path $forGptDir)) {
            Write-Host "[WhatIf] Would create legacy Packet for External AI directory at $packetPathRel for compatibility" -ForegroundColor Cyan
        }
        if (-not (Test-Path $manifestPath)) {
            Write-Host "[WhatIf] Would seed default packet manifest at $packetPathRel/forgpt.manifest.json" -ForegroundColor Cyan
        }
    }
}

# Validate manifest exists
if (-not (Test-Path $manifestPath)) {
    Write-Error "STOP: Manifest not found at $manifestPath"
    exit 1
}

# Load manifest
Write-Host "`nLoading manifest..." -ForegroundColor Yellow
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

if (-not $manifest.files -or $manifest.files.Count -eq 0) {
    Write-Error "STOP: Manifest has no files defined"
    exit 1
}

foreach ($entry in $manifest.files) {
    $destLeaf = Split-Path $entry.dest -Leaf
    if ($destLeaf -ieq "VIBE-KIT-SNAPSHOT.md") {
        Write-Error "STOP: Manifest must not include VIBE-KIT-SNAPSHOT.md (owner-only file)."
        exit 1
    }
}

# Split files by tier (core vs extra)
$coreFiles = @($manifest.files | Where-Object { $_.tier -eq "core" })
$extraFiles = @($manifest.files | Where-Object { $_.tier -eq "extra" })
$coreCount = $coreFiles.Count
$extraCount = $extraFiles.Count
$totalCount = $manifest.files.Count

Write-Host "Manifest loaded:" -ForegroundColor Green
Write-Host "  CORE files:  $coreCount" -ForegroundColor White
Write-Host "  EXTRA files: $extraCount" -ForegroundColor Gray
Write-Host "  TOTAL files: $totalCount" -ForegroundColor White

# Verify all sources exist BEFORE copying anything
# Note: manifest src paths are DOCS_ROOT-relative, so we prepend docsRoot
Write-Host "`nVerifying source files..." -ForegroundColor Yellow
$missingFiles = @()
foreach ($entry in $manifest.files) {
    $srcPath = Join-Path (Join-Path $projectRoot $docsRoot) $entry.src
    if (-not (Test-Path $srcPath)) {
        $missingFiles += $entry.src
        Write-Host "  MISSING: $docsRoot/$($entry.src)" -ForegroundColor Red
    } else {
        Write-Host "  OK: $docsRoot/$($entry.src)" -ForegroundColor Gray
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "STOP: $($missingFiles.Count) source file(s) missing. Fix the manifest or create the missing files."
    exit 1
}

Write-Host "All source files verified" -ForegroundColor Green

# Get git info
Write-Host "`nGathering git info..." -ForegroundColor Yellow
$gitBranch = "unknown"
$gitCommit = "unknown"
try {
    Push-Location $projectRoot
    $gitBranch = (git branch --show-current 2>$null) -join ""
    $gitCommit = (git rev-parse --short HEAD 2>$null) -join ""
    Pop-Location
} catch {
    Write-Host "  Warning: Could not get git info" -ForegroundColor Yellow
}
Write-Host "  Branch: $gitBranch" -ForegroundColor Gray
Write-Host "  Commit: $gitCommit" -ForegroundColor Gray

# WhatIf mode: show what would be copied
if ($WhatIf) {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  WHATIF MODE - No changes made" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($coreCount -gt 0) {
        Write-Host "`nWould copy $coreCount CORE files:" -ForegroundColor White
        foreach ($entry in $coreFiles) {
            Write-Host "  $docsRoot/$($entry.src) -> $packetDirName/$($entry.dest)" -ForegroundColor Gray
        }
    }
    
    if ($extraCount -gt 0) {
        Write-Host "`nWould copy $extraCount EXTRA files:" -ForegroundColor Gray
        foreach ($entry in $extraFiles) {
            Write-Host "  $docsRoot/$($entry.src) -> $packetDirName/$($entry.dest)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`nTOTAL: $totalCount files would be copied" -ForegroundColor Yellow
    Write-Host "Would generate: $versionManifestPath" -ForegroundColor Yellow
    Write-Host "`nTo actually sync, run without -WhatIf" -ForegroundColor Cyan
    exit 0
}

# Copy files and collect hash info
# Note: manifest src paths are DOCS_ROOT-relative, so we prepend docsRoot
Write-Host "`nSyncing files..." -ForegroundColor Yellow
$hashEntries = @()
$syncedCount = 0
$syncedCoreCount = 0
$syncedExtraCount = 0

foreach ($entry in $manifest.files) {
    $srcPath = Join-Path (Join-Path $projectRoot $docsRoot) $entry.src
    $destPath = Join-Path $forGptDir $entry.dest
    
    # Safety check: ensure dest is inside forGPT folder
    $resolvedDest = [System.IO.Path]::GetFullPath($destPath)
    $resolvedForGpt = [System.IO.Path]::GetFullPath($forGptDir)
    if (-not $resolvedDest.StartsWith($resolvedForGpt)) {
        Write-Error "STOP: Destination path escapes forGPT folder: $destPath"
        exit 1
    }
    
    # Copy the file
    Copy-Item -Path $srcPath -Destination $destPath -Force
    $syncedCount++
    if ($entry.tier -eq "core") { $syncedCoreCount++ } else { $syncedExtraCount++ }
    
    # Calculate SHA256 hash
    $hash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash.Substring(0, 16)
    
    $hashEntries += [PSCustomObject]@{
        Dest = $entry.dest
        Src = "$docsRoot/$($entry.src)"
        Hash = $hash
        Tier = $entry.tier
    }
    
    $tierLabel = if ($entry.tier -eq "core") { "[CORE]" } else { "[extra]" }
    Write-Host "  $tierLabel Copied: $($entry.dest)" -ForegroundColor Gray
}

Write-Host "Synced $syncedCount files (CORE: $syncedCoreCount, EXTRA: $syncedExtraCount)" -ForegroundColor Green

# Generate VERSION-MANIFEST.md
Write-Host "`nGenerating VERSION-MANIFEST.md..." -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$manifestContent = @"
# forGPT Packet Version Manifest

> **Auto-generated by sync-forgpt.ps1** — Do not edit manually.

## Freshness Info

| Field | Value |
|-------|-------|
| **Generated** | $timestamp |
| **DOCS_ROOT** | ``$docsRoot`` |
| **Git Branch** | ``$gitBranch`` |
| **Git Commit** | ``$gitCommit`` |
| **CORE Files** | $syncedCoreCount |
| **EXTRA Files** | $syncedExtraCount |
| **TOTAL Files** | $($hashEntries.Count) |

## What is CORE vs EXTRA?

- **CORE ($syncedCoreCount files):** Session-start essentials. These are the minimum set needed to begin a productive GPT session.
- **EXTRA ($syncedExtraCount files):** Supporting docs that provide additional context but aren't required for session startup.

## File Hashes (SHA256 prefix)

| Tier | File | Source | Hash (first 16 chars) |
|------|------|--------|----------------------|
"@

foreach ($entry in $hashEntries) {
    $tierLabel = if ($entry.Tier -eq "core") { "CORE" } else { "extra" }
    $manifestContent += "`n| $tierLabel | $($entry.Dest) | $($entry.Src) | ``$($entry.Hash)`` |"
}

$manifestContent += @"


---

## How to Verify Freshness

1. Check the **Generated** timestamp — should be today's date
2. Check the **Git Commit** — should match your current HEAD
3. If stale, re-run: ``.\<DOCS_ROOT>\vibe-coding\tools\sync-forgpt.ps1``

## What to Upload

Upload the **entire** ``<DOCS_ROOT>/forGPT/`` folder to start a GPT session.

(Where DOCS_ROOT = ``$docsRoot`` for this repo; resolved packet path = ``$packetPathRel``)
"@

Set-Content -Path $versionManifestPath -Value $manifestContent -Encoding UTF8

Write-Host "Generated: $versionManifestPath" -ForegroundColor Green

# Owner-only guardrail: snapshot must not be part of consumer forGPT packets
if (Test-Path $ownerSnapshotPath) {
    if ($WhatIf) {
        Write-Host "[WhatIf] Would remove owner-only snapshot artifact: $ownerSnapshotPath" -ForegroundColor Cyan
        $snapshotIsolationStatus = "WHATIF(found)"
    } else {
        Remove-Item -Path $ownerSnapshotPath -Force
        Write-Host "WARN: Removed owner-only snapshot artifact from forGPT packet path." -ForegroundColor Yellow
        $snapshotIsolationStatus = "REMOVED"
    }
}

# Final summary
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SYNC COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CORE files:  $syncedCoreCount" -ForegroundColor White
Write-Host "  EXTRA files: $syncedExtraCount" -ForegroundColor Gray
Write-Host "  TOTAL synced: $syncedCount" -ForegroundColor White
Write-Host "  Manifest: VERSION-MANIFEST.md" -ForegroundColor White
Write-Host "  Packet path: $packetPathRel ($packetPathSource)" -ForegroundColor White
if ($legacyBootstrapApplied) {
    Write-Host "  Legacy bootstrap: APPLIED" -ForegroundColor White
}
Write-Host "  Snapshot isolation: $snapshotIsolationStatus" -ForegroundColor White
Write-Host "  Git: $gitBranch @ $gitCommit" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nPASS: Packet for External AI is fresh and ready for upload." -ForegroundColor Green
