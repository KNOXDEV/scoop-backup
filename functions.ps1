# passed_one_of() but accepts our custom argument object
function passed($argument) {
    return passed_one_of($argument.Aliases)
}

# checks for arguments that match one of the $aliases, strips out matches, and returns true if they were found
function passed_one_of($aliases) {
    $mismatches = $arguments | where { $aliases -notcontains $_ }
    if($mismatches.Count -lt $arguments.Count) {
        $global:arguments = $mismatches
        return $true
    }
    return $false
}

# creates a hashtable object storing information about this argument
function argument($description) {
    return @{
        Description = $description;
        Aliases = $args
    }
}

# prints a message with the error formatting, but does not break
function complain($message) {
    Write-Host -ForegroundColor $host.PrivateData.ErrorForegroundColor -BackgroundColor $host.PrivateData.ErrorBackgroundColor $message
}

# executes the first expression, but falls back to the second if it isn't defined
function invoke($cmd, $fallback) {
    if(Get-Command $cmd -errorAction SilentlyContinue) {
        Invoke-Expression $cmd
    } else {
        Invoke-Expression $fallback
    }
}

# appends another line to our in-progress script file
function append($line) {
    $global:cmd += ($line + "`n")
}