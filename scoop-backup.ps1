#requires -Version 3
# include functions and argument processing
$global:arguments = $args
. "$psscriptroot\functions.ps1"

$supported_arguments = @(
    (argument 'prints this help message' '-h' '--help' '/?' '-?'),
    (argument 'compresses the restoration script as an encoded batch file' '-c' '--compress')
)

# parse various default path settings
$compressed = passed($supported_arguments[1])
$default_filename = "backup-$(Get-Date -f yyMMdd)"
$default_file = "$default_filename" + $(if($compressed) {".bat"} else {".ps1"})
$default_destination = "$psscriptroot\backups\$default_file"
$destination = $default_destination

# check for help arguments
if(passed($supported_arguments[0])) {
    Write-Host "Usage: scoop-backup [flags] [destination_folder] `n"
    Write-Host "Default destination: $default_destination `n"

    $supported_arguments | ForEach-Object {
        Write-Host "$($_.Aliases)   `t $($_.Description)"
    }
    break
}

# filter all paths from our arguments and set our output folder the last path found
$global:arguments = $arguments | Where {
    if(Test-Path -Path $_ -PathType container) {
        $destination = "$_\$default_file"
        return $false
    }
    complain "the following path does not exist or is not a directory: $_"
    return $true
}

# complain about unrecognized arguments and abort if found
if($arguments.Count -ne 0) {
    complain "unrecognized arguments: $arguments"
    complain "see: 'scoop-backup --help'"
    break
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
$global:cmd = "try{if(Get-Command scoop){}} catch {iex (new-object net.webclient).downloadstring('https://get.scoop.sh')}`n"

# if we need to install some buckets, we'll need to install git first
$buckets = invoke "Get-LocalBucket" "buckets"
if(($buckets | Measure-Object).Count -gt 0) {
    append "scoop install git"

    # add each bucket installation on its own line
    $buckets | ForEach-Object {
        $repo_url = git config --file "$bucketsdir\$_\.git\config" remote.origin.url
        "$_ $repo_url"
    } | ForEach-Object { append "scoop bucket add $_" }
}

# next, we install apps
$apps = installed_apps
if(($apps | Measure-Object).Count -gt 0) {

    # installing each app on a new line is, unfortunately, more resilient
    $apps | ForEach-Object {
        $info = install_info $_ (Select-CurrentVersion -AppName $_ -Global:$false) $false
        if($info.url) { $info.url } else { "$($info.bucket)/$_" }
    } | ForEach-Object { append "scoop install $_" }
}

# finally, we install global apps
$globals = installed_apps $true
if(($globals | Measure-Object).Count -gt 0) {
    append 'scoop install main/sudo'

    # installing each app on a new line is, unfortunately, more resilient
    append ('sudo powershell -Command "scoop install --global ' + (($globals | ForEach-Object {
        $info = install_info $_ (Select-CurrentVersion -AppName $_ -Global:$true) $true
        if($info.url) { $($info.url) } else { "$($info.bucket)/$_" }
    }) -Join ";scoop install --global ") + '"')
}

# writing the final output
New-Item $destination -Force | Out-Null
if($compressed) {
    $cmd_bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $cmd_encoded = '@echo off' + [environment]::NewLine `
                + "powershell.exe -NoProfile -EncodedCommand " `
                + [Convert]::ToBase64String($cmd_bytes) + [environment]::NewLine `
                + 'pause'
    Add-Content -Path $destination -Value $cmd_encoded
} else {
    Add-Content -Path $destination -Value $cmd
}

Write-Output "backed up to: $destination"
