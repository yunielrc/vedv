# shellcheck disable=SC2016
load test_helper

teardown() {
  delete_vms_by_id_tag "${VM_TAG}-clone"
  delete_vms_by_id_tag "$VM_TAG"
}
# shellcheck disable=SC2120
gen_vm_clone_name() {
  echo "$(gen_vm_name "${1:-}")-clone"
}

@test "vedv::virtualbox::validate_vm_name(), should be short name" {
  local -r vm_name='1234'

  run vedv::virtualbox::validate_vm_name "$vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be shorter than 5 characters'
}

@test "vedv::virtualbox::validate_vm_name(), should be large name" {
  local -r vm_name="$(printf 'n%.0s' {1..61})"

  run vedv::virtualbox::validate_vm_name "$vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be longer than 60 characters'
}

@test "vedv::virtualbox::validate_vm_name(), should be ok" {
  local -r vm_name="$(printf 'n%.0s' {1..60})"

  run vedv::virtualbox::validate_vm_name "$vm_name"

  assert_success
  assert_output ''
}

@test "vedv::virtualbox::import(), with 'ova_file' undefined should return error" {
  run vedv::virtualbox::import

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::import(), with 'vm_name' undefined should return error" {
  local -r ova_file="/tmp/${RANDOM}${RANDOM}.ova"

  run vedv::virtualbox::import "$ova_file"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::import(), with 'ova_file' that doesnt't exist should return error" {
  local -r ova_file="/tmp/feacd213baf31d50798a.ova"
  local -r vm_name="alpine-feacd213baf31d50798a"

  run vedv::virtualbox::import "$ova_file" "$vm_name"

  assert_failure 64
  assert_output "OVA file doesn't exist"
}

@test "vedv::virtualbox::import(), should import a vm from ova" {
  local -r ova_file="$TEST_OVA_FILE"
  local -r vm_name="$(gen_vm_name)"

  run vedv::virtualbox::import "$ova_file" "$vm_name"

  assert_success

  run VBoxManage list vms

  assert_output --partial "$vm_name"
}

@test "vedv::virtualbox::take_snapshot(), with 'vm_name' undefined should return error" {
  run vedv::virtualbox::take_snapshot

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::take_snapshot(), with 'snapshot_name' undefined should return error" {
  local -r vm_name="vm1"

  run vedv::virtualbox::take_snapshot "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::take_snapshot(), should create a snapshot" {
  local -r vm_name="$(create_vm)"
  local -r snapshot_name="snapshot1"

  run vedv::virtualbox::take_snapshot "$vm_name" "$snapshot_name"

  assert_success
  assert_output --partial "Snapshot taken"
}

@test "vedv::virtualbox::clonevm_link(), with 'vm_name' undefined should return error" {
  run vedv::virtualbox::clonevm_link

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::clonevm_link(), with 'vm_clone_name' undefined should return error" {
  local -r vm_name='vm'
  run vedv::virtualbox::clonevm_link "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::clonevm_link(), with a 'vm_name' that doesn't exist should return error" {
  local -r vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::virtualbox::clonevm_link "$vm_name" "$vm_clone_name"

  assert_failure 1
  assert_output --partial "Could not find a registered machine named 'vm'"
}

@test "vedv::virtualbox::clonevm_link(), should clone the vm" {
  local -r vm_name="$(create_vm)"
  # shellcheck disable=SC2119
  local -r vm_clone_name="$(gen_vm_clone_name)"

  run vedv::virtualbox::clonevm_link "$vm_name" "$vm_clone_name"

  assert_success
  assert_output --partial "Machine has been successfully cloned"
}

@test "vedv::virtualbox::list_wms_by_partial_name, with 'vm_partial_name()' that doesn't exist should print an empty list" {
  local -r vm_partial_name='container:happy'

  run vedv::virtualbox::list_wms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output ''
}
# bats test_tags=only
@test "vedv::virtualbox::list_wms_by_partial_name(), should print a list of vm" {
  local -r vm_partial_name='virtualbox'
  create_vm

  run vedv::virtualbox::list_wms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output --partial 'virtualbox'
}

@test "vedv::virtualbox::poweroff(), with 'vm_name' undefined should throw an error" {
  run vedv::virtualbox::poweroff

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::poweroff(), should poweroff a vm" {
  skip # this test is problematic
  local -r vm_name="$(create_vm)"
  VBoxManage startvm "$vm_name"

  run vedv::virtualbox::poweroff "$vm_name"

  assert_success
  assert_output --partial '<put the output here>'
}

@test "vedv::virtualbox::rm(), with 'vm_name' undefined should throw an error" {
  run vedv::virtualbox::rm

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::rm(), Should remove the vm" {
  local -r vm_name="$(create_vm)"

  run vedv::virtualbox::rm "$vm_name"

  assert_success
}

@test "vedv::virtualbox::list(), Should print all vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  run vedv::virtualbox::list

  assert_success
  assert_output "${vm_name1}
${vm_name2}"
}

@test "vedv::virtualbox::list(), Should print running vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  VBoxManage startvm "$vm_name1" --type headless

  run vedv::virtualbox::list_running

  assert_success
  assert_output "${vm_name1}"
}

@test "vedv::virtualbox::show_snapshots(), Should print no snapshots" {
  local -r vm_name1="$(create_vm)"

  run vedv::virtualbox::show_snapshots "$vm_name1"

  assert_success
  assert_output ''
}

@test "vedv::virtualbox::show_snapshots(), Should print snapshots" {
  local -r vm_name1="$(create_vm)"
  local -r snapshot_name1="snapshot1"
  local -r snapshot_name2="snapshot2"

  VBoxManage snapshot "$vm_name1" take "$snapshot_name1"
  VBoxManage snapshot "$vm_name1" take "$snapshot_name2"
  run vedv::virtualbox::show_snapshots "$vm_name1"

  assert_success
  assert_output "${snapshot_name1}
${snapshot_name2}"
}
