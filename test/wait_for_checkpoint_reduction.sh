#!/bin/bash

CHECKPOINTS_DIR="$HOME/checkpoints"
EXPECTED_COUNT=2
TIMEOUT=60
start_time=$(date +%s)

count_tar_files() {
	find "$CHECKPOINTS_DIR" -maxdepth 1 -name "*.tar" -print | wc -l
}

# Function to print logs of operator pods
print_operator_pod_logs() {
	echo "Fetching logs of operator pods:"
	pod_names=$(kubectl -n checkpoint-restore-operator-system get pods -o jsonpath='{.items[*].metadata.name}')
	if [[ -z "$pod_names" ]]; then
		echo "No operator pods found"
	else
		for pod_name in $pod_names; do
			echo "Logs for pod $pod_name:"
			kubectl -n checkpoint-restore-operator-system logs "$pod_name" || echo "Failed to fetch logs for pod $pod_name"
		done
	fi
}

# Wait for the checkpoint tar files to be reduced from 5 to 2
while true; do
	current_count=$(count_tar_files)
	if [ "$current_count" -le "$EXPECTED_COUNT" ]; then
		echo "Checkpoint tar files reduced to $current_count (<= $EXPECTED_COUNT)"
		break
	fi
	current_time=$(date +%s)
	elapsed_time=$((current_time - start_time))
	if [ "$elapsed_time" -ge "$TIMEOUT" ]; then
		echo "Timeout reached: Checkpoint tar files count is still $current_count (should be $EXPECTED_COUNT)"
		echo "Fetching checkpoint files for debugging:"
		ls -l "$CHECKPOINTS_DIR"
		print_operator_pod_logs
		exit 1
	fi
	echo "Checkpoint tar files count is $current_count (waiting for $EXPECTED_COUNT)"
	print_operator_pod_logs
	sleep 5
done
