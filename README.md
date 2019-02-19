# scoop-backup

Additional functionality for the (Scoop Package Manager)[https://scoop.sh].

Backup your entire current scoop installation with one command:

```powershell
scoop-backup ./path/to/output.ps1
```

This produces `output.ps1`, which can now be executed on any computer with PowerShell to restore your entire installation, including all buckets and apps.

scoop-backup can be installed via, you guessed it, scoop, via the (knox-scoop bucket)[https://git.irs.sh/KNOXDEV/knox-scoop]:

```powershell
scoop bucket add knox-scoop https://git.irs.sh/KNOXDEV/knox-scoop
scoop install scoop-backup
```

### Use cases:
* Backing up a computer's software for easy reinstallation
* Deploying an identical scoop-based installation to many computers
* Syncing between two personal computers for an effortless, uniform experience
