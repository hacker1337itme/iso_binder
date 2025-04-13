param(
    [string]$directoryPath = "C:\Your\Directory\Path",  # Default directory path
    [string]$urlOfIsoFile = "http://example.com/path/to/file.iso" # Default ISO URL
)

# Logs messages to a log file
function Log-Message {
    param (
        [string]$message
    )
    $logFile = Join-Path $directoryPath "script-log.txt"
    Add-Content -Path $logFile -Value "$(Get-Date): $message"
}

# Checks if a directory exists
function Check-DirectoryExists {
    param (
        [string]$path
    )
    return Test-Path -Path $path
}

# Lists all folders with the system attribute
function Get-SystemFolders {
    param (
        [string]$path
    )
    return Get-ChildItem -Path $path -Directory | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::System }
}

# Downloads a file from URL
function Download-File {
    param (
        [string]$url,
        [string]$destination
    )
    try {
        Invoke-WebRequest -Uri $url -OutFile $destination
        Log-Message "Downloaded $url to $destination."
    } catch {
        Log-Message "Failed to download from $url. Error: $_"
        return $false
    }
    return $true
}

# Creates a ZIP file
function Create-ZipFile {
    param (
        [string]$zipPath
    )
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    try {
        [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create).Dispose()
        Log-Message "Created ZIP file at $zipPath."
    } catch {
        Log-Message "Failed to create ZIP file at $zipPath. Error: $_"
        return $false
    }
    return $true
}

# Adds a file to the ZIP file
function Add-FileToZip {
    param (
        [string]$zipPath,
        [string]$filePath
    )
    try {
        $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Update)
        $zip.CreateEntryFromFile($filePath, [System.IO.Path]::GetFileName($filePath))
        Log-Message "Added $filePath to $zipPath."
    } catch {
        Log-Message "Failed to add $filePath to $zipPath. Error: $_"
    } finally {
        $zip.Dispose()
    }
}

# Removes a file
function Remove-File {
    param (
        [string]$filePath
    )
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
        Log-Message "Removed file $filePath."
    } else {
        Log-Message "File $filePath does not exist."
    }
}

# Checks if a file exists
function Check-FileExists {
    param (
        [string]$filePath
    )
    return Test-Path -Path $filePath
}

# Get folder information
function Get-FolderInfo {
    param (
        [string]$folderPath
    )
    Get-Item $folderPath | Select-Object Name, FullName, Attributes
}

# Lists all ISO files in the specified directory
function List-IsoFiles {
    param (
        [string]$path
    )
    return Get-ChildItem -Path $path -Filter *.iso
}

# Main script logic
if (-not (Check-DirectoryExists -path $directoryPath)) {
    Write-Host "The directory '$directoryPath' does not exist."
    Log-Message "The directory '$directoryPath' does not exist."
    exit
}

$systemFolders = Get-SystemFolders -path $directoryPath

foreach ($folder in $systemFolders) {
    Log-Message "Processing folder: $folder"

    $zipFilePath = Join-Path $folder.FullName "droop.zip"

    # Create a new ZIP file
    if (-not (Create-ZipFile -zipPath $zipFilePath)) {
        continue
    }

    # Download the ISO file
    $isoDestination = Join-Path $folder.FullName "file.iso"
    if (-not (Download-File -url $urlOfIsoFile -destination $isoDestination)) {
        continue
    }

    # Add the ISO file to the ZIP archive
    Add-FileToZip -zipPath $zipFilePath -filePath $isoDestination

    # Optionally, delete the iso after adding to ZIP
    Remove-File -filePath $isoDestination
}

Log-Message "Script completed. [ENJOY]"
