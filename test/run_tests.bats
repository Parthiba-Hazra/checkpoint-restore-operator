#!/usr/bin/env bats

CHECKPOINT_DIR=${CHECKPOINT_DIR:-/var/lib/kubelet/checkpoints}

function teardown() {
  rm -rf "${CHECKPOINT_DIR:?}"/*
}

@test "test_garbage_collection" {
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
  run kubectl apply -f ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run ./test/wait_for_checkpoint_reduction.sh 2
  [ "$status" -eq 0 ]
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
}

@test "test_max_checkpoints_set_to_0" {
  run sed -i 's/maxCheckpointsPerContainer: [0-9]*/maxCheckpointsPerContainer: 0/' ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run sed -i '/^  containerPolicies:/,/maxCheckpoints: [0-9]*/ s/^/#/' ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run kubectl apply -f ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run ./test/generate_checkpoint_tar.sh
  [ "$status" -eq 0 ]
  run sleep 2
  run ./test/wait_for_checkpoint_reduction.sh 5
  [ "$status" -eq 0 ]
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
}

@test "test_max_checkpoints_set_to_1" {
  run sed -i 's/maxCheckpointsPerContainer: [0-9]*/maxCheckpointsPerContainer: 1/' ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run kubectl apply -f ./test/test_byCount_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run ./test/generate_checkpoint_tar.sh
  [ "$status" -eq 0 ]
  run ./test/wait_for_checkpoint_reduction.sh 1
  [ "$status" -eq 0 ]
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
}

@test "test_max_total_checkpoint_size" {
  run kubectl apply -f ./test/test_bySize_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run ./test/generate_checkpoint_tar.sh large
  [ "$status" -eq 0 ]
  run ./test/wait_for_checkpoint_reduction.sh 2
  [ "$status" -eq 0 ]
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
}

@test "test_max_checkpoint_size" {
  run sed -i '/^  containerPolicies:/,/maxTotalSize: [0-9]*/ s/^/#/' ./test/test_bySize_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run kubectl apply -f ./test/test_bySize_checkpointrestoreoperator.yaml
  [ "$status" -eq 0 ]
  run ./test/generate_checkpoint_tar.sh large
  [ "$status" -eq 0 ]
  run ./test/wait_for_checkpoint_reduction.sh 0
  [ "$status" -eq 0 ]
  run ls -la "$CHECKPOINT_DIR"
  [ "$status" -eq 0 ]
}
