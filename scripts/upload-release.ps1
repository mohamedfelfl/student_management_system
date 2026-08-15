param(
    [string]$Version = "1.0.5",
    [string]$Token,
    [string]$RepoUrl = "https://github.com/mohamedfelfl/student_management_system"
)

$ErrorActionPreference = 'Stop'
$env:DOTNET_ROLL_FORWARD = "LatestMajor"
$dotnetDir = "$env:USERPROFILE\.dotnet"
$toolsDir = "$env:USERPROFILE\.dotnet\tools"
$env:PATH = "$dotnetDir;$toolsDir;$env:PATH"

$releasesDir = Join-Path $PSScriptRoot "..\Releases"

Write-Host "Uploading release v$Version to GitHub ($RepoUrl)..." -ForegroundColor Cyan

$uploadArgs = @(
    "upload", "github",
    "--repoUrl", $RepoUrl,
    "--publish",
    "--tag", "v$Version",
    "--releaseName", "Release v$Version",
    "--token", $Token,
    "--outputDir", $releasesDir
)

& vpk @uploadArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully published release v$Version to GitHub!" -ForegroundColor Green
} else {
    Write-Error "Failed to upload release to GitHub."
}
