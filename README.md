# Snapback
Backup snapper Btrfs snapshots to another partition/drive.

## Usage
```bash
snapback.sh [-i] <subvol_path> <mounted_backup_UUID>
```

#### Initial backup
**NOT YET IMPLEMENTED**
You must initialize a snapback repository ONCE per snapper config per UUID.
```bash
snapback.sh -i / 050e1e34-39e6-4072-a03e-ae0bf90ba13a
```

#### Incremental backups
Now that your drive has been initialized, snapback may backup incrementally. It will take advantage of btrfs's incremental backups to reduce load.
```bash
snapback.sh / 050e1e34-39e6-4072-a03e-ae0bf90ba13a
```

#### Determining UUID programatically
```bash
blkid -s UUID -o value /dev/sdX#
```

## How it works
snapback looks for snapshots of `<subvol_path>` taken by snapper with `backup=<mounted_backup_UUID>` in the userdata. If it finds one, it assumes the backup still exists on that partition and sends an incremental snapshot to it. Backup snapshots' file names are formatted in UTC time.