$ErrorActionPreference = "Stop"

# 1. Define paths
$srcDir = "C:\src"
$flutterDir = Join-Path $srcDir "flutter"
$zipPath = Join-Path $srcDir "flutter_windows_3.44.2-stable.zip"
$workspace = "c:\Users\KABELO PC\practise_projects\CivicPulse"

Write-Host "=== Starting Flutter Environment Setup ==="

# 2. Create C:\src if it doesn't exist
if (-not (Test-Path $srcDir)) {
    Write-Host "Creating SDK directory at $srcDir..."
    New-Item -Path $srcDir -ItemType Directory | Out-Null
}

# 3. Download Flutter if not installed
if (-not (Test-Path $flutterDir)) {
    if (-not (Test-Path $zipPath)) {
        Write-Host "Downloading Flutter SDK stable (version 3.44.2)..."
        $url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.2-stable.zip"
        # Use curl for faster download with progress
        curl.exe -L -o $zipPath $url
    }

    Write-Host "Extracting Flutter SDK to $srcDir (this will take a few minutes)..."
    Expand-Archive -Path $zipPath -DestinationPath $srcDir -Force
    
    Write-Host "Cleaning up ZIP archive..."
    Remove-Item $zipPath -Force
} else {
    Write-Host "Flutter SDK already exists at $flutterDir."
}

# 4. Configure PATH for current session and user profile
$flutterBin = Join-Path $flutterDir "bin"
if ($env:Path -notlike "*flutter\bin*") {
    $env:Path += ";$flutterBin"
}

Write-Host "Updating User environment PATH..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*flutter\bin*") {
    $newUserPath = $userPath + ";$flutterBin"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "Added Flutter to User PATH. (Note: You will need to restart your IDE or terminal to reflect this change outside this session)."
} else {
    Write-Host "Flutter is already present in User PATH."
}

# 5. Verify installation
Write-Host "Verifying Flutter installation..."
& flutter --version

# 6. Initialize project in workspace
Write-Host "Initializing Flutter project in $workspace..."
Set-Location $workspace
# Use force to overwrite existing files, like README
& flutter create --org com.civicpulse --project-name civicpulse_app . --force

# 7. Add dependencies via flutter pub add
Write-Host "Configuring project dependencies..."
& flutter pub add provider google_fonts lucide_icons http supabase_flutter flutter_map latlong2

Write-Host "=== Flutter Environment Setup Completed Successfully! ==="
