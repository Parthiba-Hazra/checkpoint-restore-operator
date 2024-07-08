#!/bin/bash

CONFIG_FILE="kind-config.yaml"
CHECKPOINT_DIR="/var/lib/kubelet/checkpoints"

{
	echo "kind: Cluster"
	echo "apiVersion: kind.x-k8s.io/v1alpha4"
	echo "nodes:"
	echo "- role: control-plane"
	echo "  extraMounts:"
	echo "  - hostPath: $CHECKPOINT_DIR"
	echo "    containerPath: $CHECKPOINT_DIR"
} >$CONFIG_FILE
