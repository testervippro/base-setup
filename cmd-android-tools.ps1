# === Configuration ===
$androidZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
$androidSdkRoot = "C:\Android\android_sdk"
$cmdlineTempPath = "$androidSdkRoot\cmdline-tools\temp"
$cmdlineToolsPath = "$androidSdkRoot\cmdline-tools\latest"
$buildToolsVersion = "34.0.0"
$androidUserHome = "$androidSdkRoot\.android"
$androidZipPath = "$androidSdkRoot\commandlinetools.zip"
$deviceName = "pixel_4a"
$systemImage = "system-images;android-34;google_apis;x86_64"

# === Ensure SDK root exists ===
if (-Not (Test-Path $androidSdkRoot)) {
    New-Item -ItemType Directory -Path $androidSdkRoot -Force | Out-Null
}

# === Download SDK ZIP if not already present ===
if (-Not (Test-Path $androidZipPath)) {
    Invoke-WebRequest -Uri $androidZipUrl -OutFile $androidZipPath
}

# === Extract Command Line Tools ===
if (-Not (Test-Path "$cmdlineToolsPath\bin\sdkmanager.bat")) {
    if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
    if (Test-Path $cmdlineTempPath) { Remove-Item -Recurse -Force $cmdlineTempPath }

    Expand-Archive -Path $androidZipPath -DestinationPath $cmdlineTempPath -Force
    Move-Item "$cmdlineTempPath\cmdline-tools" $cmdlineToolsPath -Force
}

# === Set environment variables (session) ===
$env:ANDROID_HOME = $androidSdkRoot
$env:ANDROID_SDK_ROOT = $androidSdkRoot
$env:ANDROID_USER_HOME = $androidUserHome

# === Persist environment variables (machine-wide) ===
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdkRoot, "Machine")
[System.Environment]::SetEnvironmentVariable("ANDROID_USER_HOME", $androidUserHome, "Machine")

# === Add essential paths to system PATH ===
$pathsToAdd = @(
    "$cmdlineToolsPath\bin",
    "$androidSdkRoot\platform-tools",
    "$androidSdkRoot\emulator",
    "$androidSdkRoot\build-tools\$buildToolsVersion"
)
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" | Where-Object { $_ -ne "" }
$newPath = ($currentPath + $pathsToAdd | Select-Object -Unique) -join ";"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

# === Install required SDK packages ===
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

# === Create AVD if it doesn't exist ===
$avdPath = "$androidUserHome\avd\$deviceName.avd"
if (-Not (Test-Path $avdPath)) {
    Write-Host "Creating AVD: $deviceName"
    & "$cmdlineToolsPath\bin\avdmanager.bat" create avd `
        --name $deviceName `
        --package $systemImage `
        --device "pixel_4a" `
        --sdcard 51M `
        --force
} else {
    Write-Host "AVD '$deviceName' already exists."
}

# === Verify tool installation ===
Write-Host ""
Write-Host "Verifying SDK tools..."
& "$androidSdkRoot\platform-tools\adb.exe" version
& "$cmdlineToolsPath\bin\avdmanager.bat" -h
& "$androidSdkRoot\build-tools\$buildToolsVersion\aapt2.exe" version
& "$androidSdkRoot\emulator\emulator.exe" -list-avds
