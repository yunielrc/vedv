# shellcheck disable=SC2016
load test_helper

teardown() {
  # remove created vm in this test unit
  # cloned vm must be removed first
  delete_all_test_unit_vms
}

@test "vedv::virtualbox::import, with 'ova_file' undefined should return error" {
  run vedv::virtualbox::import

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::import, with 'vm_name' undefined should return error" {
  local -r ova_file="/tmp/${RANDOM}${RANDOM}.ova"

  run vedv::virtualbox::import "$ova_file"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::import, with 'ova_file' that doesnt't exist should return error" {
  local -r ova_file="/tmp/feacd213baf31d50798a.ova"
  local -r vm_name="alpine-feacd213baf31d50798a"

  run vedv::virtualbox::import "$ova_file" "$vm_name"

  assert_failure 64
  assert_output "OVA file doesn't exist"
}

@test "vedv::virtualbox::import, should import a vm from ova" {
  local -r ova_file="$TEST_OVA_FILE"
  local -r vm_name="$(gen_vm_name)"

  run vedv::virtualbox::import "$ova_file" "$vm_name"

  assert_success

  run VBoxManage list vms

  assert_output --partial "$vm_name"
}

@test "vedv::virtualbox::take_snapshot, with 'vm_name' undefined should return error" {
  run vedv::virtualbox::take_snapshot

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::take_snapshot, with 'snapshot_name' undefined should return error" {
  local -r vm_name="vm1"

  run vedv::virtualbox::take_snapshot "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::take_snapshot, should create a snapshot" {
  local -r vm_name="$(create_vm)"
  local -r snapshot_name="snapshot1"

  run vedv::virtualbox::take_snapshot "$vm_name" "$snapshot_name"

  assert_success
  assert_output --partial "Snapshot taken"
}

@test "vedv::virtualbox::clonevm_link, with 'vm_name' undefined should return error" {
  run vedv::virtualbox::clonevm_link

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::clonevm_link, with 'vm_clone_name' undefined should return error" {
  local -r vm_name='vm'
  run vedv::virtualbox::clonevm_link "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::clonevm_link, with a 'vm_name' that doesn't exist should return error" {
  local -r vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::virtualbox::clonevm_link "$vm_name" "$vm_clone_name"

  assert_failure 1
  assert_output --partial "Could not find a registered machine named 'vm'"
}

@test "vedv::virtualbox::clonevm_link, should clone the vm" {
  local -r vm_name="$(create_vm)"
  local -r vm_clone_name="$(gen_vm_clone_name)"

  run vedv::virtualbox::clonevm_link "$vm_name" "$vm_clone_name"

  assert_success
  assert_output --partial "Machine has been successfully cloned"
}

@test "vedv::virtualbox::list_wms_by_partial_name, with 'vm_partial_name' that doesn't exist should print an empty list" {
  local -r vm_partial_name='container:happy'

  run vedv::virtualbox::list_wms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output ''
}

@test "vedv::virtualbox::list_wms_by_partial_name, should print a list of vm" {
  local -r vm_partial_name='testunit:virtualbox'
  create_vm

  run vedv::virtualbox::list_wms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output --partial 'testunit:virtualbox-1020623423-alpine-x86_64'
}
