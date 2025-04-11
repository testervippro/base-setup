# Set variables
$pythonZipUrl = "https://www.python.org/ftp/python/3.12.2/python-3.12.2-embed-amd64.zip"
$pythonZipPath = "$env:TEMP\python-portable.zip"
$pythonPath = "C:\python-portable"
$pythonExe = Join-Path $pythonPath "python.exe"
$pthFile = Join-Path $pythonPath "python312._pth"
$scriptsPath = Join-Path $pythonPath "Scripts"

# Step 1: Download and extract Python embeddable
Invoke-WebRequest -Uri $pythonZipUrl -OutFile $pythonZipPath
Expand-Archive -Path $pythonZipPath -DestinationPath $pythonPath -Force

# Step 2: Enable import site in python312._pth
(Get-Content $pthFile) -replace '#import site', 'import site' | Set-Content $pthFile

# Step 3: Download get-pip.py and install pip
Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$env:TEMP\get-pip.py"
& $pythonExe "$env:TEMP\get-pip.py" --no-warn-script-location --no-cache-dir

# Step 4: Add Scripts path if pip installed it
if (-not (Test-Path $scriptsPath)) {
    New-Item -Path $scriptsPath -ItemType Directory | Out-Null
}

# Add Scripts to PATH temporarily
$env:Path = "$pythonPath;$scriptsPath;" + $env:Path

# Step 5: Install podman-compose
& $pythonExe -m pip install podman-compose

# Step 6: Test
Write-Host "`n✅ podman-compose version:"
& $pythonExe -m podman_compose --version
