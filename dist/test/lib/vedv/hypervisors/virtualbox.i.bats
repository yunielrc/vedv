# shellcheck disable=SC2016,SC2317,SC2031,SC2030,SC2119,SC2120,SC2154
load test_helper

setup_file() {
  # delete_vms_directory
  :
}

# teardown_file(){
#   delete_vms_directory
# }

teardown() {
  delete_vms_by_id_tag "${VM_TAG}-clone"
  delete_vms_by_id_tag "$VM_TAG"

  delete_vms_by_partial_vm_name 'image123'
  delete_vms_by_partial_vm_name 'container:'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'

  if [[ -d "$TEST_IMAGE_TMP_DIR" &&
    "$TEST_IMAGE_TMP_DIR" == */tmp/* ]]; then
    rm -rf "$TEST_IMAGE_TMP_DIR"
  fi
  [[ -d "$TEST_IMAGE_TMP_DIR" ]] ||
    mkdir -p "$TEST_IMAGE_TMP_DIR"
}
# shellcheck disable=SC2120
gen_vm_clone_name() {
  echo "$(gen_vm_name "${1:-}")-clone"
}

# Tests for vedv::virtualbox::validate_vm_name()
@test "vedv::virtualbox::validate_vm_name(), should be short name" {
  local -r __vm_name='1234'

  run vedv::virtualbox::validate_vm_name "$__vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be shorter than 5 characters'
}

@test "vedv::virtualbox::validate_vm_name(), should be large name" {
  local -r __vm_name="$(printf 'n%.0s' {1..61})"

  run vedv::virtualbox::validate_vm_name "$__vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be longer than 60 characters'
}

@test "vedv::virtualbox::validate_vm_name(), should be ok" {
  local -r __vm_name="$(printf 'n%.0s' {1..60})"

  run vedv::virtualbox::validate_vm_name "$__vm_name"

  assert_success
  assert_output ''
}

# Tests for vedv::virtualbox::import()
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
  local -r __vm_name="alpine-feacd213baf31d50798a"

  run vedv::virtualbox::import "$ova_file" "$__vm_name"

  assert_failure 64
  assert_output "OVA file doesn't exist"
}

@test "vedv::virtualbox::import() Should fail If __remove_vm_existing_directory fails" {
  local -r ova_file="$TEST_OVA_FILE"
  local -r __vm_name="alpine-feacd213baf31d50798a"

  vedv::virtualbox::__remove_vm_existing_directory() {
    assert_equal "$*" "$__vm_name"
    return 1
  }

  run vedv::virtualbox::import "$ova_file" "$__vm_name"

  assert_failure
  assert_output "Failed to remove existing directory for vm 'alpine-feacd213baf31d50798a' that is going to be created"
}

@test "vedv::virtualbox::import() Should succeed" {

  run vedv::virtualbox::import "$TEST_OVA_FILE" "image123"

  assert_success

  run VBoxManage list vms

  assert_success
  assert_output --partial "image123"
}

@test "vedv::virtualbox::import() Should fail If a directory for the vm exists and its not removed" {
  local __vm_name="image123-import1"
  local -r vbox_vms_dir="$(vedv::virtualbox::__get_vms_directory)"
  local -r vm_directory_name="$(vedv::virtualbox::__vm_name_to_vm_dirname "$__vm_name")"
  local -r vm_directory="${vbox_vms_dir}/${vm_directory_name}"

  if [[ ! -d "$vm_directory" ]]; then
    mkdir -p "$vm_directory"
    touch "${vm_directory}/${__vm_name}.vbox"
  fi

  vedv::virtualbox::__remove_vm_existing_directory() {
    assert_equal "$*" "$__vm_name"
  }

  run vedv::virtualbox::import "$TEST_OVA_FILE" "$__vm_name"
  rm -rf "$vm_directory"

  assert_failure
  assert_output --regexp "Machine settings file '/.*/${__vm_name}.vbox' already exists"
}

@test "vedv::virtualbox::import() Should succeed If a directory for the vm exists and its removed" {
  local __vm_name="image123-import2"
  local -r vbox_vms_dir="$(vedv::virtualbox::__get_vms_directory)"
  local -r vm_directory_name="$(vedv::virtualbox::__vm_name_to_vm_dirname "$__vm_name")"
  local -r vm_directory="${vbox_vms_dir}/${vm_directory_name}"

  if [[ ! -d "$vm_directory" ]]; then
    mkdir -p "$vm_directory"
    touch "${vm_directory}/${__vm_name}.vbox"
    touch "${vm_directory}/alpine-x86_64-disk001.vmdk"
  fi

  run vedv::virtualbox::import "$TEST_OVA_FILE" "$__vm_name"

  assert_success
  assert_output --partial "Successfully imported the appliance"
}

# Tests for vedv::virtualbox::take_snapshot()
@test "vedv::virtualbox::take_snapshot(), with 'vm_name' undefined should return error" {
  run vedv::virtualbox::take_snapshot

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::take_snapshot(), with 'snapshot_name' undefined should return error" {
  local -r __vm_name="vm1"

  run vedv::virtualbox::take_snapshot "$__vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::take_snapshot(), should create a snapshot" {
  local -r __vm_name="$(create_vm)"
  local -r snapshot_name="snapshot1"

  run vedv::virtualbox::take_snapshot "$__vm_name" "$snapshot_name"

  assert_success
  assert_output --partial "Snapshot taken"
}

# Tests for vedv::virtualbox::clonevm()
@test "vedv::virtualbox::clonevm() Should fail with invalid vm_name" {
  local -r __vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The vm_name name cannot be shorter than 5 characters"
}

@test "vedv::virtualbox::clonevm() Should fail with invalid vm_clone_name" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='vmc'

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The clone_vm_name name cannot be shorter than 5 characters"
}

@test "vedv::virtualbox::clonevm() Should fail If __remove_vm_existing_directory fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'

  vedv::virtualbox::__remove_vm_existing_directory() {
    assert_equal "$*" "clone_name1"
    return 1
  }

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "Failed to remove existing directory for vm 'clone_name1' that is going to be created"
}

@test "vedv::virtualbox::clonevm() Should fail If clonevm fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --snapshot snapshot1"
      return 1
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1' from snapshot 'snapshot1'"
}

@test "vedv::virtualbox::clonevm() Should succeed" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --snapshot snapshot1"
      return 0
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}

@test "vedv::virtualbox::clonevm() Should fail If clonevm fails without snapshot" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot=''

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register"
      return 1
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::virtualbox::clonevm() Should succeed without snapshot" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot=''

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register"
      return 0
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::clonevm "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}
# Tests for vedv::virtualbox::clonevm_link()
@test "vedv::virtualbox::clonevm_link(), with 'vm_name' undefined should return error" {
  run vedv::virtualbox::clonevm_link

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::clonevm_link(), with 'vm_clone_name' undefined should return error" {
  local -r __vm_name='vm'
  run vedv::virtualbox::clonevm_link "$__vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::virtualbox::clonevm_link(), Should fail If __remove_vm_existing_directory fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='vm_clone'

  vedv::virtualbox::__remove_vm_existing_directory() {
    assert_equal "$*" "$vm_clone_name"
    return 1
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "Failed to remove existing directory for vm 'vm_clone' that is going to be created"
}

@test "vedv::virtualbox::clonevm_link(), with a 'vm_name' that doesn't exist should return error" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='vm_clone'

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output --partial "Could not find a registered machine named 'vm_name1'"
}

@test "vedv::virtualbox::clonevm_link(), should clone the vm" {
  local -r __vm_name="$(create_vm)"
  # shellcheck disable=SC2119
  local -r vm_clone_name="$(gen_vm_clone_name)"

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name"

  assert_success
  assert_output --partial "Machine has been successfully cloned"
}

@test "vedv::virtualbox::clonevm_link() Should fail with invalid vm_name" {
  local -r __vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The vm_name name cannot be shorter than 5 characters"
}

@test "vedv::virtualbox::clonevm_link() Should fail with invalid vm_clone_name" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='vmc'

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The clone_vm_name name cannot be shorter than 5 characters"
}

@test "vedv::virtualbox::clonevm_link() Should fail If take_snapshot fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::virtualbox::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
    return 1
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to create snapshot '${vm_clone_name}'"
}

@test "vedv::virtualbox::clonevm_link() Should fail If clonevm_link fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::virtualbox::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
    command VBoxManage "$@"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
    return 1
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to delete snapshot 'clone_name1'
Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::virtualbox::clonevm_link() Should fail If clonevm fails 2" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::virtualbox::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
    command VBoxManage "$@"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::virtualbox::clonevm_link() Should fail With create_snapshot=false and clonevm fails" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='false'

  vedv::virtualbox::take_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
    command VBoxManage "$@"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name" "$vm_snapshot" "$create_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::virtualbox::clonevm_link() Should succeed" {
  local -r __vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::virtualbox::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == clonevm ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 0
    fi
    command VBoxManage "$@"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::virtualbox::clonevm_link "$__vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}
# Tests for vedv::virtualbox::list_vms_by_partial_name()
@test "vedv::virtualbox::list_vms_by_partial_name, with 'vm_partial_name()' that doesn't exist should print an empty list" {
  local -r vm_partial_name='container:happy'

  run vedv::virtualbox::list_vms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output ''
}

@test "vedv::virtualbox::list_vms_by_partial_name(), should print a list of vm" {
  local -r vm_partial_name='virtualbox'
  create_vm

  run vedv::virtualbox::list_vms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output --partial 'virtualbox'
}

# Tests for vedv::virtualbox::exists_vm_with_partial_name()
@test "vedv::virtualbox::exists_vm_with_partial_name() Should fails If lis_vms_by_partial_name() fails" {
  local -r vm_partial_name="test_vm"

  vedv::virtualbox::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
    return 1
  }

  run vedv::virtualbox::exists_vm_with_partial_name "$vm_partial_name"

  assert_failure
  assert_output 'Failed to get vms list'
}

@test "vedv::virtualbox::exists_vm_with_partial_name() returns true when VM exists" {
  local -r vm_partial_name="test_vm"

  vedv::virtualbox::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
    echo "test_vm"
  }

  run vedv::virtualbox::exists_vm_with_partial_name "$vm_partial_name"

  assert_success
  assert_output true
}

@test "vedv::virtualbox::exists_vm_with_partial_name() returns false when VM does not exist" {
  local -r vm_partial_name="test_vm"

  vedv::virtualbox::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
  }

  run vedv::virtualbox::exists_vm_with_partial_name "$vm_partial_name"

  assert_success
  assert_output false
}

# Tests for vedv::virtualbox::poweroff()
@test "vedv::virtualbox::poweroff(), with 'vm_name' undefined should throw an error" {
  run vedv::virtualbox::poweroff

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::virtualbox::poweroff() should poweroff a vm" {
  local -r __vm_name="$(create_vm)"

  VBoxManage startvm "$__vm_name" --type headless

  run vedv::virtualbox::poweroff "$__vm_name"

  assert_success

  __run_cmd_wrapper() {
    VBoxManage showvminfo --machinereadable "$__vm_name" |
      grep -Pom1 '^VMState="\K\w+(?=")' || :
  }

  run __run_cmd_wrapper

  assert_success
  assert_output 'poweroff'
}

# Tests for vedv::virtualbox::rm()
@test "vedv::virtualbox::rm() Should fail With empty vm_name" {
  local -r __vm_name=""

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output "Argument 'vm_name' is required"
}

@test "vedv::virtualbox::rm() Should fail If is_running fails" {
  local -r __vm_name="image123"

  vedv::virtualbox::is_running() {
    assert_equal "$*" "$__vm_name"
    return 1
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output "Failed to check if vm is running"
}

@test "vedv::virtualbox::rm() Should fail If poweroff fails" {
  local -r __vm_name="image123"

  vedv::virtualbox::is_running() {
    assert_equal "$*" "$__vm_name"
    echo true
  }
  VBoxManage() {
    if [[ "$1" == controlvm ]]; then
      assert_equal "$*" "controlvm image123 poweroff"
      return 1
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output "Failed to poweroff VM image123"
}

@test "vedv::virtualbox::rm() Should fail If showvminfo fails" {
  local -r __vm_name="image123"

  vedv::virtualbox::is_running() {
    assert_equal "$*" "$__vm_name"
    echo false
  }
  VBoxManage() {
    if [[ "$1" == controlvm ]]; then
      assert_equal "$*" "controlvm image123 poweroff"
      return 0
    fi
    if [[ "$1" == showvminfo ]]; then
      assert_equal "$*" "showvminfo image123 --machinereadable"
      return 1
    fi
    command VBoxManage "$@"
  }
  sleep() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output "Failed to get vm info for 'image123'"
}

@test "vedv::virtualbox::rm() Should fail If __get_vms_directory fails" {
  local -r __vm_name="image123"

  vedv::virtualbox::is_running() {
    assert_equal "$*" "$__vm_name"
    echo false
  }
  VBoxManage() {
    if [[ "$1" == controlvm ]]; then
      assert_equal "$*" "INVALID_CALL"
      return 0
    fi
    if [[ "$1" == showvminfo ]]; then
      assert_equal "$*" "showvminfo image123 --machinereadable"
      return 0
    fi
  }
  sleep() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    return 1
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output "Failed to get vbox vms directory"
}

@test "vedv::virtualbox::rm() Should fail If vm_dir is not inside vbox vms directory" {
  local -r __vm_name="$(create_vm)"

  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    echo 'dir'
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output --regexp "VM dir '.*' is not inside 'dir'"
}

@test "vedv::virtualbox::rm() Should fail If unregistervm fails" {
  local -r __vm_name="$(create_vm)"

  VBoxManage() {
    if [[ "$1" == unregistervm ]]; then
      assert_equal "$*" "unregistervm ${vm_name} --delete"
      return 1
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output --regexp "Failed to unregister vm '.*'"
}

@test "vedv::virtualbox::rm() Should fail If __rm fails" {
  local -r __vm_name="$(create_vm)"

  VBoxManage() {
    if [[ "$1" == unregistervm ]]; then
      assert_equal "$*" "unregistervm ${vm_name} --delete"
      command VBoxManage unregistervm "$vm_name"
      return 0
    fi
    command VBoxManage "$@"
  }

  __rm() {
    assert_regex "$*" "-rf .*${__vm_name}.*"
    return 1
  }

  run vedv::virtualbox::rm "$__vm_name"

  assert_failure
  assert_output --regexp "Failed to remove vm dir '.*'"
}

@test "vedv::virtualbox::rm() Should Succeed" {
  local -r __vm_name="$(create_vm)"

  run vedv::virtualbox::rm "$__vm_name"

  assert_success
  assert_output --partial "100%"
}

# Tests for vedv::virtualbox::list()
@test "vedv::virtualbox::list(), Should print all vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  run vedv::virtualbox::list

  assert_success
  assert_output --partial "${vm_name1}
${vm_name2}"
}

@test "vedv::virtualbox::list(), Should print running vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  VBoxManage startvm "$vm_name1" --type headless

  run vedv::virtualbox::list_running

  assert_success
  assert_output --partial "${vm_name1}"
}

# Tests for vedv::virtualbox::show_snapshots()
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

# Tests for vedv::virtualbox::set_description()
@test "vedv::virtualbox::set_description(): Should fail When 'vm_name' is empty" {
  run vedv::virtualbox::set_description "" "Test description"

  assert_failure 69
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::set_description(): Should fail When description is empty" {
  run vedv::virtualbox::set_description 'testvm' ""

  assert_failure 69
  assert_output "Argument 'description' must not be empty"
}

@test "vedv::virtualbox::set_description(): Should fail When 'vm_name' doesn't exist" {
  run vedv::virtualbox::set_description 'testvm' "Test description"

  assert_failure 86
  assert_output --partial "Error setting description, vm: testvm"
}

@test "vedv::virtualbox::set_description() Should succeed" {
  local -r __vm_name="$(create_vm)"
  local -r description="Test description"

  run vedv::virtualbox::set_description "$__vm_name" "$description"

  assert_success
  assert_output ''
  # shellcheck disable=SC2171

  __run_cmd_wrapper() {
    VBoxManage getextradata "$__vm_name" user-data
  }

  run __run_cmd_wrapper

  assert_success
  assert_output "Value: ${description}"
}

# Tests for vedv::virtualbox::get_description()
@test "vedv::virtualbox::get_description(): Should fail When 'vm_name' is empty" {
  run vedv::virtualbox::get_description ""

  assert_failure 69
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::get_description(): Should fail When 'vm_name' doesn't exist" {

  run vedv::virtualbox::get_description "vm_1"

  assert_failure 86
  assert_output --partial "Error getting description of vm: vm_1"
}

@test "vedv::virtualbox::get_description(): Should succeed" {
  (
    VBoxManage() {
      echo 'image_cache=value1 ova_file_sum=value2'
    }

    run vedv::virtualbox::get_description 'vm_name'

    assert_success
    assert_output 'image_cache=value1 ova_file_sum=value2'
  )
}

# Tests for vedv::virtualbox::add_forwarding_port()
@test "vedv::virtualbox::add_forwarding_port(): Should fail With unset vm_name" {
  run vedv::virtualbox::add_forwarding_port "" "rule_name" 8080 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::add_forwarding_port(): Should fail With unset rule_name" {
  run vedv::virtualbox::add_forwarding_port "vm_name" "" 8080 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'rule_name' must not be empty"
}

@test "vedv::virtualbox::add_forwarding_port(): Should fail With unset host_port" {
  run vedv::virtualbox::add_forwarding_port "vm_name" "rule_name" "" 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'host_port' must not be empty"
}

@test "vedv::virtualbox::add_forwarding_port(): Should fail With unset guest_port" {
  run vedv::virtualbox::add_forwarding_port "vm_name" "rule_name" 8080 ""
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'guest_port' must not be empty"
}

@test "vedv::virtualbox::add_forwarding_port(): Should fail With vm_name that doesn't exist" {
  run vedv::virtualbox::add_forwarding_port "vm_name" "rule_name" 8080 8080

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output --partial "Error adding forwarding port, rule name: rule_name"
}

@test "vedv::virtualbox::add_forwarding_port(): Should succeed With correct args" {
  (
    VBoxManage() { :; }

    run vedv::virtualbox::add_forwarding_port "vm_name" "ssh" 2022 22

    assert_success
  )
}

# Tests for vedv::virtualbox::delete_forwarding_port()
@test "vedv::virtualbox::delete_forwarding_port(): Should fail With unset vm_name" {
  run vedv::virtualbox::delete_forwarding_port "" "rule_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::delete_forwarding_port(): Should fail With unset rule_name" {
  run vedv::virtualbox::delete_forwarding_port "vm_name" ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'rule_name' must not be empty"
}

@test "vedv::virtualbox::delete_forwarding_port(): Should fail With vm_name that doesn't exist" {
  run vedv::virtualbox::delete_forwarding_port "vm_name" "rule_name"

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output --partial "Error deleting forwarding port, rule name: rule_name"
}

@test "vedv::virtualbox::delete_forwarding_port(): Should succeed With correct args" {
  (
    VBoxManage() { :; }

    run vedv::virtualbox::delete_forwarding_port "vm_name" "ssh"

    assert_success
  )
}

# Tests for vedv::virtualbox::assign_random_host_forwarding_port()
@test "vedv::virtualbox::assign_random_host_forwarding_port(): Should succeed With correct args" {
  get_a_dynamic_port() { echo 2024; }
  vedv::virtualbox::delete_forwarding_port() { :; }
  vedv::virtualbox::add_forwarding_port() { :; }

  run vedv::virtualbox::assign_random_host_forwarding_port "vm_name" "ssh" 22

  assert_success
  assert_output 2024
}

@test "vedv::virtualbox::restore_snapshot(): NO TEST" {
  :
}

@test "vedv::virtualbox::remove_inaccessible_hdds(): TEST" {
  skip
  local create_m_out=''
  for i in {1..3}; do
    create_m_out+="$(VBoxManage createmedium --filename "/tmp/disk${i}.vmdk" --size 1024 2>/dev/null)\n"
  done

  for i in {1..2}; do
    rm -f "/tmp/disk${i}.vmdk"
  done

  run vedv::virtualbox::remove_inaccessible_hdds

  VBoxManage closemedium "/tmp/disk3.vmdk" --delete 2>/dev/null

  assert_success
  assert_output "$(echo -e "$create_m_out" | sed 's/.*UUID:\s\+//' | head -n 2)"
}

# Tests for vedv::virtualbox::get_forwarding_ports()

@test "vedv::virtualbox::get_forwarding_ports(): Should fail With empty vm_name" {
  local -r __vm_name=""

  run vedv::virtualbox::get_forwarding_ports "$__vm_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::get_forwarding_ports(): Should fail With vm_name that doesn't exist" {
  local -r __vm_name="vm_name"

  VBoxManage() {
    return 1
  }

  run vedv::virtualbox::get_forwarding_ports "$__vm_name"

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output "Error getting forwarding ports of vm: vm_name"
}

@test "vedv::virtualbox::get_forwarding_ports(): Should succeed" {
  local -r __vm_name="vm_name"

  VBoxManage() {
    cat <<'EOF'
Forwarding(0)="ssh,tcp,,2022,,22"
Forwarding(1)="http,tcp,,8080,,80"
EOF
  }

  run vedv::virtualbox::get_forwarding_ports "$__vm_name"

  assert_success
  assert_output 'ssh,tcp,,2022,,22
http,tcp,,8080,,80'
}

# Tests for vedv::virtualbox::start()

@test "vedv::virtualbox::start(): Should fail With empty vm_name" {
  local -r __vm_name=""

  run vedv::virtualbox::start "$__vm_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::start(): Should fail With vm_name that doesn't exist" {
  local -r __vm_name="vm_name1"

  VBoxManage() {
    # assert_equal "$*" "startvm vm_name1 --type headless"
    return 1
  }

  run vedv::virtualbox::start "$__vm_name"

  assert_failure
  assert_output "Failed to start VM ${__vm_name}"
}

@test "vedv::virtualbox::start(): Should succeed" {
  local -r __vm_name="vm_name1"
  local -r show_gui='true'

  VBoxManage() {
    # assert_equal "$*" "startvm vm_name1 --type gui"
    :
  }

  run vedv::virtualbox::start "$__vm_name" "$show_gui"

  assert_success
  assert_output ""
}

# Tests for vedv::virtualbox::export()
@test "vedv::virtualbox::export() Should fail With empty vm_name" {
  local -r __vm_name=""
  local -r ova_file=""
  local -r exported_vm_name=""

  run vedv::virtualbox::export "$__vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Argument 'vm_name' is required"
}

@test "vedv::virtualbox::export() Should fail With empty ova_file" {
  local -r __vm_name="image123"
  local -r ova_file=""
  local -r exported_vm_name=""

  run vedv::virtualbox::export "$__vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Argument 'ova_file' is required"
}

@test "vedv::virtualbox::export() Should fail If is_running fails" {
  local -r __vm_name="image123"
  local -r ova_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r exported_vm_name=""

  vedv::virtualbox::is_running() {
    assert_equal "$*" "image123"
    return 1
  }

  run vedv::virtualbox::export "$__vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Failed to check if vm is running"
}

@test "vedv::virtualbox::export() Should succeed" {
  local -r __vm_name="image123-export"
  local -r ova_file="${TEST_IMAGE_TMP_DIR}/image123-export.ova"
  local -r exported_vm_name="exported_vm_name"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$__vm_name" &>/dev/null

  run vedv::virtualbox::export "$__vm_name" "$ova_file" "$exported_vm_name"

  assert_success
  assert_output ""

  assert [ -f "$ova_file" ]
}

# Tests for vedv::virtualbox::modifyvm()
@test "vedv::virtualbox::modifyvm(): Should fail With empty vm_name" {
  local -r __vm_name=""
  local -ri cpus=""
  local -ri memory=""

  run vedv::virtualbox::modifyvm "$__vm_name" "$cpus" "$memory"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::modifyvm(): Should succeed If cpus and memory are empty" {
  local -r __vm_name="vm_name"
  local -ri cpus=""
  local -ri memory=""

  run vedv::virtualbox::modifyvm "$__vm_name" "$cpus" "$memory"

  assert_success
  assert_output ""
}

@test "vedv::virtualbox::modifyvm(): Should fail If modifyvm fails" {
  local -r __vm_name="vm_name"
  local -ri cpus=2
  local -ri memory=512

  VBoxManage() {
    if [[ "$1" == "modifyvm" ]]; then
      return 1
    fi
  }

  run vedv::virtualbox::modifyvm "$__vm_name" "$cpus" "$memory"

  assert_failure
  assert_output "Error modifying vm: vm_name"
}

@test "vedv::virtualbox::modifyvm(): Should succeed" {
  local -r __vm_name="image123-modifyvm"
  local -ri cpus=3
  local -ri memory=740

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$__vm_name" &>/dev/null

  VBoxManage() {
    if [[ "$1" == "modifyvm" ]]; then
      assert_equal "$*" "modifyvm image123 --cpus 3 --memory 740"
    fi
    command VBoxManage "$@"
  }

  run vedv::virtualbox::modifyvm "$__vm_name" "$cpus" "$memory"

  assert_success
  assert_output ""

  run VBoxManage showvminfo --machinereadable "$__vm_name"

  assert_success
  assert_output --regexp "cpus=${cpus}"
  assert_output --regexp "memory=${memory}"
}

@test "vedv::virtualbox::get_state(): Should fail With empty vm_name" {
  local -r __vm_name=""

  run vedv::virtualbox::get_state "$__vm_name"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::get_state() Should succeed" {
  local -r __vm_name="image123"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$__vm_name" &>/dev/null || :

  run vedv::virtualbox::get_state "$__vm_name"

  assert_success
  assert_output "poweroff"

  VBoxManage startvm "$__vm_name" --type "headless" &>/dev/null

  run vedv::virtualbox::get_state "$__vm_name"

  assert_success
  assert_output "running"

  VBoxManage controlvm "$__vm_name" savestate

  run vedv::virtualbox::get_state "$__vm_name"

  assert_success
  assert_output "saved"
}

# Tests for vedv::virtualbox::__get_vms_directory()
@test "vedv::virtualbox::__get_vms_directory(): Should fail If 'vbox_vms_dir' is empty" {
  VBoxManage() {
    if [[ "$1" == list && "$2" == systemproperties ]]; then
      return 1
    fi
  }

  run vedv::virtualbox::__get_vms_directory

  assert_failure
  assert_output "'vbox_vms_dir' is empty"
}

@test "vedv::virtualbox::__get_vms_directory(): Should fail If 'vbox_vms_dir' doesn't exist" {
  VBoxManage() {
    echo 'Default machine folder: /tmp/8572b40c643a7c56412a'
  }

  run vedv::virtualbox::__get_vms_directory

  assert_failure
  assert_output "VirtualBox VMs directory '/tmp/8572b40c643a7c56412a' doesn't exist"
}

@test "vedv::virtualbox::__get_vms_directory(): Should succeed" {

  run vedv::virtualbox::__get_vms_directory

  assert_success
  assert [ -d "$output" ]
}

# Tests for vedv::virtualbox::vedv::virtualbox::__vm_name_to_vm_dirname()()
@test "vedv::virtualbox::__vm_name_to_vm_dirname(): Should fail If 'vm_name' is empty" {
  local -r __vm_name=""

  run vedv::virtualbox::__vm_name_to_vm_dirname "$__vm_name"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::__vm_name_to_vm_dirname(): Should succeed" {
  local -r __vm_name="image-cache|crc:1980169285|"

  run vedv::virtualbox::__vm_name_to_vm_dirname "$__vm_name"

  assert_success
  assert_output "image-cache_crc_1980169285_"
}

# Tests for vedv::virtualbox::__remove_vm_existing_directory()
@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail With empty vm_name" {
  local -r __vm_name=""

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If exists_vm_with_partial_name fails" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    return 1
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Failed to check if vm exists image:image123|crc:1980169285|"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If vm exists" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo true
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "VM 'image:image123|crc:1980169285|' already exists"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If __get_vms_directory fails" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    return 1
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Failed to get vbox vms directory"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If 'vbox_vms_directory' is empty" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "'vbox_vms_directory' is empty"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If 'vbox_vms_directory' doesn't exist" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    echo '/tmp/8572b40c643a7c56412a'
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Virtualbox VMs '/tmp/8572b40c643a7c56412a' doesn't exist"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If __vm_name_to_vm_dirname fails" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    mktemp -d
  }

  vedv::virtualbox::__vm_name_to_vm_dirname() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    return 1
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Failed to calc vm directory for vm 'image:image123|crc:1980169285|'"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If 'vm_directory_name' is empty" {
  local -r __vm_name="image:image123|crc:1980169285|"

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    mktemp -d
  }
  vedv::virtualbox::__vm_name_to_vm_dirname() {
    assert_equal "$*" "image:image123|crc:1980169285|"
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "'vm_directory_name' is empty"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should succeed if vm_directory doesn't exist" {
  local -r __vm_name="image:image123|crc:1980169285|"

  declare -rx VBOX_VMS_DIRECTORY="$(mktemp -d)"
  declare -rx VM_DIRECTORY_NAME='image-image123_crc_1980169285_'

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    echo "$VBOX_VMS_DIRECTORY"
  }
  vedv::virtualbox::__vm_name_to_vm_dirname() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo "$VM_DIRECTORY_NAME"
  }
  __rm() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_success
  assert_output ""
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should fail If __rm fails" {
  local -r __vm_name="image:image123|crc:1980169285|"

  declare -rx VBOX_VMS_DIRECTORY="$(mktemp -d)"
  declare -rx VM_DIRECTORY_NAME='image-image123_crc_1980169285_'

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    echo "$VBOX_VMS_DIRECTORY"
  }
  vedv::virtualbox::__vm_name_to_vm_dirname() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    mkdir -p "${VBOX_VMS_DIRECTORY}/${VM_DIRECTORY_NAME}"
    echo "$VM_DIRECTORY_NAME"
  }
  __rm() {
    assert_equal "$*" "-rf ${VBOX_VMS_DIRECTORY}/${VM_DIRECTORY_NAME}"
    return 1
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_failure
  assert_output "Failed to remove directory of VM 'image:image123|crc:1980169285|'"
}

@test "vedv::virtualbox::__remove_vm_existing_directory() Should succeed" {
  local -r __vm_name="image:image123|crc:1980169285|"

  declare -rx VBOX_VMS_DIRECTORY="$(mktemp -d)"
  declare -rx VM_DIRECTORY_NAME='image-image123_crc_1980169285_'

  vedv::virtualbox::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    echo false
  }
  vedv::virtualbox::__get_vms_directory() {
    assert_equal "$*" ""
    echo "$VBOX_VMS_DIRECTORY"
  }
  vedv::virtualbox::__vm_name_to_vm_dirname() {
    assert_equal "$*" "image:image123|crc:1980169285|"
    mkdir -p "${VBOX_VMS_DIRECTORY}/${VM_DIRECTORY_NAME}"
    echo "$VM_DIRECTORY_NAME"
  }
  __rm() {
    assert_equal "$*" "-rf ${VBOX_VMS_DIRECTORY}/${VM_DIRECTORY_NAME}"
  }

  run vedv::virtualbox::__remove_vm_existing_directory "$__vm_name"

  assert_success
  assert_output "removed: ${VBOX_VMS_DIRECTORY}/${VM_DIRECTORY_NAME}"
}
