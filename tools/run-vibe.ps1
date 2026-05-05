<#
.SYNOPSIS
  Universal runner for vibe-coding-kit tools. Path-independent.
.DESCRIPTION
  Discovers tool paths from its own location (tools/ folder) and invokes
  the requested tool, forwarding any additional arguments.
  Works regardless of current working directory or DOCS_ROOT nesting depth.

  Common tool flags are declared explicitly so PS 5.1 binds them correctly.
  Any unlisted flags can still be passed via -ToolArgs (escape hatch).
.PARAMETER Tool
  Which tool to run: start, session-start, session-start-kit, kit-update, end-session, sync-forgpt, doc-audit.
.PARAMETER WhatIf
  Print what would be executed without running it.
.PARAMETER WriteReport
  (end-session) Write a markdown status report.
.PARAMETER SkipFetch
  (end-session) Skip git fetch origin.
.PARAMETER SkipUpdate
  (session-start) Deprecated compatibility flag.
.PARAMETER SkipAudit
  (session-start) Skip Consumer doc-audit step.
.PARAMETER Force
  (session-start) Deprecated compatibility flag.
.PARAMETER Mode
  (doc-audit) Explicit mode: Kit or Consumer.
.PARAMETER StartSession
  (doc-audit) Print session-start snippets before audit.
.PARAMETER ToolArgs
  Escape-hatch: extra arguments forwarded verbatim to the underlying tool.
.EXAMPLE
  .\run-vibe.ps1 -Tool start
  Runs unified startup flow: session-start, conditional kit-update,
  conditional sync-forgpt, then final READY/BLOCKED status.
 .EXAMPLE
  .\run-vibe.ps1 -Tool session-start
  .\run-vibe.ps1 -Tool session-start-kit
  .\run-vibe.ps1 -Tool kit-update
  .\run-vibe.ps1 -Tool end-session -WriteReport
  .\run-vibe.ps1 -Tool doc-audit -Mode Consumer -StartSession
  .\run-vibe.ps1 -Tool sync-forgpt -WhatIf
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
  [ValidateSet("start", "session-start", "session-start-kit", "kit-update", "end-session", "sync-forgpt", "doc-audit")]
    [string]$Tool,

    [switch]$WhatIf,

    # end-session flags
    [switch]$WriteReport,
    [switch]$SkipFetch,

    # session-start flags
    [switch]$SkipUpdate,
    [switch]$SkipAudit,
    [switch]$Force,

    # doc-audit flags
    [string]$Mode,
    [switch]$StartSession,

    # escape hatch
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ToolArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-ToolAndCapture {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ScriptPath,
    [hashtable]$NamedArgs,
    [string[]]$PositionalArgs,
    [string]$Label
  )

  $lines = @()
  if (-not $NamedArgs) { $NamedArgs = @{} }
  if (-not $PositionalArgs) { $PositionalArgs = @() }

  if ($Label) {
    Write-Host ""
    Write-Host "=== $Label ===" -ForegroundColor Cyan
  }

  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = @()
  try {
    if ($PositionalArgs.Count -gt 0) {
      $output = & $ScriptPath @NamedArgs @PositionalArgs *>&1
    } else {
      $output = & $ScriptPath @NamedArgs *>&1
    }
  } catch {
    $output += $_
    if (-not $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
      $global:LASTEXITCODE = 1
    }
  } finally {
    $ErrorActionPreference = $prevEap
  }
  $exitCode = $LASTEXITCODE

  foreach ($item in $output) {
    $line = "$item"
    $lines += $line
    Write-Host $line
  }

  return [pscustomobject]@{
    ExitCode = $exitCode
    Lines    = $lines
  }
}

function Parse-SessionStartSummary {
  [CmdletBinding()]
  param([string[]]$Lines)

  $state = [ordered]@{
    Tree           = "UNKNOWN"
    KitLag         = "UNKNOWN"
    ConsumerDrift  = "UNKNOWN"
    PacketStatus   = "UNKNOWN"
    StalenessExpiry = "UNKNOWN"
    DecisionQueue  = "UNKNOWN"
    ToolAuth       = "UNKNOWN"
    BlockedReasons = @()
  }

  foreach ($raw in $Lines) {
    $line = $raw.Trim()

    if ($line -match 'RepoRoot=.*\|\s*Branch=.*\|\s*Tree=([A-Z]+)') {
      $state.Tree = $Matches[1]
      continue
    }
    if ($line -match 'KitVersion=.*\|\s*Effective=.*\|\s*KitLag=([^|]+)\|') {
      $state.KitLag = $Matches[1].Trim()
      continue
    }
    if ($line -match '^ConsumerDrift=([A-Z]+)') {
      $state.ConsumerDrift = $Matches[1]
      if ($Matches[1] -eq 'BLOCKED') { $state.BlockedReasons += 'ConsumerDrift' }
      continue
    }
    if ($line -match '^PacketStatus=([A-Z]+)') {
      $state.PacketStatus = $Matches[1]
      continue
    }
    if ($line -match '^StalenessExpiry=([A-Z]+)') {
      $state.StalenessExpiry = $Matches[1]
      if ($Matches[1] -eq 'BLOCKED') { $state.BlockedReasons += 'StalenessExpiry' }
      continue
    }
    if ($line -match '^DecisionQueue=([A-Z]+)') {
      $state.DecisionQueue = $Matches[1]
      if ($Matches[1] -eq 'BLOCKED') { $state.BlockedReasons += 'DecisionQueue' }
      continue
    }
    if ($line -match '^ToolAuth=([A-Z]+)') {
      $state.ToolAuth = $Matches[1]
      if ($Matches[1] -eq 'BLOCKED') { $state.BlockedReasons += 'ToolAuth' }
      continue
    }
  }

  $state.BlockedReasons = @($state.BlockedReasons | Select-Object -Unique)
  return [pscustomobject]$state
}

function Get-RepoRootPath {
  [CmdletBinding()]
  param()

  try {
    $root = (git rev-parse --show-toplevel 2>$null | Select-Object -First 1)
    if ($null -ne $root) {
      $trimmed = $root.Trim()
      if ($trimmed) {
        return ($trimmed -replace '/', '\\')
      }
    }
  } catch {
    # fall through
  }

  return $null
}

function Invoke-NativeCommandNoThrow {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][scriptblock]$Command
  )

  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = @()
  $exitCode = 0

  try {
    $output = & $Command 2>&1
    $exitCode = $LASTEXITCODE
  } catch {
    $output += $_
    if (-not $LASTEXITCODE -or $LASTEXITCODE -eq 0) {
      $exitCode = 1
    } else {
      $exitCode = $LASTEXITCODE
    }
  } finally {
    $ErrorActionPreference = $prevEap
  }

  return [pscustomobject]@{
    Output   = @($output)
    ExitCode = $exitCode
  }
}

# -- Resolve paths from script location -------------------------
$kitHead = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$docsRootDisplay = "(kit source repo)"

if ((Split-Path $kitHead -Leaf) -eq "vibe-coding") {
    $docsRootFull = (Resolve-Path (Join-Path $kitHead "..")).Path
    try {
    $repoRoot = Get-RepoRootPath
    $repoRootNorm = $repoRoot -replace '/', '\\'
        $docsRootNorm = $docsRootFull -replace '/', '\'
        if ($docsRootNorm.Length -gt $repoRootNorm.Length -and $docsRootNorm.StartsWith($repoRootNorm)) {
            $docsRootDisplay = ($docsRootNorm.Substring($repoRootNorm.Length).TrimStart('\')) -replace '\\', '/'
        } elseif ($docsRootNorm -eq $repoRootNorm) {
            $docsRootDisplay = "."
        }
    } catch { }
}

# -- Map tool name to script ------------------------------------
$toolScript = Join-Path $PSScriptRoot "$Tool.ps1"
if ($Tool -ne 'start' -and -not (Test-Path $toolScript)) {
    Write-Error "HARD STOP: Tool script not found: $toolScript"
    exit 1
}

# -- Build forwarding args (hashtable for named, array for positional) --
if (-not $ToolArgs) { $ToolArgs = @() }
$named = @{}

# Switches relevant to each tool
if ($WhatIf)       { $named["WhatIf"]       = $true }
if ($WriteReport)  { $named["WriteReport"]  = $true }
if ($SkipFetch)    { $named["SkipFetch"]    = $true }
if ($SkipUpdate)   { $named["SkipUpdate"]   = $true }
if ($SkipAudit)    { $named["SkipAudit"]    = $true }
if ($Force)        { $named["Force"]        = $true }
if ($StartSession) { $named["StartSession"] = $true }
if ($Mode)         { $named["Mode"]         = $Mode }

# Positional escape-hatch args
$positional = @($ToolArgs)

# -- Build display string for WhatIf ----------------------------
$displayParts = @()
foreach ($key in $named.Keys) {
    $val = $named[$key]
    if ($val -is [bool]) {
        $displayParts += "-$key"
    } else {
        $displayParts += "-$key $val"
    }
}
if ($positional.Count -gt 0) { $displayParts += $positional }
$displayStr = $displayParts -join ' '

# -- Unified start flow -----------------------------------------
if ($Tool -eq 'start') {
  $steps = [System.Collections.Generic.List[string]]::new()
  $sessionStartScript = Join-Path $PSScriptRoot "session-start.ps1"
  $kitUpdateScript = Join-Path $PSScriptRoot "kit-update.ps1"
  $syncScript = Join-Path $PSScriptRoot "sync-forgpt.ps1"
  $sessionStartNamed = @{}

  if ($SkipAudit) {
    $sessionStartNamed["SkipAudit"] = $true
  }
  if ($SkipUpdate) {
    $sessionStartNamed["SkipUpdate"] = $true
  }
  if ($Force) {
    $sessionStartNamed["Force"] = $true
  }

  foreach ($scriptPath in @($sessionStartScript, $kitUpdateScript, $syncScript)) {
    if (-not (Test-Path $scriptPath)) {
      Write-Error "HARD STOP: Required tool script not found: $scriptPath"
      exit 1
    }
  }

  if ($WhatIf) {
    Write-Host ""
    Write-Host "========== RUN-VIBE START (WhatIf) ==========" -ForegroundColor Cyan
    Write-Host "DOCS_ROOT  = $docsRootDisplay"
    Write-Host "KitHead    = $kitHead"
    Write-Host "Plan:" -ForegroundColor Yellow
    Write-Host "  1. Run session-start"
    Write-Host "  2. If KitLag is WARN(lag), run kit-update"
    Write-Host "  3. If PacketStatus is STALE and Tree is CLEAN, run sync-forgpt"
    Write-Host "  3b. If sync ran: classify dirty files; auto-commit forGPT-only; STOP on any canonical dirty"
    Write-Host "  4. Re-run session-start"
    Write-Host "  5. Print READY/BLOCKED and Safe to proceed"
    Write-Host "=============================================" -ForegroundColor Cyan
    exit 0
  }

  $initial = Invoke-ToolAndCapture -ScriptPath $sessionStartScript -NamedArgs $sessionStartNamed -Label "Step 1 - session-start"
  $steps.Add("session-start")
  if ($initial.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "FinalState=BLOCKED" -ForegroundColor Red
    Write-Host "Reason=session-start failed (exit $($initial.ExitCode))" -ForegroundColor Red
    Write-Host "SafeToProceed=NO" -ForegroundColor Red
    exit $initial.ExitCode
  }

  $state1 = Parse-SessionStartSummary -Lines $initial.Lines

  if ($state1.ConsumerDrift -eq 'BLOCKED') {
    Write-Host ""
    Write-Host "ConsumerDrift is BLOCKED after initial session-start. Stopping before update/sync." -ForegroundColor Red
    Write-Host "FinalState=BLOCKED" -ForegroundColor Red
    Write-Host "Reason=ConsumerDrift BLOCKED" -ForegroundColor Red
    Write-Host "SafeToProceed=NO" -ForegroundColor Red
    exit 1
  }

  if ($state1.KitLag -eq 'WARN(lag)') {
    $update = Invoke-ToolAndCapture -ScriptPath $kitUpdateScript -Label "Step 2 - kit-update"
    $steps.Add("kit-update")
    if ($update.ExitCode -ne 0) {
      Write-Host ""
      Write-Host "FinalState=BLOCKED" -ForegroundColor Red
      Write-Host "Reason=kit-update failed (exit $($update.ExitCode))" -ForegroundColor Red
      Write-Host "SafeToProceed=NO" -ForegroundColor Red
      exit $update.ExitCode
    }
  } else {
    $steps.Add("kit-update skipped (KitLag=$($state1.KitLag))")
  }

  if (($state1.PacketStatus -eq 'STALE' -or $state1.PacketStatus -eq 'MISSING') -and $state1.Tree -eq 'CLEAN') {
    $sync = Invoke-ToolAndCapture -ScriptPath $syncScript -Label "Step 3 - sync-forgpt"
    $steps.Add("sync-forgpt")
    if ($sync.ExitCode -ne 0) {
      Write-Host ""
      Write-Host "FinalState=BLOCKED" -ForegroundColor Red
      Write-Host "Reason=sync-forgpt failed (exit $($sync.ExitCode))" -ForegroundColor Red
      Write-Host "SafeToProceed=NO" -ForegroundColor Red
      exit $sync.ExitCode
    }

    # -- 3b. Auto-commit generated forGPT packet files after sync --------
    # Safety: classify every dirty tracked file. Any non-forGPT dirty file
    # means a canonical doc was touched unexpectedly — STOP immediately.
    # Only forGPT-generated files are auto-committed.
    $repoRootForStep3b = Get-RepoRootPath
    if (-not $repoRootForStep3b) {
      Write-Host ""
      Write-Host "HARD STOP: Unable to resolve repo root for Step 3b auto-commit." -ForegroundColor Red
      Write-Host "FinalState=BLOCKED" -ForegroundColor Red
      Write-Host "Reason=Unable to resolve repo root for forGPT auto-commit" -ForegroundColor Red
      Write-Host "SafeToProceed=NO" -ForegroundColor Red
      exit 1
    }

    $invocationCwd = (Get-Location).Path
    Push-Location $repoRootForStep3b
    try {
      $dirtyAfterSync = @(git status --porcelain 2>$null | Where-Object { $_ -and $_ -notmatch '^\?\?' })
    if ($dirtyAfterSync.Count -gt 0) {
      $forGptDirty   = @()
      $canonicalDirty = @()
      foreach ($line in $dirtyAfterSync) {
        $filePath = $line.Substring(3).Trim()
        if ($filePath -match ' -> (.+)$') { $filePath = $Matches[1] }
        $filePath = $filePath -replace '\\', '/'
        if ($filePath -match '[/\\]forGPT[/\\]' -or $filePath -match '^forGPT[/\\]') {
          $forGptDirty += [pscustomobject]@{
            OriginalStatusPath = $line.Substring(3).Trim()
            RepoRelativePath   = $filePath
          }
        } else {
          $canonicalDirty += $filePath
        }
      }

      if ($canonicalDirty.Count -gt 0) {
        Write-Host ""
        Write-Host "HARD STOP: Canonical files are dirty after sync-forgpt. Auto-commit aborted." -ForegroundColor Red
        foreach ($f in $canonicalDirty) { Write-Host "  dirty: $f" -ForegroundColor Red }
        Write-Host "FinalState=BLOCKED" -ForegroundColor Red
        Write-Host "Reason=Canonical files dirty after sync - manual review required" -ForegroundColor Red
        Write-Host "SafeToProceed=NO" -ForegroundColor Red
        exit 1
      }

      if ($forGptDirty.Count -gt 0) {
        Write-Host ""
        Write-Host "=== Step 3b - auto-commit forGPT packet ===" -ForegroundColor Cyan
        $rollbackPaths = @($forGptDirty | ForEach-Object { $_.RepoRelativePath } | Select-Object -Unique)
        foreach ($entry in $forGptDirty) {
          $pathAttempted = $entry.RepoRelativePath
          $absolutePath = Join-Path $repoRootForStep3b ($pathAttempted -replace '/', '\\')

          if (-not (Test-Path -LiteralPath $absolutePath)) {
            Write-Host "HARD STOP: forGPT auto-commit path assertion failed." -ForegroundColor Red
            Write-Host "  RepoRoot: $repoRootForStep3b" -ForegroundColor Red
            Write-Host "  CurrentDirectory: $((Get-Location).Path)" -ForegroundColor Red
            Write-Host "  InvocationDirectory: $invocationCwd" -ForegroundColor Red
            Write-Host "  PathAttempted: $pathAttempted" -ForegroundColor Red
            Write-Host "  OriginalStatusPath: $($entry.OriginalStatusPath)" -ForegroundColor Red
            Write-Host "FinalState=BLOCKED" -ForegroundColor Red
            Write-Host "Reason=forGPT auto-commit path assertion failed" -ForegroundColor Red
            Write-Host "SafeToProceed=NO" -ForegroundColor Red
            exit 1
          }

          $gitAdd = Invoke-NativeCommandNoThrow -Command { git add -- $pathAttempted }
          if ($gitAdd.ExitCode -ne 0) {
            if ($rollbackPaths.Count -gt 0) {
              $restoreResult = Invoke-NativeCommandNoThrow -Command { git restore --staged -- @rollbackPaths }
              if ($restoreResult.ExitCode -ne 0) {
                $null = Invoke-NativeCommandNoThrow -Command { git reset -q HEAD -- @rollbackPaths }
              }
            }
            Write-Host "HARD STOP: git add failed for forGPT auto-commit path." -ForegroundColor Red
            Write-Host "  RepoRoot: $repoRootForStep3b" -ForegroundColor Red
            Write-Host "  CurrentDirectory: $((Get-Location).Path)" -ForegroundColor Red
            Write-Host "  InvocationDirectory: $invocationCwd" -ForegroundColor Red
            Write-Host "  PathAttempted: $pathAttempted" -ForegroundColor Red
            Write-Host "  OriginalStatusPath: $($entry.OriginalStatusPath)" -ForegroundColor Red
            foreach ($line in $gitAdd.Output) {
              if ($line) { Write-Host "  git add: $line" -ForegroundColor Red }
            }
            Write-Host "FinalState=BLOCKED" -ForegroundColor Red
            Write-Host "Reason=forGPT auto-commit git add failed" -ForegroundColor Red
            Write-Host "SafeToProceed=NO" -ForegroundColor Red
            exit 1
          }
        }
        $gitCommit = Invoke-NativeCommandNoThrow -Command { git commit -m 'docs: refresh forGPT packet' }
        if ($gitCommit.ExitCode -ne 0) {
          Write-Host "HARD STOP: Auto-commit of forGPT packet failed (exit $($gitCommit.ExitCode))" -ForegroundColor Red
          foreach ($line in $gitCommit.Output) {
            if ($line) { Write-Host "  git commit: $line" -ForegroundColor Red }
          }
          Write-Host "FinalState=BLOCKED" -ForegroundColor Red
          Write-Host "Reason=forGPT auto-commit failed" -ForegroundColor Red
          Write-Host "SafeToProceed=NO" -ForegroundColor Red
          exit 1
        }
        Write-Host "Auto-committed $($forGptDirty.Count) forGPT packet file(s)" -ForegroundColor Green
        $steps.Add("forGPT auto-commit ($($forGptDirty.Count) file(s))")
      }
    }
    } finally {
      Pop-Location
    }
  } elseif ($state1.PacketStatus -eq 'STALE') {
    $steps.Add("sync-forgpt skipped (tree not clean)")
  } else {
    $steps.Add("sync-forgpt skipped (PacketStatus=$($state1.PacketStatus))")
  }

  $final = Invoke-ToolAndCapture -ScriptPath $sessionStartScript -NamedArgs $sessionStartNamed -Label "Step 4 - session-start (re-run)"
  $steps.Add("session-start (re-run)")
  if ($final.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "FinalState=BLOCKED" -ForegroundColor Red
    Write-Host "Reason=session-start re-run failed (exit $($final.ExitCode))" -ForegroundColor Red
    Write-Host "SafeToProceed=NO" -ForegroundColor Red
    exit $final.ExitCode
  }

  $state2 = Parse-SessionStartSummary -Lines $final.Lines
  $isBlocked = $state2.BlockedReasons.Count -gt 0

  Write-Host ""
  Write-Host "========== RUN-VIBE START RESULT ==========" -ForegroundColor Cyan
  Write-Host "StepsExecuted:" -ForegroundColor Yellow
  for ($i = 0; $i -lt $steps.Count; $i++) {
    Write-Host ("  {0}. {1}" -f ($i + 1), $steps[$i])
  }
  Write-Host ""
  Write-Host "FinalGateSummary:" -ForegroundColor Yellow
  Write-Host "  ConsumerDrift=$($state2.ConsumerDrift)"
  Write-Host "  PacketStatus=$($state2.PacketStatus)"
  Write-Host "  StalenessExpiry=$($state2.StalenessExpiry)"
  Write-Host "  DecisionQueue=$($state2.DecisionQueue)"
  Write-Host "  ToolAuth=$($state2.ToolAuth)"

  if ($isBlocked) {
    Write-Host ("FinalState=BLOCKED ({0})" -f ($state2.BlockedReasons -join ', ')) -ForegroundColor Red
    Write-Host "SafeToProceed=NO" -ForegroundColor Red
    Write-Host "===========================================" -ForegroundColor Cyan
    exit 1
  }

  Write-Host "FinalState=READY" -ForegroundColor Green
  Write-Host "SafeToProceed=YES" -ForegroundColor Green
  Write-Host "===========================================" -ForegroundColor Cyan
  exit 0
}

# -- WhatIf: print and exit ------------------------------------
if ($WhatIf) {
    Write-Host ""
    Write-Host "========== RUN-VIBE (WhatIf) ==========" -ForegroundColor Cyan
    Write-Host "DOCS_ROOT  = $docsRootDisplay"
    Write-Host "KitHead    = $kitHead"
    Write-Host "Tool       = $Tool"
    Write-Host "ToolScript = $toolScript"
    if ($displayStr) {
        Write-Host "ForwardArgs = $displayStr"
    }
    Write-Host ""
    Write-Host "[WhatIf] Would run: & `"$toolScript`" $displayStr" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    exit 0
}

# -- Execute the tool (hashtable splat + positional splat) ------
Write-Host "run-vibe: invoking $Tool..." -ForegroundColor Yellow
if ($positional.Count -gt 0) {
    & $toolScript @named @positional
} else {
    & $toolScript @named
}
exit $LASTEXITCODE
