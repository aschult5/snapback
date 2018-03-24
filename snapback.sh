#!/bin/bash -e

usage() {
	echo "Usage:"
	echo -e "\t$0 <subvol_path> <mounted_backup_UUID>"
}

cleanup() {
	echo "FAIL: Cleaning up '$CONFIG' by deleting newly created snapshot: $NEW"
	snapper -c $CONFIG delete $NEW
	exit 2
}

if [ $# -ne 2 ]; then
	usage
	exit 1
fi

SUBVOL=$1
CONFIG=$(snapper list-configs | grep "$SUBVOL\s\+$" | cut -d'|' -f 1 | tr -d '[:space:]')
UUID=$2

# Extract snapshot number of previous backup
OLD=$(snapper -c $CONFIG list -t single | grep "backup=${UUID}" | tail -n 1 | cut -d'|' -f 1 | tr -d '[:space:]')
if [ -z "$OLD" ]; then
	echo "FAIL: No existing backup for UUID=${UUID}"
	exit 2
fi

# Create new snapshot
echo "Creating snapshot for config '$CONFIG'"
if ! NEW=$(snapper -c $CONFIG create -c number -d "backup $(date -u +%F)" -u "important=yes,backup=${UUID}" -p); then
	echo "FAIL: Could not create snapshot for config '$CONFIG'"
	exit 2
fi


# Convert UUID mount point to snapshot destination
DEST="$(findmnt -rn -S UUID=${UUID} | cut -d' ' -f 1)/snapshots/${CONFIG}"
if [ ! -d ${DEST} ]; then
	echo "Creating $DEST"
	mkdir -p ${DEST}
fi

# Send the incremental snapshot
echo "Sending incremental snapshot to ${DEST}"
btrfs send -q -p ${SUBVOL}/.snapshots/${OLD}/snapshot ${SUBVOL}/.snapshots/${NEW}/snapshot | btrfs receive ${DEST} >/dev/null || cleanup

# Timestamp the new snapshot
NAME=$(date -u +%F_%H:%M:%S)
mv ${DEST}/snapshot ${DEST}/${NAME}
echo "Created incremental snapshot ${NAME}"

# Remove backup tag from old snapshot
snapper -c $CONFIG modify -u "backup=" $OLD
