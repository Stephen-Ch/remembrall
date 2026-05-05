<#
.SYNOPSIS
    Docs Health Audit — dual-mode (Kit / Consumer) with auto-detect.
.DESCRIPTION
    Runs documentation health checks against DOCS-HEALTH-CONTRACT.md.
    Auto-detects whether this is the vibe-coding-kit source repo (Kit mode)
    or a consumer/arm repo (Consumer mode). Use -Mode to override.
.PARAMETER Mode
    Explicit mode override: Kit or Consumer. When omitted, auto-detect runs.
.PARAMETER StartSession
    Print session-start snippets extracted from README.md before running the audit.
.EXAMPLE
    .\doc-audit.ps1                  # auto-detect mode
    .\doc-audit.ps1 -Mode Kit        # force Kit mode
    .\doc-audit.ps1 -Mode Consumer   # force Consumer mode
    .\doc-audit.ps1 -StartSession    # print snippets then audit
#>
[CmdletBinding()]
param(
    [ValidateSet("Kit", "Consumer")]
    [string]$Mode,

    [switch]$StartSession
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message"
    exit 1
}

function Pass {
    param([string]$Message)
    Write-Host "PASS: $Message"
}

function Get-AuditMode {
    param([string]$RepoRoot)

    $kitSignals = @()
    $consumerSignals = @()

    # KIT signal A: origin remote URL matches vibe-coding-kit
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl -match "github\.com[/:]Stephen-Ch/vibe-coding-kit") {
        $kitSignals += "origin remote matches Stephen-Ch/vibe-coding-kit"
    }

    # KIT signal B: kit-only files at repo root
    if (Test-Path (Join-Path $RepoRoot "portability/subtree-playbook.md")) {
        $kitSignals += "portability/subtree-playbook.md exists (kit-only)"
    }
    if (Test-Path (Join-Path $RepoRoot "MIGRATION-INSTRUCTIONS.md")) {
        $kitSignals += "MIGRATION-INSTRUCTIONS.md exists (kit-only)"
    }
    $versionFile = Get-ChildItem -Path $RepoRoot -Filter "VIBE-CODING-KIT-VERSION-*.txt" -ErrorAction SilentlyContinue
    if ($versionFile) {
        $kitSignals += "VIBE-CODING-KIT-VERSION-*.txt exists (kit-only)"
    }

    # CONSUMER signal C: vibe-coding subtree folder present
    if ((Test-Path (Join-Path $RepoRoot "docs-engineering/vibe-coding")) -or
        (Test-Path (Join-Path $RepoRoot "docs/vibe-coding"))) {
        $consumerSignals += "vibe-coding subtree folder found"
    }

    # CONSUMER signal D: Control Deck files present
    $cdPaths = @(
        "docs/project/VISION.md", "docs/project/EPICS.md", "docs/project/NEXT.md",
        "docs-engineering/project/VISION.md", "docs-engineering/project/EPICS.md", "docs-engineering/project/NEXT.md"
    )
    $cdFound = @($cdPaths | Where-Object { Test-Path (Join-Path $RepoRoot $_) })
    if ($cdFound.Count -gt 0) {
        $consumerSignals += "Control Deck files found ($($cdFound.Count) files)"
    }

    # Decision
    if ($kitSignals.Count -ge 2 -and $consumerSignals.Count -eq 0) {
        return @{ Mode = "Kit"; Confidence = "HIGH"; Reasons = $kitSignals }
    } elseif ($consumerSignals.Count -ge 2) {
        return @{ Mode = "Consumer"; Confidence = "HIGH"; Reasons = $consumerSignals }
    } else {
        $allReasons = @($kitSignals) + @($consumerSignals)
        if ($kitSignals.Count -ge 2) {
            return @{ Mode = "Kit"; Confidence = "LOW"; Reasons = $allReasons + @("Mixed signals: kit files + consumer artifacts both present") }
        } elseif ($consumerSignals.Count -eq 1) {
            return @{ Mode = "Consumer"; Confidence = "LOW"; Reasons = $allReasons + @("Only 1 consumer signal detected") }
        } else {
            return @{ Mode = "Unknown"; Confidence = "LOW"; Reasons = $allReasons + @("Insufficient signals to determine mode") }
        }
    }
}

# Anchor to repo root
$repoRoot = git rev-parse --show-toplevel
Set-Location $repoRoot

Write-Host "Repo Root: $repoRoot"
$prefix = git rev-parse --show-prefix
if (-not [string]::IsNullOrWhiteSpace($prefix)) {
    Write-Host "Current Prefix: $prefix"
}

# Detect DOCS_ROOT — prefer script-relative, fall back to repo-root detection
# Script-relative: tools/ -> vibe-coding/ (kit head) -> DOCS_ROOT
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

# Fallback: repo-root detection (Kit source repo or unusual layout)
if (-not $docsRoot) {
    $deDir = Join-Path $repoRoot "docs-engineering"
    $docsDir = Join-Path $repoRoot "docs"
    if ((Test-Path $deDir) -and ((Test-Path (Join-Path $deDir "vibe-coding")) -or (Test-Path (Join-Path $deDir "forGPT")))) {
        $docsRoot = "docs-engineering"
    } elseif (Test-Path $docsDir) {
        $docsRoot = "docs"
    } else {
        $docsRoot = "docs"  # fallback for config-path compatibility
    }
}

Write-Host "DOCS_ROOT: $docsRoot"

# -- Mode resolution ------------------------------------------
if ($Mode) {
    $auditMode = $Mode
    $modeConfidence = "EXPLICIT"
    $modeReasons = @("User specified -Mode $Mode")
} else {
    $detected = Get-AuditMode -RepoRoot $repoRoot
    $auditMode = $detected.Mode
    $modeConfidence = $detected.Confidence
    $modeReasons = $detected.Reasons

    if ($modeConfidence -eq "LOW") {
        Write-Host ""
        Write-Host "Audit Mode: $auditMode" -ForegroundColor Red
        Write-Host "Mode Confidence: LOW" -ForegroundColor Red
        Write-Host "Mode Reasons:" -ForegroundColor Red
        foreach ($r in $modeReasons) { Write-Host "  - $r" -ForegroundColor Red }
        Write-Host ""
        Write-Host "HARD STOP: Auto-detect confidence is LOW. Rerun with -Mode Kit or -Mode Consumer." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Audit Mode: $auditMode"
Write-Host "Mode Confidence: $modeConfidence"
Write-Host "Mode Reasons:"
foreach ($r in $modeReasons) { Write-Host "  - $r" }
Write-Host ""

# Load config (with defaults)
$configPath = Join-Path $repoRoot "$docsRoot/vibe-coding.config.json"
$defaultConfig = [pscustomobject]@{
    controlDeck     = [pscustomobject]@{
        visionPath = "docs/project/VISION.md"
        epicsPath  = "docs/project/EPICS.md"
        nextPath   = "docs/project/NEXT.md"
    }
    testCatalogPath = "docs/testing/test-catalog.md"
    # Word boundaries (\b) prevent matching "templates" when looking for "TEMPLATE"
    placeholderRegex = "(\bTBD\b|\bTODO\b|\bTEMPLATE\b|\bPLACEHOLDER\b|FILL IN|COMING SOON|\bXXX\b|\bFIXME\b|TO BE DETERMINED|<fill)"
    nextFreshness = [pscustomobject]@{
        mode = "codeChangesOnly"
        docOnlyPrefixes = @("docs/")
        requireOnPullRequest = $true
        requireOnPush = $false
    }
}

$config = $defaultConfig
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    } catch {
        Fail "Could not parse config at ${configPath}: $($_.Exception.Message)"
    }
}

$visionPath = $config.controlDeck.visionPath
$epicsPath  = $config.controlDeck.epicsPath
$nextPath   = $config.controlDeck.nextPath
$testCatalogPath = $config.testCatalogPath
$placeholderRegex = $config.placeholderRegex
$docOnlyPrefixes = $config.nextFreshness.docOnlyPrefixes
$requireOnPullRequest = [bool]$config.nextFreshness.requireOnPullRequest
$requireOnPush = [bool]$config.nextFreshness.requireOnPush
$nextMode = $config.nextFreshness.mode

# PRE) Overlays-outside-head check (Octopus Invariant 2)
# See OCTOPUS-INVARIANTS.md — overlays MUST NOT live inside the kit head.
$overlaysInsideHead = Join-Path $repoRoot "$docsRoot/vibe-coding/overlays"
if (Test-Path $overlaysInsideHead) {
    Fail "Overlays detected inside kit head ($docsRoot/vibe-coding/overlays/). Move to $docsRoot/overlays/ and re-run. See OCTOPUS-INVARIANTS.md."
} else {
    Pass "Overlays-outside-head: no overlays inside kit head"
}

# PRE-B) Overlay index existence check (Consumer only)
if ($auditMode -eq "Consumer") {
    $overlayIndexPath = Join-Path $repoRoot "$docsRoot/overlays/OVERLAY-INDEX.md"
    if (-not (Test-Path $overlayIndexPath)) {
        Write-Host "WARNING: Overlay index missing at $docsRoot/overlays/OVERLAY-INDEX.md. Create it per OCTOPUS-INVARIANTS.md." -ForegroundColor Yellow
    } else {
        Pass "Overlay index exists at $docsRoot/overlays/OVERLAY-INDEX.md"
    }
} else {
    Pass "Overlay index: skipped ($auditMode mode)"
}

# PRE-C) kit-workspace/ reference check (Consumer only)
# kit-workspace/ ships via subtree but is kit-internal planning; consumers should not reference it.
if ($auditMode -eq "Consumer") {
    $kwRefs = Get-ChildItem -Path $repoRoot -Recurse -Include *.md -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike "*vibe-coding*kit-workspace*" } |
        Select-String -Pattern 'kit-workspace/' -CaseSensitive:$false -ErrorAction SilentlyContinue
    if ($kwRefs) {
        Write-Host "WARNING: Consumer docs reference kit-workspace/ (kit-internal). These files are not intended for consumer use:" -ForegroundColor Yellow
        $kwRefs | ForEach-Object { Write-Host "  $($_.Filename):$($_.LineNumber)" -ForegroundColor Yellow }
    } else {
        Pass "kit-workspace refs: no consumer-side references detected"
    }
} else {
    Pass "kit-workspace refs: skipped ($auditMode mode)"
}

# A) Required files (Consumer only)
if ($auditMode -eq "Consumer") {
    $missing = @()
    foreach ($p in @($visionPath, $epicsPath, $nextPath, $testCatalogPath)) {
        if (-not (Test-Path (Join-Path $repoRoot $p))) {
            $missing += $p
        }
    }
    if ($missing.Count -gt 0) {
        Fail "Required files missing: $($missing -join ', ')"
    } else {
        Pass "Required files present"
        # Print canonical paths explicitly as proof
        Write-Host "Checked: $visionPath"
        Write-Host "Checked: $epicsPath"
        Write-Host "Checked: $nextPath"
        Write-Host "Checked: $testCatalogPath"
    }
} else {
    Pass "Required files: skipped ($auditMode mode)"
}

# B) Population Gate (Consumer only — Control Deck)
if ($auditMode -eq "Consumer") {
    # Run git at repo root using -C
    $grepArgs = @("-C", $repoRoot, "grep", "-n", "-i", "-E", $placeholderRegex, "--", $visionPath, $epicsPath, $nextPath)
    & git @grepArgs | Out-String -OutVariable grepOutput | Out-Null
    $grepCode = $LASTEXITCODE
    if ($grepCode -eq 0) {
        Fail "Population Gate found placeholders:\n$grepOutput"
    } elseif ($grepCode -eq 1) {
        Pass "Population Gate: no placeholders in Control Deck"
    } else {
        Fail "Population Gate scan error (exit $grepCode)."
    }
} else {
    Pass "Population Gate: skipped ($auditMode mode)"
}

# C) NEXT freshness (Consumer only — low-noise v1)
if ($auditMode -ne "Consumer") {
    Pass "NEXT freshness: skipped ($auditMode mode)"
} else {
$inPrContext = ($env:GITHUB_EVENT_NAME -eq "pull_request") -or ([string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF) -eq $false)
if ($requireOnPullRequest -and $inPrContext) {
    if ($nextMode -ne "codeChangesOnly") {
        Fail "Unsupported nextFreshness.mode '$nextMode'"
    }
-C $repoRoot fetch --no-tags origin +refs/heads/*:refs/remotes/origin/* | Out-Null
    $mergeBase = git -C $repoRoot merge-base "origin/$baseRef" HEAD
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mergeBase)) {
        Fail "NEXT freshness: could not compute merge-base with origin/$baseRef"
    }

    $diffPaths = git -C $repoRootags origin +refs/heads/*:refs/remotes/origin/* | Out-Null
    $mergeBase = git merge-base "origin/$baseRef" HEAD
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mergeBase)) {
        Fail "NEXT freshness: could not compute merge-base with origin/$baseRef"
    }

    $diffPaths = git diff --name-only "$mergeBase"...HEAD
    $diffList = $diffPaths | Where-Object { $_ -ne "" }

    $isDocsOnly = $true
    foreach ($path in $diffList) {
        $prefixed = $false
        foreach ($prefix in $docOnlyPrefixes) {
            if ($path.StartsWith($prefix)) { $prefixed = $true; break }
        }
        if (-not $prefixed) { $isDocsOnly = $false; break }
    }

    if ($isDocsOnly) {
        Pass "NEXT freshness: docs-only PR detected; NEXT change not required"
    } else {
        $nextChanged = $diffList -contains $nextPath
        if ($nextChanged) {
            Pass "NEXT freshness: NEXT.md changed for code-affecting PR"
        } else {
            $joined = ($diffList -join ", ")
            Fail "NEXT freshness: code-affecting PR requires $nextPath in diff; changed: [$joined]"
        }
    }
} elseif ($requireOnPush -and ($env:GITHUB_EVENT_NAME -eq "push")) {
    $hasPrev = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -ne 0) {
        Fail "NEXT freshness: HEAD~1 not available to check push diff"
    }
    $pushDiff = git diff --name-only HEAD~1..HEAD
    if ($pushDiff -contains $nextPath) {
        Pass "NEXT freshness: NEXT.md changed on push"
    } else {
        Fail "NEXT freshness: push requires $nextPath in HEAD~1..HEAD"
    }
} else {
    Pass "NEXT freshness: skipped (context does not require)"
}
} # end Consumer-only NEXT freshness

# -- Session Start Snippets (optional) -------------------------
if ($StartSession) {
    # Locate README.md at repo root
    $readmePath = Join-Path $repoRoot "README.md"
    if (-not (Test-Path $readmePath)) {
        Write-Host "WARNING: README.md not found at $readmePath - cannot extract snippets." -ForegroundColor Yellow
    } else {
        $readmeContent = Get-Content $readmePath -Raw

        Write-Host ""
        Write-Host "===== SESSION START SNIPPETS =====" -ForegroundColor Cyan

        # Extract GPT snippet
        if ($readmeContent -match '(?s)<!-- STARTSESSION:GPT -->(.+?)<!-- ENDSESSION:GPT -->') {
            $gptSnippet = $Matches[1].Trim()
            Write-Host "--- GPT (paste into ChatGPT) ---" -ForegroundColor Yellow
            Write-Host $gptSnippet
        } else {
            Write-Host 'WARNING: STARTSESSION:GPT marker not found in README.md' -ForegroundColor Yellow
        }

        Write-Host ""

        # Extract Copilot snippet
        if ($readmeContent -match '(?s)<!-- STARTSESSION:COPILOT -->(.+?)<!-- ENDSESSION:COPILOT -->') {
            $copilotSnippet = $Matches[1].Trim()
            Write-Host "--- COPILOT (paste at top of every prompt) ---" -ForegroundColor Yellow
            Write-Host $copilotSnippet
        } else {
            Write-Host 'WARNING: STARTSESSION:COPILOT marker not found in README.md' -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""

        # Extract GPT Bootstrap upload list
        if ($readmeContent -match '(?s)<!-- GPTBOOTSTRAP:START -->(.+?)<!-- GPTBOOTSTRAP:END -->') {
            $bootstrapBlock = $Matches[1]
            $uploadPaths = @("README.md")  # Always first
            foreach ($line in ($bootstrapBlock -split "`n")) {
                if ($line -match '^\s*-\s*\[.*?\]\(([^)]+)\)') {
                    $linkPath = $Matches[1]
                    if ($uploadPaths -notcontains $linkPath) {
                        $uploadPaths += $linkPath
                    }
                }
            }

            Write-Host "===== FILES TO UPLOAD TO GPT =====" -ForegroundColor Cyan
            foreach ($p in $uploadPaths) {
                $fullPath = Join-Path $repoRoot $p
                if (-not (Test-Path $fullPath)) {
                    Write-Host "WARNING: $p not found" -ForegroundColor Yellow
                }
                Write-Host $p
            }
            Write-Host "==================================" -ForegroundColor Cyan
        } else {
            Write-Host "WARNING: GPTBOOTSTRAP markers not found in README.md" -ForegroundColor Yellow
        }

        Write-Host ""

        # --- Protocol Index Check (StartSession only) ---
        Write-Host "===== PROTOCOL INDEX CHECK =====" -ForegroundColor Cyan
        $indexScript = Join-Path $PSScriptRoot "verify-protocol-index.ps1"
        if (Test-Path $indexScript) {
            & $indexScript
            if ($LASTEXITCODE -ne 0) {
                Fail "Protocol index check FAILED"
                exit 1
            }
        } else {
            Write-Host "SKIP: verify-protocol-index.ps1 not found" -ForegroundColor Yellow
        }
        Write-Host "================================" -ForegroundColor Cyan
        Write-Host ""

        # --- Protocol v7 Budget Check (StartSession only) ---
        Write-Host "===== PROTOCOL V7 BUDGET CHECK =====" -ForegroundColor Cyan
        $budgetScript = Join-Path $PSScriptRoot "check-protocol-v7-budget.ps1"
        if (Test-Path $budgetScript) {
            & $budgetScript
            if ($LASTEXITCODE -ne 0) {
                Fail "Protocol v7 budget check FAILED"
                exit 1
            }
        } else {
            Write-Host "SKIP: check-protocol-v7-budget.ps1 not found" -ForegroundColor Yellow
        }
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host ""
    }
}

Pass "DOC-AUDIT ($auditMode mode): PASS"
exit 0
