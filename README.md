# Snapback
Backup snapper Btrfs snapshots to another partition/drive.

## Usage
```bash
snapback.sh <btrfs_subvol_path> <mounted_backup_UUID>
```

#### Initial backup
You must initialize a snapback repository ONCE per snapper config per UUID.
If snapback is unable to find a previous snapshot, it will create and send a new initial snapshot.

#### Example
Normally, snapback will take advantage of btrfs's incremental backups to reduce load.
```bash
snapback.sh / 050e1e34-39e6-4072-a03e-ae0bf90ba13a
```

#### Determining UUID programatically
```bash
blkid -s UUID -o value /dev/sdX#
```

## How it works
snapback looks for snapshots of `<subvol_path>` taken by snapper with `backup=<mounted_backup_UUID>` in the userdata. If it finds one, it assumes the backup still exists on that partition and tries to send an incremental snapshot to it. If it didn't find a previous snapshot for that UUID, it will send a complete snapshot, rather than an incremental one. Backup snapshots' file names are formatted in UTC time.