<#
.SYNOPSIS
  End-of-session repo hygiene check: tracked changes, untracked items, orphan branches.
.DESCRIPTION
  Run this from ANY consumer repo (any subdirectory). It detects repo root
    and DOCS_ROOT automatically. Exits nonzero whenever CLEAN FIELD READY is NO.
    Evidence gathering and report output remain unchanged.
.PARAMETER SkipFetch
  Skip git fetch origin (use stale remote refs for branch check).
.PARAMETER WriteReport
  Write a markdown status report under <DOCS_ROOT>/status/.
.PARAMETER WhatIf
  Print what would happen without fetching or writing files.
#>
[CmdletBinding()]
param(
    [switch]$SkipFetch,
    [switch]$WriteReport,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cleanCloseProofSchemaVersion = 1

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

# -- Helper: read kit version if available ---------------------
function Get-KitVersionForProof {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$DocsRoot
    )

    $candidates = @(
        (Join-Path $RepoRoot (Join-Path $DocsRoot "vibe-coding\VIBE-CODING.VERSION.md")),
        (Join-Path $RepoRoot "VIBE-CODING.VERSION.md")
    )

    foreach ($candidate in $candidates) {
        if (-not (Test-Path $candidate)) { continue }
        $content = Get-Content $candidate -Raw
        if ($content -match '\*\*Version:\*\*\s*(v[\d.]+)') {
            return $Matches[1]
        }
    }

    return "(unknown)"
}

# -- Helper: write proof atomically ----------------------------
function Write-CleanCloseProof {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProofPath,
        [Parameter(Mandatory)][hashtable]$ProofData
    )

    $proofDir = Split-Path $ProofPath -Parent
    if (-not (Test-Path $proofDir)) {
        New-Item -ItemType Directory -Path $proofDir -Force | Out-Null
    }

    $tempPath = Join-Path $proofDir ([System.IO.Path]::GetRandomFileName())
    try {
        $json = $ProofData | ConvertTo-Json -Depth 4
        Set-Content -Path $tempPath -Value $json -Encoding UTF8
        Move-Item -Path $tempPath -Destination $ProofPath -Force
    } finally {
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# -- Helper: run git tolerant of stderr progress ---------------
function Invoke-GitSafe {
    <#
    .SYNOPSIS
      Runs git with stderr tolerance so progress output does not
      become a terminating error under $ErrorActionPreference=Stop.
      Throws only when git returns a non-zero exit code.
    #>
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

try {

# -- 1. DOCS_ROOT (prefer script-relative) ----------------------
$docsRoot = $null

$kitHead = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ((Split-Path $kitHead -Leaf) -eq "vibe-coding") {
    $docsRootFull = (Resolve-Path (Join-Path $kitHead "..")).Path
    $repoRootNorm = $repoRoot -replace '/', '\'
    $docsRootNorm = $docsRootFull -replace '/', '\'
    if ($docsRootNorm.Length -gt $repoRootNorm.Length -and $docsRootNorm.StartsWith($repoRootNorm)) {
        $docsRoot = ($docsRootNorm.Substring($repoRootNorm.Length).TrimStart('\')) -replace '\\', '/'
    } elseif ($docsRootNorm -eq $repoRootNorm) {
        $docsRoot = "."
    }
}

# Fallback: repo-root detection
if (-not $docsRoot) {
    $deDir = Join-Path $repoRoot "docs-engineering"
    $docsDir = Join-Path $repoRoot "docs"
    if ((Test-Path $deDir) -and ((Test-Path (Join-Path $deDir "vibe-coding")) -or (Test-Path (Join-Path $deDir "forGPT")))) {
        $docsRoot = "docs-engineering"
    } elseif (Test-Path $docsDir) {
        $docsRoot = "docs"
    } else {
        $docsRoot = "docs"  # safe default for path construction
    }
}

# -- 2. Current branch + HEAD ----------------------------------
$branch = (git branch --show-current 2>$null) -join ""
$headSha = (git rev-parse --short HEAD 2>$null) -join ""

# -- 3. Default branch (origin/HEAD) ---------------------------
$defaultBranch = "main"
try {
    $symRef = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -join ""
    if ($symRef -match 'refs/remotes/origin/(.+)') {
        $defaultBranch = $Matches[1]
    }
} catch { }

# -- 4. Fetch origin (unless skipped) --------------------------
$rrStatus = "BLOCKED"
$rrNotes = @()

# -- Tool/Auth Fragility tracking (populated throughout script) --
$taGhStatus = "UNAVAILABLE"     # AVAILABLE | DEGRADED | UNAVAILABLE
$taFetchStatus = "UNAVAILABLE"  # AVAILABLE | DEGRADED | UNAVAILABLE

if ($SkipFetch) {
    Write-Host "[SkipFetch] Skipping git fetch --all --prune" -ForegroundColor Yellow
    $taFetchStatus = "DEGRADED"
} elseif ($WhatIf) {
    Write-Host "[WhatIf] Would run: git fetch --all --prune" -ForegroundColor Cyan
} else {
    Write-Host "Fetching (--all --prune)..." -ForegroundColor Yellow
    try {
        Invoke-GitSafe fetch --all --prune | Out-Null
        $taFetchStatus = "AVAILABLE"
    } catch {
        Write-Host "  Warning: fetch failed: $_" -ForegroundColor Yellow
        $taFetchStatus = "DEGRADED"
    }
}

# -- 5. Print summary header -----------------------------------
Write-Host ""
Write-Host "========== END OF SESSION CHECK ==========" -ForegroundColor Cyan
Write-Host "RepoRoot     = $repoRoot"
Write-Host "DOCS_ROOT    = $docsRoot"
Write-Host "Branch       = $branch"
Write-Host "origin/HEAD  = origin/$defaultBranch"
Write-Host "HEAD         = $headSha"
Write-Host ""

# -- 6. Tracked changes ----------------------------------------
$statusLines = @(git status --porcelain)
$trackedChanges = @($statusLines | Where-Object { $_ -notmatch '^\?\?' })
$untrackedItems = @($statusLines | Where-Object { $_ -match '^\?\?' })

$snapshotArtifactCandidates = @(
    (Join-Path $repoRoot (Join-Path $docsRoot "forGPT/VIBE-KIT-SNAPSHOT.md")),
    (Join-Path $repoRoot (Join-Path $docsRoot "VIBE-KIT-SNAPSHOT.md")),
    (Join-Path $repoRoot "VIBE-KIT-SNAPSHOT.md"),
    (Join-Path $repoRoot (Join-Path $docsRoot "vibe-coding/docs/forGPT/VIBE-KIT-SNAPSHOT.md"))
)

$hasTracked = $trackedChanges.Count -gt 0

if ($hasTracked) {
    Write-Host "TRACKED CHANGES ($($trackedChanges.Count)):" -ForegroundColor Red
    foreach ($line in $trackedChanges) {
        Write-Host "  $line" -ForegroundColor Red
    }
} else {
    Write-Host "Tracked changes: none" -ForegroundColor Green
}

# -- 7. Untracked items ----------------------------------------
Write-Host ""
if ($untrackedItems.Count -gt 0) {
    Write-Host "UNTRACKED ITEMS ($($untrackedItems.Count)):" -ForegroundColor Yellow
    foreach ($line in $untrackedItems) {
        Write-Host "  $line" -ForegroundColor Yellow
    }
} else {
    Write-Host "Untracked items: none" -ForegroundColor Green
}

# -- 8. Non-merged branches ------------------------------------
Write-Host ""
$baseRef = "origin/$defaultBranch"
# Check if origin/<default> exists; fall back to local <default>
$null = git rev-parse --verify $baseRef 2>$null
if ($LASTEXITCODE -ne 0) {
    $baseRef = $defaultBranch
}

$nonMergedRaw = @(git branch --no-merged $baseRef 2>$null)
# Filter out the current branch indicator and trim whitespace
$nonMerged = @($nonMergedRaw | ForEach-Object { ($_ -replace '^\*?\s+', '').Trim() } | Where-Object { $_ -ne '' })

# Separate x-branches from normal non-merged branches
$xBranches     = @($nonMerged | Where-Object { $_ -match '^x/' })
$normalNonMerged = @($nonMerged | Where-Object { $_ -notmatch '^x/' })

if ($normalNonMerged.Count -gt 0) {
    Write-Host "NON-MERGED BRANCHES (vs $baseRef) ($($normalNonMerged.Count)):" -ForegroundColor Yellow
    foreach ($b in $normalNonMerged) {
        Write-Host "  $b" -ForegroundColor Yellow
    }
    Write-Host "  (No deletes performed - review per repo policy)" -ForegroundColor Gray
} else {
    Write-Host "Non-merged branches (vs $baseRef): none" -ForegroundColor Green
}

# -- 8a. X-Branch Report --------------------------------------
if ($xBranches.Count -gt 0) {
    Write-Host ""
    Write-Host "X-BRANCHES (experimental, never-merge) ($($xBranches.Count)):" -ForegroundColor Magenta
    foreach ($xb in $xBranches) {
        # Get age of last commit on the x-branch
        $xbAge = git log -1 --format="%cr" $xb 2>$null
        if (-not $xbAge) { $xbAge = "unknown age" }
        $ageColor = "Magenta"
        # Warn if older than 3 days (likely exceeds 1-session timebox)
        $xbDaysRaw = git log -1 --format="%ct" $xb 2>$null
        if ($xbDaysRaw) {
            $xbDays = [math]::Floor(([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$xbDaysRaw) / 86400)
            if ($xbDays -gt 3) { $ageColor = "Red" }
        }
        Write-Host "  $xb ($xbAge)" -ForegroundColor $ageColor
    }
    Write-Host "  (X-branches are never merged. Produce findings report, then delete.)" -ForegroundColor Gray
    Write-Host "  See: protocol/x-branch-contract.md" -ForegroundColor Gray
}

# -- 8b. Remote Reality Check ----------------------------------
Write-Host ""
Write-Host "--- Remote Reality Check ---" -ForegroundColor Cyan

# Ahead/behind vs default branch
$rrAhead = 0; $rrBehind = 0
$abStr = git rev-list --left-right --count "origin/$defaultBranch...HEAD" 2>$null
if ($LASTEXITCODE -eq 0 -and ($abStr | Out-String) -match '(\d+)\s+(\d+)') {
    $rrBehind = [int]$Matches[1]
    $rrAhead  = [int]$Matches[2]
    Write-Host ("  Ahead/Behind : behind {0} / ahead {1} vs origin/{2}" -f $rrBehind, $rrAhead, $defaultBranch) -ForegroundColor Cyan
    if ($rrAhead -gt 0) { $rrNotes += "Branch is ahead of origin/$defaultBranch by $rrAhead commit(s) - push or explain" }
    if ($rrBehind -gt 0) { $rrNotes += "Branch is behind origin/$defaultBranch by $rrBehind commit(s) - rebase or note" }
} else {
    Write-Host "  Ahead/Behind : unavailable (origin/$defaultBranch not found or not connected)" -ForegroundColor Yellow
    $rrNotes += "ahead/behind vs origin/$defaultBranch unavailable"
}

# Open PR list via gh CLI
if ($WhatIf) {
    Write-Host "  [WhatIf] Would run: gh pr list --state open --json number,title,headRefName,baseRefName,url" -ForegroundColor Cyan
} else {
    $ghOk = $false
    try { $null = gh --version 2>$null; if ($LASTEXITCODE -eq 0) { $ghOk = $true } } catch {}
    if ($ghOk) {
        $taGhStatus = "AVAILABLE"
        try {
            $rrPrs = gh pr list --state open --json number,title,headRefName,baseRefName,url 2>$null | ConvertFrom-Json
            if ($null -eq $rrPrs -or $rrPrs.Count -eq 0) {
                Write-Host "  Open PRs     : none" -ForegroundColor Green
                if ($nonMerged.Count -gt 0) { $rrNotes += "Non-merged branches with no open PRs - classify each: ACTIVE / PARKED / OBSOLETE" }
            } else {
                Write-Host "  Open PRs ($($rrPrs.Count)):" -ForegroundColor Cyan
                foreach ($pr in $rrPrs) {
                    Write-Host ("    #{0} [{1} -> {2}] {3}" -f $pr.number, $pr.headRefName, $pr.baseRefName, $pr.title) -ForegroundColor Cyan
                }
            }
            $rrStatus = if ($rrNotes.Count -eq 0) { "PASS" } else { "WARN" }
        } catch {
            Write-Host "  Open PRs     : gh pr list failed - record Remote Reality: BLOCKED in PAUSE.md" -ForegroundColor Yellow
            $rrNotes += "gh pr list error"
            $taGhStatus = "DEGRADED"
        }
    } else {
        Write-Host "  Open PRs     : gh not available - record Remote Reality: BLOCKED in PAUSE.md" -ForegroundColor Yellow
        $rrNotes += "gh CLI not available"
    }
}

foreach ($note in $rrNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }
Write-Host ("  Remote Reality: {0}" -f $rrStatus) -ForegroundColor $(if ($rrStatus -eq 'PASS') { 'Green' } else { 'Yellow' })

# -- 8c. Worktree Check ----------------------------------------
Write-Host ""
Write-Host "--- Workspace Reality Check ---" -ForegroundColor Cyan

$wrNotes = @()

$worktreeRaw = @(git worktree list 2>$null)
$worktreeCount = $worktreeRaw.Count
$extraWorktrees = [Math]::Max(0, $worktreeCount - 1)

Write-Host ("  Worktrees    : {0} total ({1} extra)" -f $worktreeCount, $extraWorktrees) -ForegroundColor $(if ($extraWorktrees -eq 0) { 'Green' } else { 'Yellow' })
foreach ($wt in $worktreeRaw) { Write-Host "    $wt" -ForegroundColor Gray }
if ($extraWorktrees -gt 2) {
    $wrNotes += "Extra worktrees ($extraWorktrees) exceed cap (2) - BLOCKED"
} elseif ($extraWorktrees -gt 1) {
    $wrNotes += "Extra worktrees ($extraWorktrees) above default cap (1) - review and clean up"
}

# -- 8d. Stash Check -------------------------------------------
$stashRaw = @(git stash list 2>$null)
$stashCount = $stashRaw.Count

Write-Host ("  Stashes      : {0}" -f $stashCount) -ForegroundColor $(if ($stashCount -eq 0) { 'Green' } elseif ($stashCount -le 2) { 'Yellow' } else { 'Red' })
foreach ($st in $stashRaw) { Write-Host "    $st" -ForegroundColor Gray }
if ($stashCount -gt 4) {
    $wrNotes += "Stash count ($stashCount) exceeds cap (4) - BLOCKED"
} elseif ($stashCount -gt 2) {
    $wrNotes += "Stash count ($stashCount) above default cap (2) - review stashes"
}

# -- 8d-age. Stash Age Check -----------------------------------
if ($stashCount -gt 0) {
    $stashDated = @(git stash list --format="%gd|%ci" 2>$null)
    $today = Get-Date
    foreach ($entry in $stashDated) {
        $parts = $entry -split '\|', 2
        if ($parts.Count -eq 2) {
            $ref = $parts[0].Trim()
            try {
                $stashDate = [datetime]::Parse($parts[1].Trim())
                $ageDays = [int]($today - $stashDate).TotalDays
                if ($ageDays -gt 14) {
                    Write-Host "    $ref : ${ageDays}d old - EXPIRED (>14d)" -ForegroundColor Red
                    $wrNotes += "Stash $ref is ${ageDays} days old - expired per Staleness Expiry (>14d); promote to branch or drop"
                } elseif ($ageDays -gt 3) {
                    Write-Host "    $ref : ${ageDays}d old - STALE (>3d)" -ForegroundColor Yellow
                    $wrNotes += "Stash $ref is ${ageDays} days old - stale per Staleness Expiry (>3d); consider promoting to branch"
                }
            } catch {
                # Date parse failure - skip age check for this entry
            }
        }
    }
}

# Untracked/dirty count for Workspace Reality
$dirtyAndUntracked = $statusLines.Count
if ($dirtyAndUntracked -gt 0) {
    $wrNotes += "Dirty/untracked files: $dirtyAndUntracked item(s) - classify or clean"
}

# Non-merged branch count for Workspace Reality
if ($nonMerged.Count -gt 5) {
    $wrNotes += "Non-merged branches ($($nonMerged.Count)) exceed cap (5) - BLOCKED"
} elseif ($nonMerged.Count -gt 3) {
    $wrNotes += "Non-merged branches ($($nonMerged.Count)) above default cap (3) - classify each"
}

# -- 8d-branchage. Stale Local Branch Age Check ----------------
if ($nonMerged.Count -gt 0) {
    $branchRefs = @(git for-each-ref --format="%(refname:short)|%(upstream)|%(committerdate:iso)" refs/heads/ 2>$null)
    $today = Get-Date
    foreach ($line in $branchRefs) {
        $parts = $line -split '\|', 3
        if ($parts.Count -eq 3) {
            $bName = $parts[0].Trim()
            $bUpstream = $parts[1].Trim()
            $bDate = $parts[2].Trim()
            # Only check non-merged branches with no upstream
            if ($bUpstream -eq '' -and $nonMerged -contains $bName -and $bDate -ne '') {
                try {
                    $commitDate = [datetime]::Parse($bDate)
                    $ageDays = [int]($today - $commitDate).TotalDays
                    if ($ageDays -gt 30) {
                        Write-Host "    branch $bName : ${ageDays}d since last commit - EXPIRED (>30d, no upstream)" -ForegroundColor Red
                        $wrNotes += "Branch '$bName' last commit ${ageDays}d ago, no upstream - expired per Staleness Expiry (>30d)"
                    } elseif ($ageDays -gt 14) {
                        Write-Host "    branch $bName : ${ageDays}d since last commit - STALE (>14d, no upstream)" -ForegroundColor Yellow
                        $wrNotes += "Branch '$bName' last commit ${ageDays}d ago, no upstream - stale per Staleness Expiry (>14d)"
                    }
                } catch {
                    # Date parse failure - skip age check for this branch
                }
            }
        }
    }
}

# -- 8e. Workspace Reality Verdict ------------------------------
$wrBlocked = @($wrNotes | Where-Object { $_ -match 'BLOCKED' })
if ($wrBlocked.Count -gt 0) {
    $wrStatus = "BLOCKED"
} elseif ($wrNotes.Count -gt 0) {
    $wrStatus = "WARN"
} else {
    $wrStatus = "PASS"
}

foreach ($note in $wrNotes) { Write-Host "    -> $note" -ForegroundColor Yellow }
Write-Host ("  Workspace Reality: {0}" -f $wrStatus) -ForegroundColor $(if ($wrStatus -eq 'PASS') { 'Green' } elseif ($wrStatus -eq 'WARN') { 'Yellow' } else { 'Red' })

# -- 8f. Active Lane Verdict -----------------------------------
$alStatus = if ($hasTracked) { "DIRTY" } else { "CLEAN" }

# -- 9. Optional report file -----------------------------------
if ($WriteReport) {
    $statusDir = Join-Path $repoRoot (Join-Path $docsRoot "status")
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportPath = Join-Path $statusDir "END-SESSION-REPORT-$ts.md"

    if ($WhatIf) {
        Write-Host ""
        Write-Host "[WhatIf] Would write report to: $reportPath" -ForegroundColor Cyan
    } else {
        if (-not (Test-Path $statusDir)) {
            New-Item -ItemType Directory -Path $statusDir -Force | Out-Null
        }

        $trackedBlock = if ($hasTracked) {
            ($trackedChanges | ForEach-Object { "- ``$_``" }) -join "`n"
        } else { "None" }

        $untrackedBlock = if ($untrackedItems.Count -gt 0) {
            ($untrackedItems | ForEach-Object { "- ``$_``" }) -join "`n"
        } else { "None" }

        $branchBlock = if ($nonMerged.Count -gt 0) {
            ($nonMerged | ForEach-Object { "- ``$_``" }) -join "`n"
        } else { "None" }

        $reportLines = @()
        $reportLines += "# End-of-Session Report"
        $reportLines += ""
        $reportLines += "> Auto-generated by end-session.ps1"
        $reportLines += ""
        $reportLines += "| Field | Value |"
        $reportLines += "|-------|-------|"
        $reportLines += "| **Time** | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') |"
        $reportLines += "| **Branch** | ``$branch`` |"
        $reportLines += "| **HEAD** | ``$headSha`` |"
        $reportLines += "| **DOCS_ROOT** | ``$docsRoot`` |"
        $reportLines += ""
        $reportLines += "## Tracked Changes ($($trackedChanges.Count))"
        $reportLines += ""
        $reportLines += $trackedBlock
        $reportLines += ""
        $reportLines += "## Untracked Items ($($untrackedItems.Count))"
        $reportLines += ""
        $reportLines += $untrackedBlock
        $reportLines += ""
        $reportLines += "## Non-Merged Branches vs $baseRef ($($nonMerged.Count))"
        $reportLines += ""
        $reportLines += $branchBlock
        $reportLines += ""
        $reportLines += "## Remote Reality"
        $reportLines += ""
        $reportLines += "**Status:** $rrStatus"
        if ($rrNotes.Count -gt 0) {
            $reportLines += ""
            foreach ($note in $rrNotes) { $reportLines += "- $note" }
        }
        $reportLines += ""
        $reportLines += "## Workspace Reality"
        $reportLines += ""
        $reportLines += "**Status:** $wrStatus"
        $reportLines += ""
        $reportLines += "| Category | Count |"
        $reportLines += "|----------|-------|"
        $reportLines += "| Extra worktrees | $extraWorktrees |"
        $reportLines += "| Stashes | $stashCount |"
        $reportLines += "| Non-merged branches | $($nonMerged.Count) |"
        $reportLines += "| Dirty/untracked files | $dirtyAndUntracked |"
        if ($wrNotes.Count -gt 0) {
            $reportLines += ""
            foreach ($note in $wrNotes) { $reportLines += "- $note" }
        }
        $reportLines += ""
        $reportLines += "## Combined Verdict"
        $reportLines += ""
        $cfReady = if (-not $hasTracked -and ($rrStatus -eq 'PASS') -and ($wrStatus -eq 'PASS')) { "YES" } else { "NO" }
        $reportLines += "| Gate | Status |"
        $reportLines += "|------|--------|"
        $reportLines += "| Active Lane | $alStatus |"
        $reportLines += "| Remote Reality | $rrStatus |"
        $reportLines += "| Workspace Reality | $wrStatus |"
        $reportLines += "| **CLEAN FIELD READY** | **$cfReady** |"
        $reportLines += ""
        $reportLines += "## Suggested Next Steps"
        $reportLines += ""
        $reportLines += "- If tracked changes exist: commit or stash before closing the session."
        $reportLines += "- If non-merged branches exist: open PRs or delete after merge per repo policy."
        $reportLines += "- If untracked items exist: decide whether to add, .gitignore, or remove."
        $reportLines += "- If Remote Reality: WARN - repair mismatches or document as debt in NEXT.md/branches.md."
        $reportLines += "- If Remote Reality: BLOCKED - note 'Remote Reality: BLOCKED' in PAUSE.md with reason."

        $reportContent = $reportLines -join "`n"

        Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
        Write-Host ""
        Write-Host "Report written: $reportPath" -ForegroundColor Green
    }
}

# -- 10. Footer + exit -----------------------------------------

# -- 9b. Owner-only snapshot isolation check -------------------
$snapshotFound = @($snapshotArtifactCandidates | Where-Object { Test-Path $_ } | Select-Object -Unique)
$snapshotStatus = if ($snapshotFound.Count -gt 0) { "WARN(present)" } else { "PASS(absent)" }
if ($snapshotFound.Count -gt 0) {
    foreach ($path in $snapshotFound) {
        Write-Host "WARN: Owner-only snapshot artifact detected: $path" -ForegroundColor Yellow
    }
}

# -- Tool/Auth Fragility verdict --------------------------------
$taStatus = "PASS"
$taNotes = @()
if ($taGhStatus -ne "AVAILABLE") {
    $taNotes += "gh CLI: $taGhStatus"
}
if ($taFetchStatus -ne "AVAILABLE") {
    $taNotes += "git fetch: $taFetchStatus"
}
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

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

# Combined verdict: CLEAN FIELD READY requires all three gates
$cleanField = (-not $hasTracked) -and ($rrStatus -eq 'PASS') -and ($wrStatus -eq 'PASS')
$cleanCloseProofPath = $null
$cleanCloseProofWarning = $null

try {
    $cleanCloseProofPath = Resolve-CleanCloseProofPath -RepoRoot $repoRoot
    if ($WhatIf) {
        if ($cleanField) {
            Write-Host "[WhatIf] Would write clean-close proof to: $cleanCloseProofPath" -ForegroundColor Cyan
        } else {
            Write-Host "[WhatIf] Would remove clean-close proof from: $cleanCloseProofPath" -ForegroundColor Cyan
        }
    } elseif ($cleanField) {
        $proofData = @{
            schemaVersion   = $cleanCloseProofSchemaVersion
            writtenAtUtc    = (Get-Date).ToUniversalTime().ToString('o')
            repoName        = Split-Path $repoRoot -Leaf
            docsRoot        = $docsRoot
            branch          = $branch
            head            = $headSha
            cleanFieldReady = $true
            activeLane      = $alStatus
            remoteReality   = $rrStatus
            workspaceReality = $wrStatus
            toolAuth        = $taStatus
            kitVersion      = Get-KitVersionForProof -RepoRoot $repoRoot -DocsRoot $docsRoot
        }
        Write-CleanCloseProof -ProofPath $cleanCloseProofPath -ProofData $proofData
    } else {
        if (Test-Path $cleanCloseProofPath) {
            Remove-Item $cleanCloseProofPath -Force
        }
    }
} catch {
    $cleanCloseProofWarning = $_.Exception.Message
}

Write-Host ("  Active Lane      : {0}" -f $alStatus) -ForegroundColor $(if ($alStatus -eq 'CLEAN') { 'Green' } else { 'Red' })
Write-Host ("  Remote Reality   : {0}" -f $rrStatus) -ForegroundColor $(if ($rrStatus -eq 'PASS') { 'Green' } elseif ($rrStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
Write-Host ("  Workspace Reality: {0}" -f $wrStatus) -ForegroundColor $(if ($wrStatus -eq 'PASS') { 'Green' } elseif ($wrStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
Write-Host ("  Tool/Auth        : {0}" -f $taStatus) -ForegroundColor $(if ($taStatus -eq 'PASS') { 'Green' } elseif ($taStatus -eq 'WARN') { 'Yellow' } else { 'Red' })
Write-Host ("  Snapshot         : {0}" -f $snapshotStatus) -ForegroundColor $(if ($snapshotStatus -eq 'PASS(absent)') { 'Green' } elseif ($snapshotStatus -like 'WARN*') { 'Yellow' } else { 'Gray' })
if ($cleanCloseProofWarning) {
    Write-Host "  CleanCloseProof  : WARN" -ForegroundColor Yellow
    Write-Host "    -> Clean-close proof I/O warning: $cleanCloseProofWarning" -ForegroundColor Yellow
}
Write-Host ""

if ($cleanField) {
    Write-Host "CLEAN FIELD READY: YES" -ForegroundColor Green
    exit 0
} else {
    Write-Host "CLEAN FIELD READY: NO" -ForegroundColor Yellow
    Write-Host "END OF SESSION STATUS: FAILED" -ForegroundColor Yellow
    if ($hasTracked) {
        Write-Host "  -> Tracked changes exist. Commit to a branch (preferred) or stash for short-lived interruptions only." -ForegroundColor Red
    }
    if ($rrStatus -ne 'PASS') {
        Write-Host "  -> Remote Reality: $rrStatus - resolve notes above or record in PAUSE.md." -ForegroundColor Yellow
    }
    if ($wrStatus -ne 'PASS') {
        Write-Host "  -> Workspace Reality: $wrStatus - classify leftovers and resolve or park." -ForegroundColor Yellow
    }
    exit 1
}

} finally {
    Pop-Location
}
