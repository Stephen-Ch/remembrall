<#
.SYNOPSIS
    Session-start wrapper: audit-only default that reports kit drift, packet state, doc-audit, and session gates without modifying the repo.
.DESCRIPTION
  Run this from ANY consumer repo (any subdirectory). It detects repo root and DOCS_ROOT automatically.
  Designed to be invoked by Copilot when the user says: RUN START OF SESSION DOCS AUDIT
.PARAMETER SkipUpdate
    Deprecated compatibility flag. Session-start is audit-only by default and does not update the kit.
.PARAMETER SkipAudit
  Skip the Consumer doc-audit step (still prints kit version).
.PARAMETER Force
    Deprecated compatibility flag. Session-start is audit-only by default and does not mutate the repo.
.PARAMETER WhatIf
    Print commands that would run without executing doc-audit.
#>
[CmdletBinding()]
param(
    [switch]$SkipUpdate,
    [switch]$SkipAudit,
    [switch]$Force,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cleanCloseProofSchemaVersion = 1
$cleanCloseProofFreshDays = 7

# -- Helper: resolve repo-local clean-close proof path ---------
function Resolve-CleanCloseProofPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $gitDirRaw = ((git rev-parse --git-dir 2>$null) | Out-String).Trim()
    if (-not $gitDirRaw) {
        throw "git rev-parse --git-dir returned no path"
    }

    if ([System.IO.Path]::IsPathRooted($gitDirRaw)) {
        $gitDirFull = $gitDirRaw
    } else {
        $gitDirFull = Join-Path $RepoRoot $gitDirRaw
    }

    return Join-Path $gitDirFull "vibe-coding\clean-close-proof.json"
}

# -- 0. Repo root ----------------------------------------------
try {
    $repoRoot = (git rev-parse --show-toplevel 2>&1) -replace '/', '\'
} catch {
    Write-Error "HARD STOP: Not inside a git repository."
    exit 1
}
if (-not (Test-Path $repoRoot)) {
    Write-Error "HARD STOP: git rev-parse returned invalid path: $repoRoot"
    exit 1
}
Push-Location $repoRoot

$packetResolverScript = Join-Path $PSScriptRoot 'packet-path-resolver.ps1'
if (-not (Test-Path $packetResolverScript)) {
    Write-Error "HARD STOP: Missing packet resolver script at $packetResolverScript"
    exit 1
}
. $packetResolverScript

try {

# -- 1. Branch + tree state ------------------------------------
$branch = (git branch --show-current 2>$null) -join ""
$headSha = (git rev-parse --short HEAD 2>$null) -join ""
$dirtyFiles = git status --porcelain | Where-Object { $_ -notmatch '^\?\?' }
$treeState = if ($dirtyFiles) { "DIRTY" } else { "CLEAN" }
$requiredActions = @()
$subtreeDirty = @()
$nonSubtreeDirty = @()

# -- Tool/Auth Fragility tracking (populated throughout script) --
$taGhStatus = "UNAVAILABLE"     # AVAILABLE | DEGRADED | UNAVAILABLE
$taFetchStatus = "UNAVAILABLE"  # AVAILABLE | DEGRADED | UNAVAILABLE

# -- 2. Detect DOCS_ROOT --------------------------------------
# Prefer script-relative: tools/ -> vibe-coding/ (kit head) -> DOCS_ROOT
$docsRoot = $null
$docsReason = ""

$kitHead = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ((Split-Path $kitHead -Leaf) -eq "vibe-coding") {
    $docsRootFull = (Resolve-Path (Join-Path $kitHead "..")).Path
    $repoRootNorm = $repoRoot -replace '/', '\'
    $docsRootNorm = $docsRootFull -replace '/', '\'
    if ($docsRootNorm.Length -gt $repoRootNorm.Length -and $docsRootNorm.StartsWith($repoRootNorm)) {
        $docsRoot = ($docsRootNorm.Substring($repoRootNorm.Length).TrimStart('\')) -replace '\\', '/'
        $docsReason = "script-relative (vibe-coding parent)"
    } elseif ($docsRootNorm -eq $repoRootNorm) {
        # DOCS_ROOT is repo root itself — use '.' to keep Join-Path sane
        $docsRoot = "."
        $docsReason = "script-relative (vibe-coding at repo root)"
    }
}

# Fallback: repo-root detection (Kit source repo or unusual layout)
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
        Write-Error "HARD STOP: Neither docs-engineering/ nor docs/ found at repo root: $repoRoot"
        exit 1
    }
}

$subtreePrefix = "$docsRoot/vibe-coding"
if (-not (Test-Path (Join-Path $repoRoot $subtreePrefix))) {
    Write-Error "HARD STOP: Subtree prefix $subtreePrefix does not exist. Has the kit been added as a subtree?"
    exit 1
}

# -- 2a. Previous clean-close proof (advisory only) ------------
$cleanCloseProofStatus = "MISSING"
$cleanCloseProofAgeDays = -1
$cleanCloseProofMessage = "No previous-session clean-close proof was found."
$cleanCloseProofPath = $null

try {
    $cleanCloseProofPath = Resolve-CleanCloseProofPath -RepoRoot $repoRoot
    if (Test-Path $cleanCloseProofPath) {
        $proofJson = Get-Content $cleanCloseProofPath -Raw
        $proof = $proofJson | ConvertFrom-Json
        $requiredProofFields = @(
            'schemaVersion',
            'writtenAtUtc',
            'repoName',
            'docsRoot',
            'branch',
            'head',
            'cleanFieldReady',
            'activeLane',
            'remoteReality',
            'workspaceReality',
            'toolAuth',
            'kitVersion'
        )

        foreach ($field in $requiredProofFields) {
            if (-not ($proof.PSObject.Properties.Name -contains $field)) {
                throw "Missing required field '$field'"
            }
        }

        if ([int]$proof.schemaVersion -ne $cleanCloseProofSchemaVersion) {
            throw "Unsupported schema version '$($proof.schemaVersion)'"
        }

        $proofWrittenAt = [datetime]::Parse($proof.writtenAtUtc, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $proofWrittenAtUtc = $proofWrittenAt.ToUniversalTime()
        $proofFreshCutoffUtc = (Get-Date).ToUniversalTime().AddDays(-$cleanCloseProofFreshDays)
        $cleanCloseProofAgeDays = [math]::Floor(((Get-Date).ToUniversalTime() - $proofWrittenAt.ToUniversalTime()).TotalDays)

        if (-not [bool]$proof.cleanFieldReady) {
            throw "cleanFieldReady is not true"
        }

        $repoName = Split-Path $repoRoot -Leaf
        $proofContradictsCurrentState = (
            $proof.repoName -ne $repoName -or
            $proof.docsRoot -ne $docsRoot -or
            $proof.branch -ne $branch -or
            $proof.head -ne $headSha -or
            $treeState -ne 'CLEAN'
        )

        if ($proofWrittenAtUtc -lt $proofFreshCutoffUtc) {
            $cleanCloseProofStatus = "STALE"
            $cleanCloseProofMessage = "Previous-session clean-close proof is stale."
        } elseif ($proofContradictsCurrentState) {
            $cleanCloseProofStatus = "CONTRADICTORY"
            $cleanCloseProofMessage = "Previous-session clean-close proof contradicts current repo state."
        } else {
            $cleanCloseProofStatus = "VALID"
            $cleanCloseProofMessage = "Previous session clean-close proof is valid."
        }
    }
} catch {
    $cleanCloseProofStatus = "UNVERIFIABLE"
    $cleanCloseProofMessage = "Previous-session clean-close proof could not be verified."
}

# -- 2b. Overlay-outside-head check (Octopus Invariant 2) ------
# See OCTOPUS-INVARIANTS.md — overlays MUST NOT live inside the kit head.
$overlaysInsideHead = Join-Path $repoRoot "$docsRoot/vibe-coding/overlays"
if (Test-Path $overlaysInsideHead) {
    Write-Error "HARD STOP: Overlays detected inside kit head ($docsRoot/vibe-coding/overlays/). Move overlays to $docsRoot/overlays/ and re-run. See OCTOPUS-INVARIANTS.md."
    exit 1
}
$overlayIndex = Join-Path $repoRoot "$docsRoot/overlays/OVERLAY-INDEX.md"
if (-not (Test-Path $overlayIndex)) {
    Write-Host "WARNING: Overlay index missing at $docsRoot/overlays/OVERLAY-INDEX.md. Create it per OCTOPUS-INVARIANTS.md." -ForegroundColor Yellow
}

# -- 2c. Dirty-file classification (audit-only) ----------------
if ($treeState -eq "DIRTY") {
    foreach ($line in $dirtyFiles) {
        $path = $line.Substring(3).Trim()
        if ($path -match ' -> (.+)$') { $path = $Matches[1] }
        if ($path.StartsWith("$subtreePrefix/")) {
            $subtreeDirty += $line
        } else {
            $nonSubtreeDirty += $line
        }
    }

}

if ($SkipUpdate) {
    Write-Host "NOTE: -SkipUpdate has no effect. Session-start is audit-only by default." -ForegroundColor DarkGray
}
if ($Force) {
    Write-Host "NOTE: -Force has no effect. Session-start does not mutate the repo." -ForegroundColor DarkGray
}

if ($treeState -eq "DIRTY") {
    Write-Host ""
    Write-Host "--- Working Tree Status ---" -ForegroundColor Cyan
    Write-Host "Tracked changes detected. Audit completed without changing your files." -ForegroundColor Yellow
    if ($subtreeDirty.Count -gt 0) {
        Write-Host "Dirty kit-subtree files:" -ForegroundColor Yellow
        $subtreeDirty | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        $requiredActions += "You need to resolve tracked changes inside the kit subtree before proceeding."
    }
    if ($nonSubtreeDirty.Count -gt 0) {
        Write-Host "Dirty non-subtree files:" -ForegroundColor Yellow
        $nonSubtreeDirty | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        $requiredActions += "You need to resolve tracked changes before using the update path."
    }
}

# -- 3. Kit update status (audit-only) -------------------------
$kitUpdateResult = "NOT_RUN(AuditOnly)"
$kitRemoteUrl = "https://github.com/Stephen-Ch/vibe-coding-kit.git"
$kitRemoteName = $null
# Find existing remote whose URL matches vibe-coding-kit using current local config only.
$remotes = git remote -v 2>$null
foreach ($line in $remotes) {
    if ($line -match '(\S+)\s+.*vibe-coding-kit.*\(fetch\)') {
        $kitRemoteName = $Matches[1]
        break
    }
}

# -- 3b. Kit version print ------------------------------------
$kitVersion = "(unknown)"
$kitEffective = "(unknown)"
$versionFile = Join-Path $repoRoot (Join-Path $subtreePrefix "VIBE-CODING.VERSION.md")
if (Test-Path $versionFile) {
    $vContent = Get-Content $versionFile -Raw
    if ($vContent -match '\*\*Version:\*\*\s*(v[\d.]+)') {
        $kitVersion = $Matches[1]
    }
    if ($vContent -match '\*\*Effective Date:\*\*\s*(\d{4}-\d{2}-\d{2})') {
        $kitEffective = $Matches[1]
    }
}
Write-Host "KitVersion: $kitVersion (Effective $kitEffective)" -ForegroundColor Green

# -- 3c. Kit version lag check (WARN only) --------------------
$kitVersionRemote = "(unavailable)"
$kitLagResult = "SKIP"
$lagRef = $null
try {
    if ($kitRemoteName) {
        $lagRef = "$kitRemoteName/main"
        $taFetchStatus = "DEGRADED"
    }

    if ($lagRef) {
        $remoteContent = git show "${lagRef}:VIBE-CODING.VERSION.md" 2>$null | Out-String
        if ($remoteContent -match '\*\*Version:\*\*\s*(v[\d.]+)') {
            $kitVersionRemote = $Matches[1]
        }
    }
} catch {
    # Network unavailable or other error — continue silently
}

Write-Host "KitVersionLocal=$kitVersion" -ForegroundColor Gray
if ($kitVersionRemote -eq "(unavailable)") {
    Write-Host "KitVersionRemote=(unavailable)" -ForegroundColor Yellow
    Write-Host "WARN: Could not check remote kit version from current local refs. Audit did not fetch or update the kit." -ForegroundColor Yellow
    $kitLagResult = "WARN(unavailable)"
} elseif ($kitVersion -ne $kitVersionRemote) {
    Write-Host "KitVersionRemote=$kitVersionRemote" -ForegroundColor Yellow
    Write-Host "WARN: Kit version lag - local $kitVersion vs remote $kitVersionRemote. Audit did not update the kit." -ForegroundColor Yellow
    $kitLagResult = "WARN(lag)"
} else {
    Write-Host "KitVersionRemote=$kitVersionRemote" -ForegroundColor Green
    Write-Host "OK: Kit version is current." -ForegroundColor Green
    $kitLagResult = "OK"
}

# -- 3d. Consumer-Kit Drift Gate --------------------------------
$driftStatus = "PASS"
$driftClassification = "CURRENT"
$driftNotes = @()

# Factor 1: Kit version currency (from 3c)
if ($kitLagResult -eq "WARN(lag)") {
    $driftStatus = "WARN"
    $driftClassification = "STALE"
    $driftNotes += "Kit version lag: local $kitVersion vs remote $kitVersionRemote"
    $requiredActions += "You need to run run-vibe -Tool kit-update before proceeding."
} elseif ($kitLagResult -eq "WARN(unavailable)") {
    $driftStatus = "WARN"
    $driftNotes += "Remote kit version unavailable — cannot confirm currency"
    $requiredActions += "Kit currency could not be confirmed. You need to verify remote state manually before proceeding."
}

# Factor 2: Sentinel file integrity (committed divergence detection)
# Only meaningful when version matches (or pull just completed) AND remote ref available
$sentinelRef = $null
if ($kitRemoteName) {
    $sentinelRef = "$kitRemoteName/main"
} elseif ($lagRef -and $lagRef -ne "(unavailable)") {
    $sentinelRef = $lagRef
}

if ($sentinelRef -and ($kitLagResult -eq "OK" -or $kitUpdateResult -eq "DONE")) {
    $sentinelFiles = @("VIBE-CODING.VERSION.md", "protocol/protocol-v7.md", "protocol-lite.md")
    $divergentFiles = @()
    foreach ($sf in $sentinelFiles) {
        try {
            $localBlob = (git rev-parse "HEAD:${subtreePrefix}/$sf" 2>$null) | Out-String
            $localBlob = $localBlob.Trim()
            $remoteBlob = (git rev-parse "${sentinelRef}:$sf" 2>$null) | Out-String
            $remoteBlob = $remoteBlob.Trim()
            if ($localBlob -and $remoteBlob -and $localBlob -ne $remoteBlob) {
                $divergentFiles += $sf
            }
        } catch { }
    }
    if ($divergentFiles.Count -gt 0) {
        $driftStatus = "BLOCKED"
        $driftClassification = "DIVERGENT"
        $driftNotes += "Sentinel files differ from kit source: $($divergentFiles -join ', ')"
    }
}

# Factor 3: Required consumer wiring
$overlayIdxPath = Join-Path $repoRoot "$docsRoot/overlays/OVERLAY-INDEX.md"
if (-not (Test-Path $overlayIdxPath)) {
    if ($driftStatus -ne "BLOCKED") { $driftStatus = "WARN" }
    $driftNotes += "Missing consumer wiring: $docsRoot/overlays/OVERLAY-INDEX.md"
}

Write-Host ""
Write-Host "--- Consumer-Kit Drift Gate ---" -ForegroundColor Cyan
Write-Host ("  Classification : {0}" -f $driftClassification) -ForegroundColor $(if ($driftClassification -eq 'CURRENT') { 'Green' } elseif ($driftClassification -eq 'STALE') { 'Yellow' } else { 'Red' })
Write-Host ("  Drift Status   : {0}" -f $driftStatus) -ForegroundColor $(if ($driftStatus -eq 'PASS') { 'Green' } elseif ($driftStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
foreach ($note in $driftNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }

# -- 4. forGPT packet state (audit-only) ----------------------
$forGptStatus = "MISSING"
$vmDate = "MISSING"
$vmCommit = "MISSING"
$packetStatus = "UNKNOWN"
$packetNotes = @()

$packetResolution = Resolve-VibePacketPath -RepoRoot $repoRoot -DocsRoot $docsRoot
$packetPathRel = $packetResolution.PacketPath
$packetPathSource = $packetResolution.PacketPathSource
$packetDirDisplay = $packetPathRel
if ($packetResolution.Notes.Count -gt 0) {
    $packetNotes += $packetResolution.Notes
}

$forGptDir = Join-Path $repoRoot ($packetPathRel -replace '/', '\\')
if (Test-Path $forGptDir) {
    $forGptStatus = "PRESENT"
}

# Parse VERSION-MANIFEST if present
$vmPath = Join-Path $forGptDir "VERSION-MANIFEST.md"
if (Test-Path $vmPath) {
    $vmContent = Get-Content $vmPath -Raw
    if ($vmContent -match '\*\*Generated\*\*\s*\|\s*(\d{4}-\d{2}-\d{2})') {
        $vmDate = $Matches[1]
    }
    if ($vmContent -match '\*\*Git Commit\*\*\s*\|\s*`([^`]+)`') {
        $vmCommit = $Matches[1]
    }
}

$headCommit = (git rev-parse --short HEAD 2>$null) -join ""
if ($forGptStatus -eq "MISSING") {
    $packetStatus = "MISSING"
    $packetNotes += "forGPT directory missing"
    $requiredActions += "You need to run packet sync now if you need a current packet for handoff."
} elseif (-not (Test-Path $vmPath)) {
    $packetStatus = "MISSING"
    $packetNotes += "VERSION-MANIFEST.md missing"
    $requiredActions += "You need to run packet sync now if you need a current packet for handoff."
} elseif ($vmCommit -eq "MISSING") {
    $packetStatus = "UNKNOWN"
    $packetNotes += "VERSION-MANIFEST.md present but Git Commit could not be parsed"
    $requiredActions += "Packet freshness could not be confirmed. You need to verify packet state manually or run packet sync now."
} elseif ($headCommit -and $vmCommit -ne $headCommit) {
    # Narrow one-ahead exception: if the manifest commit equals the parent of HEAD,
    # and HEAD only contains forGPT packet files, treat as CURRENT.
    # This handles the run-vibe -Tool start Step 3b auto-commit case where
    # sync-forgpt writes the manifest before the auto-commit advances HEAD by one.
    $packetStatus = "STALE"
    $packetNotes += "VERSION-MANIFEST commit $vmCommit does not match current HEAD $headCommit"

    if ($treeState -eq "CLEAN") {
        $parentCommit = (git rev-parse --short HEAD~1 2>$null) -join ""
        if ($parentCommit -and $vmCommit -eq $parentCommit) {
            # Wrap all pipeline outputs in @() to avoid StrictMode .Count crash when
            # exactly one file is changed (pipeline returns a scalar string, not an array).
            $changedFiles  = @(git diff-tree --no-commit-id --name-only -r HEAD 2>$null | Where-Object { $_ })
            $packetRelDir = ($packetPathRel.TrimEnd('/\\') + "/") -replace '\\','/'
            $nonForGptFiles = @($changedFiles | Where-Object { -not ($_ -replace '\\','/' -like "$packetRelDir*") })
            $allForGptOnly  = $changedFiles.Count -gt 0 -and $nonForGptFiles.Count -eq 0
            if ($allForGptOnly) {
                $packetStatus = "CURRENT"
                $packetNotes = @(
                    "VERSION-MANIFEST matches parent of HEAD ($vmCommit); HEAD only contains packet auto-commit"
                )
            }
        }
    }

    if ($packetStatus -eq "STALE") {
        $requiredActions += "You need to run packet sync now if you need a current packet for handoff."
    }
} else {
    $packetStatus = "CURRENT"
}

Write-Host ""
Write-Host "--- Packet Status ---" -ForegroundColor Cyan
Write-Host ("  Packet         : {0}" -f $packetStatus) -ForegroundColor $(if ($packetStatus -eq 'CURRENT') { 'Green' } elseif ($packetStatus -eq 'STALE' -or $packetStatus -eq 'UNKNOWN') { 'Yellow' } else { 'Red' })
foreach ($note in $packetNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }
if ($packetStatus -ne 'CURRENT') {
    Write-Host "    -> Audit did not run packet sync." -ForegroundColor Yellow
}

# -- 4c. Owner-only snapshot isolation check --------------------
$snapshotStatus = "PASS(absent)"
$snapshotWarnCount = 0
$snapshotArtifactPaths = @(
    (Join-Path $repoRoot (Join-Path $docsRoot "forGPT/VIBE-KIT-SNAPSHOT.md")),
    (Join-Path $repoRoot (Join-Path $docsRoot "VIBE-KIT-SNAPSHOT.md")),
    (Join-Path $repoRoot "VIBE-KIT-SNAPSHOT.md"),
    (Join-Path $repoRoot (Join-Path $subtreePrefix "docs/forGPT/VIBE-KIT-SNAPSHOT.md"))
)
$snapshotArtifactsFound = @($snapshotArtifactPaths | Where-Object { Test-Path $_ } | Select-Object -Unique)
if ($snapshotArtifactsFound.Count -gt 0) {
    $snapshotStatus = "WARN(present)"
    $snapshotWarnCount = $snapshotArtifactsFound.Count
    $requiredActions += "Owner-only snapshot artifact detected in consumer repo; remove VIBE-KIT-SNAPSHOT.md from distributed/consumer paths."
    foreach ($foundPath in $snapshotArtifactsFound) {
        Write-Host "WARN: Owner-only snapshot artifact detected: $foundPath" -ForegroundColor Yellow
    }
}

# -- 4b. Consumer doc-audit (hard fail) -----------------------
$auditResult = "SKIPPED"
$auditScript = Join-Path $repoRoot (Join-Path $subtreePrefix "tools/doc-audit.ps1")
if ($SkipAudit) {
    $auditResult = "SKIPPED(Flag)"
} elseif ($WhatIf) {
    # Detect whether doc-audit supports -StartSession
    $auditHasStartSession = $false
    try {
        $auditParams = (Get-Command $auditScript -ErrorAction SilentlyContinue).Parameters
        if ($auditParams -and $auditParams.ContainsKey('StartSession')) {
            $auditHasStartSession = $true
        }
    } catch { }
    if ($auditHasStartSession) {
        Write-Host "[WhatIf] Would run: $auditScript -Mode Consumer -StartSession" -ForegroundColor Cyan
    } else {
        Write-Host "[WhatIf] Would run: $auditScript -Mode Consumer" -ForegroundColor Cyan
    }
    $auditResult = "SKIPPED(WhatIf)"
} elseif (Test-Path $auditScript) {
    Write-Host "Running Consumer doc-audit..." -ForegroundColor Yellow
    # Detect whether doc-audit supports -StartSession
    $auditHasStartSession = $false
    try {
        $auditParams = (Get-Command $auditScript -ErrorAction SilentlyContinue).Parameters
        if ($auditParams -and $auditParams.ContainsKey('StartSession')) {
            $auditHasStartSession = $true
        }
    } catch { }
    if ($auditHasStartSession) {
        & $auditScript -Mode Consumer -StartSession
    } else {
        & $auditScript -Mode Consumer
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "HARD STOP: Consumer doc-audit FAILED (exit $LASTEXITCODE). Fix issues above before proceeding." -ForegroundColor Red
        exit 1
    }
    $auditResult = "PASS"
} else {
    Write-Host "WARNING: doc-audit.ps1 not found at $auditScript" -ForegroundColor Yellow
    $auditResult = "MISSING"
}

# -- 5. ResearchIndex -----------------------------------------
$riPath = "MISSING"
$riDate = "MISSING"
$riCandidate = Join-Path $repoRoot "$docsRoot/research/ResearchIndex.md"
if (Test-Path $riCandidate) {
    $riPath = "$docsRoot/research/ResearchIndex.md"
    $riContent = Get-Content $riCandidate -Raw
    if ($riContent -match 'Last updated:\s*(\d{4}-\d{2}-\d{2})') {
        $riDate = $Matches[1]
    }
}

# -- 5b. NEXT.md date + ResearchIndex drift warning -----------
$nextDate = $null
$nextCandidate = Join-Path $repoRoot "$docsRoot/project/NEXT.md"
if (Test-Path $nextCandidate) {
    $nextContent = Get-Content $nextCandidate -Raw
    if ($nextContent -match 'Last [Uu]pdated:\s*(\d{4}-\d{2}-\d{2})') {
        $nextDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
    }
}

$riDateParsed = $null
if ($riDate -ne "MISSING") {
    try { $riDateParsed = [datetime]::ParseExact($riDate, 'yyyy-MM-dd', $null) } catch { }
}

if ($nextDate -and $riDateParsed -and $riDateParsed -gt $nextDate) {
    Write-Host "WARNING: ResearchIndex.md ($riDate) is newer than NEXT.md ($($nextDate.ToString('yyyy-MM-dd'))); review whether NEXT.md should be updated." -ForegroundColor Yellow
}

# -- 5c. Staleness Expiry Gate (PAUSE.md freshness) ------------
$stalenessStatus = "PASS"
$stalenessClassification = "N/A"
$stalenessAge = -1
$stalenessNotes = @()

# Locate consumer PAUSE.md (not the kit template)
$pausePath = $null
$pauseCandidates = @(
    (Join-Path $repoRoot "PAUSE.md"),
    (Join-Path $repoRoot (Join-Path $docsRoot "PAUSE.md"))
)
foreach ($candidate in $pauseCandidates) {
    if (Test-Path $candidate) {
        $pausePath = $candidate
        break
    }
}

if ($pausePath) {
    $pauseContent = Get-Content $pausePath -Raw
    if ($pauseContent -match '\*\*Date:\*\*\s*(\d{4}-\d{2}-\d{2})') {
        $pauseDate = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null)
        $stalenessAge = ([datetime]::Today - $pauseDate).Days

        if ($stalenessAge -le 7) {
            $stalenessStatus = "PASS"
            $stalenessClassification = "CURRENT"
        } elseif ($stalenessAge -le 30) {
            $stalenessStatus = "WARN"
            $stalenessClassification = "STALE"
            $stalenessNotes += "PAUSE.md is $stalenessAge days old — review and confirm handoff state before relying on it"
        } else {
            $stalenessStatus = "BLOCKED"
            $stalenessClassification = "EXPIRED"
            $stalenessNotes += "PAUSE.md is $stalenessAge days old (>30 days) — re-verify all handoff state before proceeding"
        }
    } elseif ($pauseContent -match 'YYYY-MM-DD') {
        # Unpopulated template — no active handoff state
        $stalenessClassification = "TEMPLATE"
        $stalenessNotes += "PAUSE.md contains template placeholder — no active handoff state to check"
    } else {
        $stalenessStatus = "WARN"
        $stalenessClassification = "UNKNOWN"
        $stalenessNotes += "PAUSE.md found but no parseable Date field"
    }
} else {
    $stalenessNotes += "No PAUSE.md found — staleness check skipped"
}

# -- NEXT.md staleness (Covered Artifact: NEXT.md active step) --
$nextmdStalenessClassification = "N/A"
$nextmdStalenessAge = -1
$nextmdStalenessRelPath = "$docsRoot/project/NEXT.md"
$nextmdStalenessFullPath = Join-Path $repoRoot $nextmdStalenessRelPath

if (Test-Path $nextmdStalenessFullPath) {
    try {
        $nextmdLastCommitRaw = (git log -1 --format="%ci" -- $nextmdStalenessRelPath 2>$null) | Out-String
        $nextmdLastCommitRaw = $nextmdLastCommitRaw.Trim()
        if ($nextmdLastCommitRaw -match '^\d{4}-\d{2}-\d{2}') {
            $nextmdCommitDate = [datetime]::ParseExact($nextmdLastCommitRaw.Substring(0, 10), 'yyyy-MM-dd', $null)
            $nextmdStalenessAge = ([datetime]::Today - $nextmdCommitDate).Days

            if ($nextmdStalenessAge -le 7) {
                $nextmdStalenessClassification = "CURRENT"
            } elseif ($nextmdStalenessAge -le 21) {
                $nextmdStalenessClassification = "STALE"
                if ($stalenessStatus -ne "BLOCKED") { $stalenessStatus = "WARN" }
                $stalenessNotes += "NEXT.md last committed $nextmdStalenessAge days ago — review Immediate Next Steps before trusting"
            } else {
                $nextmdStalenessClassification = "STALE"
                if ($stalenessStatus -ne "BLOCKED") { $stalenessStatus = "WARN" }
                $stalenessNotes += "NEXT.md last committed $nextmdStalenessAge days ago (>21 days) — review before trusting; BLOCK only if content contradicts current repo state"
            }
        } else {
            $nextmdStalenessClassification = "UNKNOWN"
            $stalenessNotes += "NEXT.md exists but no git commit history found"
        }
    } catch {
        $nextmdStalenessClassification = "UNKNOWN"
        $stalenessNotes += "NEXT.md: could not determine last commit date"
    }
} else {
    $stalenessNotes += "No NEXT.md found at $nextmdStalenessRelPath — NEXT.md staleness check skipped"
}

Write-Host ""
Write-Host "--- Staleness Expiry Gate ---" -ForegroundColor Cyan
Write-Host ("  PAUSE.md       : {0}" -f $stalenessClassification) -ForegroundColor $(if ($stalenessClassification -eq 'CURRENT' -or $stalenessClassification -eq 'N/A' -or $stalenessClassification -eq 'TEMPLATE') { 'Green' } elseif ($stalenessClassification -eq 'STALE') { 'Yellow' } else { 'Red' })
if ($stalenessAge -ge 0) { Write-Host ("  PAUSE.md Age   : {0} day(s)" -f $stalenessAge) -ForegroundColor $(if ($stalenessAge -le 7) { 'Green' } elseif ($stalenessAge -le 30) { 'Yellow' } else { 'Red' }) }
Write-Host ("  NEXT.md        : {0}" -f $nextmdStalenessClassification) -ForegroundColor $(if ($nextmdStalenessClassification -eq 'CURRENT' -or $nextmdStalenessClassification -eq 'N/A') { 'Green' } elseif ($nextmdStalenessClassification -eq 'STALE') { 'Yellow' } else { 'Red' })
if ($nextmdStalenessAge -ge 0) { Write-Host ("  NEXT.md Age    : {0} day(s)" -f $nextmdStalenessAge) -ForegroundColor $(if ($nextmdStalenessAge -le 7) { 'Green' } elseif ($nextmdStalenessAge -le 21) { 'Yellow' } else { 'Red' }) }
Write-Host ("  Staleness      : {0}" -f $stalenessStatus) -ForegroundColor $(if ($stalenessStatus -eq 'PASS') { 'Green' } elseif ($stalenessStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
foreach ($note in $stalenessNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }

# -- 5d. Decision-Queue Gate (PAUSE.md decision items) ---------
$dqStatus = "PASS"
$dqCount = 0
$dqMalformed = 0
$dqOldestAge = -1
$dqNotes = @()

if ($pausePath -and (Test-Path $pausePath)) {
    $pauseLines = Get-Content $pausePath
    $inDecisionQueue = $false
    $headerParsed = $false
    foreach ($line in $pauseLines) {
        # Detect Decision Queue section start
        if ($line -match '^\s*##\s+Decision Queue') {
            $inDecisionQueue = $true
            continue
        }
        # Detect next section (exit Decision Queue)
        if ($inDecisionQueue -and $line -match '^\s*##\s' -and $line -notmatch 'Decision Queue') {
            break
        }
        if (-not $inDecisionQueue) { continue }
        # Skip header row and separator
        if ($line -match '^\s*\|.*Item.*Decision Owner') { $headerParsed = $true; continue }
        if ($line -match '^\s*\|[\s-:|]+\|?\s*$') { continue }
        # Skip template placeholder rows
        if ($line -match '_\(item label\)_' -or $line -match 'YYYY-MM-DD') { continue }
        # Parse data rows
        if ($headerParsed -and $line -match '^\s*\|') {
            $cells = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            if ($cells.Count -ge 4) {
                $dqCount++
                $itemLabel = $cells[0]
                $owner = $cells[1]
                $why = $cells[2]
                $dateAdded = $cells[3]
                # Check well-formedness (required fields non-empty)
                if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($why) -or [string]::IsNullOrWhiteSpace($dateAdded)) {
                    $dqMalformed++
                    $dqNotes += "Malformed: '$itemLabel' missing required field(s)"
                }
                # Check age
                if ($dateAdded -match '^\d{4}-\d{2}-\d{2}$') {
                    try {
                        $itemDate = [datetime]::ParseExact($dateAdded, 'yyyy-MM-dd', $null)
                        $itemAge = ([datetime]::Today - $itemDate).Days
                        if ($itemAge -gt $dqOldestAge) { $dqOldestAge = $itemAge }
                    } catch { }
                }
            } else {
                $dqCount++
                $dqMalformed++
                $dqNotes += "Malformed: row has fewer than 4 columns"
            }
        }
    }

    # Determine verdict
    if ($dqCount -eq 0) {
        $dqStatus = "PASS"
    } else {
        # Count thresholds
        if ($dqCount -gt 5) { $dqStatus = "BLOCKED"; $dqNotes += "DECISION NEEDED count ($dqCount) exceeds cap of 5" }
        elseif ($dqCount -gt 3) { if ($dqStatus -ne "BLOCKED") { $dqStatus = "WARN" }; $dqNotes += "DECISION NEEDED count ($dqCount) elevated (cap: 3)" }
        # Malformed thresholds
        if ($dqMalformed -ge 2) { $dqStatus = "BLOCKED"; $dqNotes += "$dqMalformed malformed item(s) — BLOCKED" }
        elseif ($dqMalformed -eq 1 -and $dqStatus -ne "BLOCKED") { $dqStatus = "WARN" }
        # Age thresholds
        if ($dqOldestAge -gt 30) { $dqStatus = "BLOCKED"; $dqNotes += "Oldest item is $dqOldestAge days old (>30) — BLOCKED" }
        elseif ($dqOldestAge -gt 14 -and $dqStatus -ne "BLOCKED") { $dqStatus = "WARN"; $dqNotes += "Oldest item is $dqOldestAge days old (>14) — review needed" }
    }
} else {
    $dqNotes += "No PAUSE.md found — decision-queue check skipped"
}

Write-Host ""
Write-Host "--- Decision-Queue Gate ---" -ForegroundColor Cyan
Write-Host ("  Items          : {0}" -f $dqCount) -ForegroundColor $(if ($dqCount -le 3) { 'Green' } elseif ($dqCount -le 5) { 'Yellow' } else { 'Red' })
Write-Host ("  Malformed      : {0}" -f $dqMalformed) -ForegroundColor $(if ($dqMalformed -eq 0) { 'Green' } elseif ($dqMalformed -eq 1) { 'Yellow' } else { 'Red' })
Write-Host ("  DecisionQueue  : {0}" -f $dqStatus) -ForegroundColor $(if ($dqStatus -eq 'PASS') { 'Green' } elseif ($dqStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
if ($dqOldestAge -ge 0) { Write-Host ("  Oldest Item    : {0} day(s)" -f $dqOldestAge) -ForegroundColor $(if ($dqOldestAge -le 14) { 'Green' } elseif ($dqOldestAge -le 30) { 'Yellow' } else { 'Red' }) }
foreach ($note in $dqNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }

# -- 6. Open PRs ----------------------------------------------
$prCount = "UNKNOWN"
$prList = "gh CLI not available"
try {
    $ghVersion = gh --version 2>$null
    if ($ghVersion) {
        $taGhStatus = "AVAILABLE"
        $prs = gh pr list --state open --json number,title 2>$null | ConvertFrom-Json
        if ($null -eq $prs -or $prs.Count -eq 0) {
            $prCount = "0"
            $prList = "none"
        } else {
            $prCount = "$($prs.Count)"
            $prList = ($prs | ForEach-Object { "#$($_.number) $($_.title)" }) -join "; "
        }
    }
} catch {
    # gh not available or auth issue
    if ($taGhStatus -eq "AVAILABLE") { $taGhStatus = "DEGRADED" }
}

# -- 6b. Tool/Auth Fragility Gate ------------------------------
$taStatus = "PASS"
$taNotes = @()

if ($taGhStatus -ne "AVAILABLE") {
    $taNotes += "gh CLI: $taGhStatus — PR count and Remote Reality may be unverifiable"
}
if ($taFetchStatus -ne "AVAILABLE") {
    $taNotes += "git fetch: $taFetchStatus — remote-dependent checks use stale or missing refs"
}

# Determine verdict: BLOCKED only if a degraded tool's effect is not already reflected
# In session-start context, gh unavailability is reflected in OpenPRs=UNKNOWN (informational, no gate)
# Fetch unavailability is reflected in kitLag WARN(unavailable) and drift WARN
# So typically WARN, not BLOCKED — unless future gates claim PASS despite tool absence
if ($taGhStatus -eq "AVAILABLE" -and $taFetchStatus -eq "AVAILABLE") {
    $taStatus = "PASS"
} elseif ($taNotes.Count -gt 0) {
    $taStatus = "WARN"
}

Write-Host ""
Write-Host "--- Tool/Auth Fragility Gate ---" -ForegroundColor Cyan
Write-Host ("  gh CLI         : {0}" -f $taGhStatus) -ForegroundColor $(if ($taGhStatus -eq 'AVAILABLE') { 'Green' } elseif ($taGhStatus -eq 'DEGRADED') { 'Yellow' } else { 'Red' })
Write-Host ("  git fetch      : {0}" -f $taFetchStatus) -ForegroundColor $(if ($taFetchStatus -eq 'AVAILABLE') { 'Green' } elseif ($taFetchStatus -eq 'DEGRADED') { 'Yellow' } else { 'Red' })
Write-Host ("  ToolAuth       : {0}" -f $taStatus) -ForegroundColor $(if ($taStatus -eq 'PASS') { 'Green' } elseif ($taStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
foreach ($note in $taNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }

# -- 6c. Visibility Contract surfacing -------------------------
$vcStatus = "NOT_FOUND"
$vcFields = @{}
$vcFile = $null

# Locate visibility-contract overlay in consumer repo
if ($docsRoot) {
    $vcRelative = Join-Path $docsRoot "overlays/visibility-contract.md"
    $vcCandidate = Join-Path $repoRoot $vcRelative
    if (Test-Path $vcCandidate) { $vcFile = $vcCandidate }
}

if ($vcFile) {
    # Parse markdown table rows: | **field_name** | value |
    $vcPlaceholderPattern = 'TODO|TBD|PLACEHOLDER|FILL|TEMPLATE|example\.com|example\.org'
    foreach ($line in (Get-Content $vcFile -ErrorAction SilentlyContinue)) {
        if ($line -match '^\|\s*\*{0,2}(\w+)\*{0,2}\s*\|\s*(.+?)\s*\|?\s*$') {
            $fName  = $Matches[1].Trim()
            $fValue = $Matches[2].Trim().Trim('`').Trim()
            # Skip header row and empty/placeholder values
            if ($fName -eq 'Field' -or $fName -eq 'Required') { continue }
            if (-not $fValue) { continue }
            if ($fValue -match '<[^>]+>') { continue }           # template variable
            if ($fValue -match $vcPlaceholderPattern) { continue } # placeholder token
            $vcFields[$fName] = $fValue
        }
    }
    if ($vcFields.Count -gt 0) {
        $vcStatus = "OK"
    } else {
        $vcStatus = "UNPOPULATED"
    }
}

Write-Host ""
if ($vcStatus -eq "OK") {
    Write-Host "--- Visibility Links ---" -ForegroundColor Cyan
    foreach ($entry in $vcFields.GetEnumerator()) {
        Write-Host ("  {0} : {1}" -f $entry.Key, $entry.Value)
    }
} elseif ($vcStatus -eq "UNPOPULATED") {
    Write-Host "  Visibility: overlay found but no values populated — see templates/visibility-contract-overlay.example.md" -ForegroundColor DarkGray
} else {
    Write-Host "  Visibility: no overlay at <DOCS_ROOT>/overlays/visibility-contract.md — see templates/visibility-contract-overlay.example.md" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "--- Clean-Close Proof ---" -ForegroundColor Cyan
Write-Host ("  Proof          : {0}" -f $cleanCloseProofStatus) -ForegroundColor $(if ($cleanCloseProofStatus -eq 'VALID') { 'Green' } elseif ($cleanCloseProofStatus -eq 'MISSING') { 'DarkGray' } else { 'Yellow' })
if ($cleanCloseProofAgeDays -ge 0) {
    Write-Host ("  Proof Age      : {0} day(s)" -f $cleanCloseProofAgeDays) -ForegroundColor $(if ($cleanCloseProofAgeDays -le $cleanCloseProofFreshDays) { 'Green' } else { 'Yellow' })
}
Write-Host "    -> $cleanCloseProofMessage" -ForegroundColor $(if ($cleanCloseProofStatus -eq 'VALID') { 'Green' } elseif ($cleanCloseProofStatus -eq 'MISSING') { 'DarkGray' } else { 'Yellow' })

$pssPath = Join-Path $forGptDir "PROJECT-STATE-SUMMARY.md"
$pssStatus = if ($forGptStatus -eq "PRESENT" -and (Test-Path $pssPath)) { "PRESENT" } elseif ($forGptStatus -eq "PRESENT") { "MISSING" } else { "SKIP(no forGPT directory)" }

# -- 7. Print session audit block ------------------------------
Write-Host ""
Write-Host "========== SESSION START AUDIT ==========" -ForegroundColor Cyan
Write-Host "RepoRoot=$repoRoot | Branch=$branch | Tree=$treeState"
Write-Host "DOCS_ROOT=$docsRoot | Reason=$docsReason"
Write-Host "forGPT=$forGptStatus | VERSION-MANIFEST=$vmDate | Commit=$vmCommit | KitUpdate=$kitUpdateResult"
Write-Host "PacketPath=$packetDirDisplay | Source=$packetPathSource | Enabled=$($packetResolution.PacketEnabled)"
Write-Host "KitVersion=$kitVersion | Effective=$kitEffective | KitLag=$kitLagResult | ConsumerAudit=$auditResult"
Write-Host "ConsumerDrift=$driftStatus ($driftClassification)"
Write-Host "PacketStatus=$packetStatus"
Write-Host "VibeKitSnapshot=$snapshotStatus (warnings=$snapshotWarnCount)"
Write-Host "CleanCloseProof=$cleanCloseProofStatus"
Write-Host "StalenessExpiry=$stalenessStatus (PAUSE=$stalenessClassification, NEXT=$nextmdStalenessClassification)"
Write-Host "DecisionQueue=$dqStatus (items=$dqCount, malformed=$dqMalformed)"
Write-Host "ToolAuth=$taStatus (gh=$taGhStatus, fetch=$taFetchStatus)"
Write-Host "Visibility=$vcStatus"
Write-Host "ProjectStateSummary=$pssStatus"
Write-Host "ResearchIndex=$riPath | LastUpdated=$riDate"
Write-Host "OpenPRs=$prCount - $prList"
Write-Host "=========================================" -ForegroundColor Cyan

if ($requiredActions.Count -gt 0) {
    Write-Host ""
    Write-Host "Required Actions:" -ForegroundColor Yellow
    $requiredActions | Select-Object -Unique | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
# -- Suggested Repair Order (G-01) ---------------------------
$repairItems = [System.Collections.Generic.List[string]]::new()
if ($driftStatus     -eq 'BLOCKED') { $repairItems.Add('[BLOCKED] Consumer-Kit Drift Gate  → run kit-update.ps1') }
if ($stalenessStatus -eq 'BLOCKED') { $repairItems.Add('[BLOCKED] Staleness Expiry Gate     → review PAUSE.md / NEXT.md') }
if ($dqStatus        -eq 'BLOCKED') { $repairItems.Add('[BLOCKED] Decision-Queue Gate       → resolve items in PAUSE.md Decision Queue') }
if ($taStatus        -eq 'BLOCKED') { $repairItems.Add('[BLOCKED] Tool/Auth Fragility Gate  → restore gh CLI / git fetch') }
if ($driftStatus     -eq 'WARN'   ) { $repairItems.Add('[WARN]    Consumer-Kit Drift Gate  → review kit-update.ps1 output') }
if ($stalenessStatus -eq 'WARN'   ) { $repairItems.Add('[WARN]    Staleness Expiry Gate     → review PAUSE.md / NEXT.md before trusting') }
if ($dqStatus        -eq 'WARN'   ) { $repairItems.Add('[WARN]    Decision-Queue Gate       → review PAUSE.md Decision Queue items') }
if ($taStatus        -eq 'WARN'   ) { $repairItems.Add('[WARN]    Tool/Auth Fragility Gate  → check gh CLI / git fetch availability') }
if ($packetStatus    -eq 'STALE'  ) { $repairItems.Add('[WARN]    forGPT packet              → run sync-forgpt (after canonical docs settled)') }

if ($repairItems.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Suggested Repair Order ---" -ForegroundColor Yellow
    $step = 1
    foreach ($item in $repairItems) {
        Write-Host ("  {0}. {1}" -f $step, $item) -ForegroundColor $(if ($item -match '\[BLOCKED\]') { 'Red' } else { 'Yellow' })
        $step++
    }
    Write-Host ("  {0}. Re-run session-start after repairs" -f $step) -ForegroundColor Cyan
    Write-Host ("  {1}. Feature work only after no BLOCKED gates remain" -f $step, ($step + 1)) -ForegroundColor Cyan
    Write-Host "  (Copilot: address in order above; do not ask Stephen which to fix first)" -ForegroundColor DarkGray
}

Write-Host "Audit completed without changing your files." -ForegroundColor Cyan

} finally {
    Pop-Location
}

# Exit-code contract:
# - 0: audit completed without BLOCKED/HARD STOP/crash
# - non-zero: HARD STOP, explicit blocked exit, or uncaught script failure
exit 0
