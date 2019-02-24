# scoop-backup

Additional functionality for the [Scoop Package Manager](https://scoop.sh).

Backup your entire current scoop installation with one command:

```powershell
scoop-backup
```

This produces the compressed backup `%SCOOP_ROOT%\persist\scoop-backup\backups\backup-DDMMYY.ps1`, which can now be executed on any Windows computer to restore your entire Scoop installation, including all buckets and apps.

scoop-backup can be installed via, you guessed it, scoop, via the [knox-scoop bucket](https://git.irs.sh/KNOXDEV/knox-scoop):

```powershell
scoop bucket add knox-scoop https://git.irs.sh/KNOXDEV/knox-scoop
scoop install scoop-backup
```

## use cases
* Backing up a computer's software for easy reinstallation
* Deploying an identical scoop-based installation to many computers
* Syncing configurations between two personal computers for an effortless, uniform experience

## options

Save to a different folder:
```powershell
scoop-backup .\path\to\folder\
```

Save backup as a compressed batch file:
```powershell
scoop-backup --compressed
# >> "output-folder\backup.bat"
```

## future plans

* Implement a strategy for backing up the persistence directory. For many apps, this is trivial (ccleaner), but others pose a significant challenge (jetbrains-toolbox).