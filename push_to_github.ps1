# push_to_github.ps1 - idempotent script to initialize repo and push to GitHub
# Usage: Open PowerShell in the project root and run: .\push_to_github.ps1

$repoUrl = "https://github.com/mainaksen1110-create/ms--one-to-chat-app.git"

Write-Host "Running push_to_github.ps1..." -ForegroundColor Cyan

# Ensure .gitignore has common entries
$ignores = @("node_modules/","backend/.env","frontend/.env",".env.local")
if (-not (Test-Path .gitignore)) { "" | Out-File .gitignore }
foreach ($i in $ignores) {
  if (-not (Select-String -Path .gitignore -Pattern ([regex]::Escape($i)) -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content -Path .gitignore -Value $i
    Write-Host "Added to .gitignore: $i"
  }
}

# Locate git executable
$gitExe = $null
try {
  $gitExe = (Get-Command git -ErrorAction Stop).Source
} catch {
  $possiblePaths = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles(x86)\Git\cmd\git.exe"
  )
  foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
      $gitExe = $path
      break
    }
  }
}

if (-not $gitExe) {
  Write-Error "git is not installed or not in PATH. Install Git and re-run this script."
  exit 1
}

# Initialize repo if needed
if (-not (Test-Path .git)) {
  & "$gitExe" init
  Write-Host "Initialized empty git repository."
}

# Remove backend/.env from index if tracked
$tracked = $false
try {
  & "$gitExe" ls-files --error-unmatch backend/.env > $null 2>&1
  $tracked = $true
} catch { $tracked = $false }
if ($tracked) {
  & "$gitExe" rm --cached backend/.env
  Write-Host "Removed backend/.env from index."
}

# Stage and commit
& "$gitExe" add .
# commit only if there are staged changes
$staged = & "$gitExe" diff --cached --name-only
if ($staged) {
  & "$gitExe" commit -m "Prepare repo for GitHub: ignore envs and initial commit"
  Write-Host "Created commit."
} else {
  Write-Host "No changes to commit."
}

# Ensure main branch
& "$gitExe" branch -M main

# Add or set remote
$remoteExists = $false
try {
  & "$gitExe" remote get-url origin > $null 2>&1
  $remoteExists = $true
} catch { $remoteExists = $false }
if ($remoteExists) {
  & "$gitExe" remote set-url origin $repoUrl
  Write-Host "Updated remote origin URL."
} else {
  & "$gitExe" remote add origin $repoUrl
  Write-Host "Added remote origin: $repoUrl"
}

# Push
Write-Host "Pushing to origin/main..." -ForegroundColor Cyan
& "$gitExe" push -u origin main

Write-Host "Done. If prompted for credentials, use your GitHub username and a Personal Access Token as password." -ForegroundColor Green
