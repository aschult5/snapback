#!/bin/bash -e

usage() {
	echo "Usage:"
	echo -e "\t$0 [-i] <subvol_path> <mounted_backup_UUID>"
}

cleanup() {
	echo "FAIL: Cleaning up '$CONFIG' by deleting newly created snapshot: $NEW"
	echo "If btrfs could not send an incremental snapshot, modify/delete snapshot $OLD so the UUID is not found"
	snapper -c $CONFIG delete $NEW
	exit 2
}

if [ "$#" != "2" ]; then
	usage
	exit 1
fi
SUBVOL=$1
UUID=$2
CONFIG=$(snapper list-configs | grep "$SUBVOL\s\+$" | cut -d'|' -f 1 | tr -d '[:space:]')
UTC_TS=$(date -u +%F_%H:%M:%S)

# Extract snapshot number of previous backup
OLD=$(snapper -c $CONFIG list -t single | grep "backup=${UUID}" | tail -n 1 | cut -d'|' -f 1 | tr -d '[:space:]')
if [ -z "$OLD" ]; then
	echo "No previous snapshot found with userdata backup=${UUID}"
else
	echo "Found previous snapshot ${OLD} with userdata backup=${UUID}"
fi

# Create new snapshot
echo "Creating snapshot for config '$CONFIG'"
if ! NEW=$(snapper -c $CONFIG create -c number -d "backup $UTC_TS" -u "important=yes,backup=${UUID}" -p); then
	echo "FAIL: Could not create snapshot for config '$CONFIG'"
	exit 2
fi


# Convert UUID mount point to snapshot destination
DEST="$(findmnt -rn -S UUID=${UUID} | cut -d' ' -f 1)/snapshots/${CONFIG}"
if [ ! -d ${DEST} ]; then
	echo "Creating $DEST"
	mkdir -p ${DEST}
fi

# Send the snapshot
if [ -z "$OLD" ]; then
	echo "Sending snapshot to ${DEST}"
	btrfs send -q ${SUBVOL}/.snapshots/${NEW}/snapshot | btrfs receive ${DEST} >/dev/null || cleanup
else
	echo "Sending incremental snapshot to ${DEST}"
	btrfs send -q -p ${SUBVOL}/.snapshots/${OLD}/snapshot ${SUBVOL}/.snapshots/${NEW}/snapshot | btrfs receive ${DEST} >/dev/null || cleanup
	# Remove backup tag from old snapshot
	snapper -c $CONFIG modify -u "backup=" $OLD
fi

# Timestamp the new snapshot

mv ${DEST}/snapshot ${DEST}/${UTC_TS}
echo "Done sending snapshot ${UTC_TS}"
