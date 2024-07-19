#!/bin/bash

DATA_DIR="./test/data"
if [ ! -d "$DATA_DIR" ]; then
	echo "Data directory '$DATA_DIR' does not exist."
	exit 1
fi

CONFIG_DUMP="$DATA_DIR/config.dump"
SPEC_DUMP="$DATA_DIR/spec.dump"
if [ ! -f "$CONFIG_DUMP" ] || [ ! -f "$SPEC_DUMP" ]; then
	echo "config.dump and/or spec.dump files are missing in the data directory."
	exit 1
fi

TEMP_DIR=$(mktemp -d)

cp "$CONFIG_DUMP" "$TEMP_DIR"
cp "$SPEC_DUMP" "$TEMP_DIR"

create_checkpoint_tar() {
	local tar_name=$1
	local original_name=$2
	tar -cf "$tar_name" -C "$TEMP_DIR" .
	sudo mv "$tar_name" "/var/lib/kubelet/checkpoints/$original_name"
	echo "Checkpoint tar file created at /var/lib/kubelet/checkpoints/$original_name"
}

for _ in {1..5}; do
	TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
	TAR_NAME="checkpoint.tar"
	ORIGINAL_NAME="checkpoint-podname_namespace-containername-$TIMESTAMP.tar"
	create_checkpoint_tar "$TAR_NAME" "$ORIGINAL_NAME"
	sleep 1
done

rm -rf "$TEMP_DIR"
