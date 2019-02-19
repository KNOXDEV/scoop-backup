param($output)

# parameter checks
if(@('-h', '--help', '/?') -contains $output) {
    Write-Host "Usage: scoop-backup ./path/to/output.bat"
    break
}
if(@('', $null) -contains $output) {
    $output = "$psscriptroot\restore.bat"
} 

# import core libraries
try {
    $scooplib = Resolve-Path "$($(Get-Command scoop).Source)\..\..\apps\scoop\current\lib"
    . "$scooplib\core.ps1"
    . "$scooplib\manifest.ps1"
    . "$scooplib\buckets.ps1"
    . "$scooplib\versions.ps1"
} catch {
    Write-Output "Failed to import Scoop libraries, not found on path"
    break
}

# creates initial restoration script content
$cmd = "try{if(Get-Command scoop){}} catch {iex (new-object net.webclient).downloadstring('https://get.scoop.sh')}"

# if we need to install some buckets, we'll need to install git first
$buckets = buckets
if(($buckets | Measure-Object).Count -gt 0) {
    $cmd += ";scoop install git;"

    # add each bucket installation on its own line
    $cmd += (buckets | ForEach-Object {
        if((known_buckets).Contains($_)) {
            $_
        } else {
            $repo_url = git config --file "$bucketsdir\$_\.git\config" remote.origin.url
            "$_ $repo_url"
        }
    } | ForEach-Object { "scoop bucket add $_" }) -Join ";"
}

# next, we install apps
$apps = installed_apps
if(($apps | Measure-Object).Count -gt 0) {

    $cmd += ";scoop install "

    $cmd += ($apps | ForEach-Object {
        $info = install_info $_ (current_version $_ $false) $false
        if($info.url) { $info.url } else { $_ }
    }) -Join " "
}

# finally, we install global apps
$globals = installed_apps $true
if(($globals | Measure-Object).Count -gt 0) {
    $cmd += ';scoop install sudo;sudo powershell -Command "scoop install --global '

    $cmd += ($globals | ForEach-Object {
        $info = install_info $_ (current_version $_ $true) $true
        if($info.url) { $($info.url) } else { $_ }
    }) -Join " "
    $cmd += '"'
}

$cmd_bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$cmd_encoded = '@echo off' + [environment]::NewLine `
                + "powershell.exe -NoProfile -EncodedCommand " + [Convert]::ToBase64String($cmd_bytes)

Write-Output "backed up to: $output"
New-Item $output -Force | Out-Null
Add-Content -Path $output -Value $cmd_encoded