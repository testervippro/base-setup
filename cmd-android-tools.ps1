# ===============================
# Minimal Android SDK Setup (Windows) with Lightweight Pixel AVD
# ===============================

# Configuration
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidZipPath = "$env:USERPROFILE\Downloads\commandlinetools.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$buildToolsVersion = "34.0.0"
$avdName = "pixel"
$systemImage = "system-images;android-30;google_apis_playstore;x86"

# Ensure SDK root directory exists
if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# Download SDK if not already downloaded
if (-Not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# Extract command line tools
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# Set environment variables
$env:ANDROID_HOME = $androidSdkRoot
$env:ANDROID_SDK_ROOT = $androidSdkRoot
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")

# Add SDK paths to system PATH
$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)

$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# Install required packages
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"
$packages = @(
    "cmdline-tools;latest",
    "platform-tools",
    "emulator",
    "build-tools;$buildToolsVersion",
    $systemImage
)

function Install-PackageIfMissing {
    param([string]$pkg)
    $installed = & $sdkmanager --list_installed 2>&1 | Select-String $pkg
    if (-not $installed) {
        Write-Host "Installing: $pkg"
        & $sdkmanager $pkg --sdk_root="$androidSdkRoot"
    } else {
        Write-Host "Already installed: $pkg"
    }
}

foreach ($pkg in $packages) {
    Install-PackageIfMissing $pkg
}

# Accept licenses
& $sdkmanager --licenses --sdk_root="$androidSdkRoot" | ForEach-Object { $_ }

# Create Pixel 1 AVD if it doesn't exist
$avdmanager = "$cmdlineToolsPath\bin\avdmanager.bat"
$existingAvd = & $avdmanager list avd | Select-String $avdName
if (-not $existingAvd) {
    Write-Host "Creating AVD: $avdName (Pixel 1)"
    & $avdmanager create avd -n $avdName --device "pixel" -k $systemImage --force
} else {
    Write-Host "AVD already exists: $avdName"
}
