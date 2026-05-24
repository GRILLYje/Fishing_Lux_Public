$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

[console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Checking for updates (Lux)..." -ForegroundColor Cyan

$apiUrl = "https://api.github.com/repos/GRILLYje/Fishing_Lux_Public/releases/latest"

try {
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Method Get

    $version = $releaseInfo.tag_name
    $publishedAt = [datetime]$releaseInfo.published_at
    $localTime = $publishedAt.ToLocalTime().ToString("dd/MM/yyyy HH:mm:ss")

    $downloadUrl = ($releaseInfo.assets | Where-Object {
        $_.name -eq "EpicGamesLauncher.exe"
    }).browser_download_url

    $templatesZipUrl = ($releaseInfo.assets | Where-Object {
        $_.name -eq "templates.zip"
    }).browser_download_url

    if (-not $downloadUrl) {
        Write-Host "Error: Could not find EpicGamesLauncher.exe" -ForegroundColor Red
        pause
        exit
    }

    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "New Update Available!" -ForegroundColor Green
    Write-Host "Version: $version"
    Write-Host "Date & Time: $localTime"
    Write-Host "==========================================" -ForegroundColor Yellow
}
catch {
    Write-Host "Failed to fetch update info from GitHub." -ForegroundColor Red
    Write-Host $_.Exception.Message
    pause
    exit
}

$baseTemp = [System.IO.Path]::GetTempPath()
$folderPath = Join-Path $baseTemp "Lux"

if (-not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
}

$tempPath = Join-Path $folderPath "EpicGamesLauncher.exe"
$tempZipPath = Join-Path $folderPath "templates.zip"

try {
    $processName = [System.IO.Path]::GetFileNameWithoutExtension($tempPath)

    Get-Process -Name $processName -ErrorAction SilentlyContinue |
        Stop-Process -Force

    Start-Sleep -Milliseconds 500
}
catch {}

try {
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
    }
}
catch {
    Write-Host "Cannot delete old file." -ForegroundColor Red
    pause
    exit
}

try {
    $webClient = New-Object System.Net.WebClient

    Write-Host "Downloading EXE..."
    $webClient.DownloadFile($downloadUrl, $tempPath)

    if ($templatesZipUrl) {

        Write-Host "Downloading templates.zip..."
        $webClient.DownloadFile($templatesZipUrl, $tempZipPath)

        Write-Host "Extracting templates..."
        Expand-Archive -Path $tempZipPath -DestinationPath $folderPath -Force

        Remove-Item $tempZipPath -Force
    }

    Write-Host "Done!" -ForegroundColor Green
}
catch {
    Write-Host "Download failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    pause
    exit
}

Write-Host "Launching Lux..." -ForegroundColor Green

if (Test-Path $tempPath) {
    Start-Process -FilePath $tempPath -WorkingDirectory $folderPath
}
else {
    Write-Host "EXE disappeared. Defender may have removed it." -ForegroundColor Red
    pause
}
