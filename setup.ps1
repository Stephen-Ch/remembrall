# Remembrall repo setup script
# Run this ONCE after cloning the GitHub repo
# Usage: .\setup.ps1 -RepoPath "C:\Users\schur\workspaces\remembrall-2026"

param(
    [Parameter(Mandatory=$true)]
    [string]$RepoPath
)

$ScaffoldPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Copying scaffold into $RepoPath..." -ForegroundColor Cyan

# Copy all scaffold files into the cloned repo
$items = Get-ChildItem -Path $ScaffoldPath -Exclude "setup.ps1" -Force
foreach ($item in $items) {
    $dest = Join-Path $RepoPath $item.Name
    if ($item.PSIsContainer) {
        Copy-Item -Path $item.FullName -Destination $dest -Recurse -Force
    } else {
        Copy-Item -Path $item.FullName -Destination $dest -Force
    }
}

Write-Host "Adding vibe-kit as git subtree..." -ForegroundColor Cyan
$kitPath = "C:\Users\schur\workspaces\vibe-coding-kit"
Push-Location $RepoPath
git subtree add --prefix docs/vibe-coding $kitPath main --squash
Pop-Location

Write-Host "Making initial commit..." -ForegroundColor Cyan
Push-Location $RepoPath
git add -A
git commit -m "chore: initial repo scaffold (docs, decisions, test catalog, vibe-kit)"
Pop-Location

Write-Host ""
Write-Host "Done. Next step: git push origin main" -ForegroundColor Green
Write-Host "Then open in VS Code and confirm Copilot is active."
