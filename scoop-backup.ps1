param($output)

# parameter checks
if(@('-h', '--help', '/?') -contains $output) {
    Write-Host "Usage: scoop-backup ./path/to/output.ps1"
    break
}
if(@('', $null) -contains $output) {
    $output = "$psscriptroot\restore.ps1"
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

# adds content to the output file, one line at a time
function add($line) {
    Add-Content -Path $output -Value $line
}

# creates initial restoration script content
New-Item $output -Force | Out-Null
add "# install Scoop if it isn't already"
add "iex (new-object net.webclient).downloadstring('https://get.scoop.sh')"
add ""

$buckets = buckets
$known = known_buckets

# if we need to install some buckets, we'll need to install git first
if(($buckets | Measure-Object).Count -gt 0) {
    add "# install extra buckets"
    add "scoop install git"

    # add each bucket installation on its own line
    ForEach($bucket in $buckets) {
        if($known.Contains($bucket)) {
            add "scoop bucket add $bucket"
        }
        else {
            $repo_url = git config --file "$bucketsdir\$bucket\.git\config" remote.origin.url
            add "scoop bucket add $bucket $repo_url"
        }
    }
}

# next, we install apps
$apps = installed_apps
if(($apps | Measure-Object).Count -gt 0) {
    add "# install local apps"

    $install_cmd = "scoop install"

    $apps | ForEach-Object {
        $info = install_info $_ (current_version $_ $false) $false
        if($info.url) {
            $install_cmd += " $($info.url)"
        } else {
            $install_cmd += " $_"
        }
    }
    add $install_cmd
}

# finally, we install global apps
$globals = installed_apps $true
if(($globals | Measure-Object).Count -gt 0) {
    add "# install global apps"
    add "scoop install sudo"

    $global_cmd = 'sudo powershell -Command "scoop install --global'

    $globals | ForEach-Object {
        $info = install_info $_ (current_version $_ $true) $true
        if($info.url) {
            $global_cmd += " $($info.url)"
        } else {
            $global_cmd += " $_"
        }
    }
    $global_cmd += '"'
    add $global_cmd
}

Write-Output "restoration script saved to:"
Get-Item $output