param(
    [string]$Version = "1.0.7",
    [string]$Token,
    [string]$RepoUrl = "https://github.com/mohamedfelfl/student_management_system"
)

$ErrorActionPreference = 'Stop'
$env:DOTNET_ROLL_FORWARD = "LatestMajor"
$dotnetDir = "$env:USERPROFILE\.dotnet"
$toolsDir = "$env:USERPROFILE\.dotnet\tools"
$env:PATH = "$dotnetDir;$toolsDir;$env:PATH"

if (-not $Token) {
    if ($env:GITHUB_TOKEN) { $Token = $env:GITHUB_TOKEN }
    elseif ($env:GH_TOKEN) { $Token = $env:GH_TOKEN }
    else {
        try {
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = "git"
            $process.StartInfo.Arguments = "credential fill"
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.RedirectStandardInput = $true
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.CreateNoWindow = $true
            [void]$process.Start()
            $process.StandardInput.WriteLine("protocol=https")
            $process.StandardInput.WriteLine("host=github.com")
            $process.StandardInput.WriteLine("")
            $process.StandardInput.Close()
            $output = $process.StandardOutput.ReadToEnd()
            $process.WaitForExit()
            if ($output) {
                foreach ($line in ($output -split "`r?`n")) {
                    if ($line.Trim().StartsWith("password=")) {
                        $Token = $line.Trim().Substring(9).Trim()
                        break
                    }
                }
            }
        } catch {
            Write-Warning "Could not extract GitHub token from git credentials: $_"
        }
    }
}

if (-not $Token) {
    Write-Error "GitHub token is required to upload the release. Set GITHUB_TOKEN or pass -Token."
    exit 1
}

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
