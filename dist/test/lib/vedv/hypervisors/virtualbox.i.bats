# shellcheck disable=SC2016,SC2317
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

# Tests for vedv::hypervisor::validate_vm_name()
@test "vedv::hypervisor::validate_vm_name(), should be short name" {
  local -r vm_name='1234'

  run vedv::hypervisor::validate_vm_name "$vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be shorter than 5 characters'
}

@test "vedv::hypervisor::validate_vm_name(), should be large name" {
  local -r vm_name="$(printf 'n%.0s' {1..61})"

  run vedv::hypervisor::validate_vm_name "$vm_name"

  assert_failure 69
  assert_output 'The vm name cannot be longer than 60 characters'
}

@test "vedv::hypervisor::validate_vm_name(), should be ok" {
  local -r vm_name="$(printf 'n%.0s' {1..60})"

  run vedv::hypervisor::validate_vm_name "$vm_name"

  assert_success
  assert_output ''
}

# Tests for vedv::hypervisor::import()
@test "vedv::hypervisor::import(), with 'ova_file' undefined should return error" {
  run vedv::hypervisor::import

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::hypervisor::import(), with 'vm_name' undefined should return error" {
  local -r ova_file="/tmp/${RANDOM}${RANDOM}.ova"

  run vedv::hypervisor::import "$ova_file"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::hypervisor::import(), with 'ova_file' that doesnt't exist should return error" {
  local -r ova_file="/tmp/feacd213baf31d50798a.ova"
  local -r vm_name="alpine-feacd213baf31d50798a"

  run vedv::hypervisor::import "$ova_file" "$vm_name"

  assert_failure 64
  assert_output "OVA file doesn't exist"
}

@test "vedv::hypervisor::import(), should import a vm from ova" {
  local -r ova_file="$TEST_OVA_FILE"
  local -r vm_name="$(gen_vm_name)"

  run vedv::hypervisor::import "$ova_file" "$vm_name"

  assert_success

  run VBoxManage list vms

  assert_output --partial "$vm_name"
}

# Tests for vedv::hypervisor::take_snapshot()
@test "vedv::hypervisor::take_snapshot(), with 'vm_name' undefined should return error" {
  run vedv::hypervisor::take_snapshot

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::hypervisor::take_snapshot(), with 'snapshot_name' undefined should return error" {
  local -r vm_name="vm1"

  run vedv::hypervisor::take_snapshot "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::hypervisor::take_snapshot(), should create a snapshot" {
  local -r vm_name="$(create_vm)"
  local -r snapshot_name="snapshot1"

  run vedv::hypervisor::take_snapshot "$vm_name" "$snapshot_name"

  assert_success
  assert_output --partial "Snapshot taken"
}
# Tests for vedv::hypervisor::clonevm()
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should fail with invalid vm_name" {
  local -r vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The vm_name name cannot be shorter than 5 characters"
}
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should fail with invalid vm_clone_name" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='vmc'

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The clone_vm_name name cannot be shorter than 5 characters"
}
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should fail If clonevm fails" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --snapshot snapshot1"
      return 1
    fi
  }

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1' from snapshot 'snapshot1'"
}
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should succeed" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --snapshot snapshot1"
    fi
  }

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should fail If clonevm fails without snapshot" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot=''

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register"
      return 1
    fi
  }

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}
# bats test_tags=only
@test "vedv::hypervisor::clonevm() Should succeed without snapshot" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot=''

  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register"
    fi
  }

  run vedv::hypervisor::clonevm "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}
# Tests for vedv::hypervisor::clonevm_link()
@test "vedv::hypervisor::clonevm_link(), with 'vm_name' undefined should return error" {
  run vedv::hypervisor::clonevm_link

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::hypervisor::clonevm_link(), with 'vm_clone_name' undefined should return error" {
  local -r vm_name='vm'
  run vedv::hypervisor::clonevm_link "$vm_name"

  assert_failure 1
  assert_output --partial '$2: unbound variable'
}

@test "vedv::hypervisor::clonevm_link(), with a 'vm_name' that doesn't exist should return error" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='vm_clone'

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name"

  assert_failure
  assert_output --partial "Could not find a registered machine named 'vm_name1'"
}

@test "vedv::hypervisor::clonevm_link(), should clone the vm" {
  local -r vm_name="$(create_vm)"
  # shellcheck disable=SC2119
  local -r vm_clone_name="$(gen_vm_clone_name)"

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name"

  assert_success
  assert_output --partial "Machine has been successfully cloned"
}

@test "vedv::hypervisor::clonevm_link() Should fail with invalid vm_name" {
  local -r vm_name='vm'
  local -r vm_clone_name='vm_clone'

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The vm_name name cannot be shorter than 5 characters"
}

@test "vedv::hypervisor::clonevm_link() Should fail with invalid vm_clone_name" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='vmc'

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name"

  assert_failure
  assert_output "The clone_vm_name name cannot be shorter than 5 characters"
}

@test "vedv::hypervisor::clonevm_link() Should fail If take_snapshot fails" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
    return 1
  }

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to create snapshot '${vm_clone_name}'"
}

@test "vedv::hypervisor::clonevm_link() Should fail If clonevm fails" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
    return 1
  }

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to delete snapshot 'clone_name1'
Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::hypervisor::clonevm_link() Should fail If clonevm fails 2" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::hypervisor::clonevm_link() Should fail With create_snapshot=false and clonevm fails" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='false'

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
      return 1
    fi
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name" "$vm_snapshot" "$create_snapshot"

  assert_failure
  assert_output "Failed to clone VM 'vm_name1' to 'clone_name1'"
}

@test "vedv::hypervisor::clonevm_link() Should succeed" {
  local -r vm_name='vm_name1'
  local -r vm_clone_name='clone_name1'
  local -r vm_snapshot='snapshot1'
  local -r create_snapshot='true'

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "vm_name1 clone_name1"
  }
  VBoxManage() {
    if [[ "$1" == 'clonevm' ]]; then
      assert_equal "$*" "clonevm vm_name1 --name clone_name1 --register --options link --snapshot snapshot1"
    fi
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::hypervisor::clonevm_link "$vm_name" "$vm_clone_name" "$vm_snapshot"

  assert_success
  assert_output ""
}
# Tests for vedv::hypervisor::list_vms_by_partial_name()
@test "vedv::hypervisor::list_vms_by_partial_name, with 'vm_partial_name()' that doesn't exist should print an empty list" {
  local -r vm_partial_name='container:happy'

  run vedv::hypervisor::list_vms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output ''
}

@test "vedv::hypervisor::list_vms_by_partial_name(), should print a list of vm" {
  local -r vm_partial_name='virtualbox'
  create_vm

  run vedv::hypervisor::list_vms_by_partial_name "$vm_partial_name"

  assert_success
  assert_output --partial 'virtualbox'
}

# Tests for vedv::hypervisor::exists_vm_with_partial_name()
@test "vedv::hypervisor::exists_vm_with_partial_name() Should fails If lis_vms_by_partial_name() fails" {
  local -r vm_partial_name="test_vm"

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
    return 1
  }

  run vedv::hypervisor::exists_vm_with_partial_name "$vm_partial_name"

  assert_failure
  assert_output 'Failed to get vms list'
}

@test "vedv::hypervisor::exists_vm_with_partial_name() returns true when VM exists" {
  local -r vm_partial_name="test_vm"

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
    echo "test_vm"
  }

  run vedv::hypervisor::exists_vm_with_partial_name "$vm_partial_name"

  assert_success
  assert_output true
}

@test "vedv::hypervisor::exists_vm_with_partial_name() returns false when VM does not exist" {
  local -r vm_partial_name="test_vm"

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$1" "test_vm"
  }

  run vedv::hypervisor::exists_vm_with_partial_name "$vm_partial_name"

  assert_success
  assert_output false
}

# Tests for vedv::hypervisor::poweroff()
@test "vedv::hypervisor::poweroff(), with 'vm_name' undefined should throw an error" {
  run vedv::hypervisor::poweroff

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::hypervisor::poweroff(), should poweroff a vm" {
  skip # this test is problematic
  local -r vm_name="$(create_vm)"
  VBoxManage startvm "$vm_name"

  run vedv::hypervisor::poweroff "$vm_name"

  assert_success
  assert_output --partial '<put the output here>'
}

# Tests for vedv::hypervisor::rm()
@test "vedv::hypervisor::rm(), with 'vm_name' undefined should throw an error" {
  run vedv::hypervisor::rm

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::hypervisor::rm(), Should remove the vm" {
  local -r vm_name="$(create_vm)"

  vedv::hypervisor::remove_inaccessible_hdds() {
    return 0
  }

  run vedv::hypervisor::rm "$vm_name"

  assert_success
}

# Tests for vedv::hypervisor::list()
@test "vedv::hypervisor::list(), Should print all vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  run vedv::hypervisor::list

  assert_success
  assert_output --partial "${vm_name1}
${vm_name2}"
}

@test "vedv::hypervisor::list(), Should print running vms" {
  local -r vm_name1="$(create_vm)"
  local -r vm_name2="$(create_vm)"

  VBoxManage startvm "$vm_name1" --type headless

  run vedv::hypervisor::list_running

  assert_success
  assert_output --partial "${vm_name1}"
}

# Tests for vedv::hypervisor::show_snapshots()
@test "vedv::hypervisor::show_snapshots(), Should print no snapshots" {
  local -r vm_name1="$(create_vm)"

  run vedv::hypervisor::show_snapshots "$vm_name1"

  assert_success
  assert_output ''
}

@test "vedv::hypervisor::show_snapshots(), Should print snapshots" {
  local -r vm_name1="$(create_vm)"
  local -r snapshot_name1="snapshot1"
  local -r snapshot_name2="snapshot2"

  VBoxManage snapshot "$vm_name1" take "$snapshot_name1"
  VBoxManage snapshot "$vm_name1" take "$snapshot_name2"
  run vedv::hypervisor::show_snapshots "$vm_name1"

  assert_success
  assert_output "${snapshot_name1}
${snapshot_name2}"
}

# Tests for vedv::hypervisor::set_description()
@test "vedv::hypervisor::set_description(): Should fail When 'vm_name' is empty" {
  run vedv::hypervisor::set_description "" "Test description"

  assert_failure 69
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::set_description(): Should fail When description is empty" {
  run vedv::hypervisor::set_description 'testvm' ""

  assert_failure 69
  assert_output "Argument 'description' must not be empty"
}

@test "vedv::hypervisor::set_description(): Should fail When 'vm_name' doesn't exist" {
  run vedv::hypervisor::set_description 'testvm' "Test description"

  assert_failure 86
  assert_output --partial "Error setting description, vm: testvm"
}

@test "vedv::hypervisor::set_description(): Should succeed" {
  local -r vm_name="$(create_vm)"
  local -r description="Test description"

  run vedv::hypervisor::set_description "$vm_name" "Test description"

  assert_success
  assert_output ''
  # shellcheck disable=SC2171
  assert [ VBoxManage showvminfo "$vm_name" | grep -q "$description" ]
}

# Tests for vedv::hypervisor::get_description()
@test "vedv::hypervisor::get_description(): Should fail When 'vm_name' is empty" {
  run vedv::hypervisor::get_description ""

  assert_failure 69
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::get_description(): Should fail When 'vm_name' doesn't exist" {

  run vedv::hypervisor::get_description "vm_1"

  assert_failure 86
  assert_output --partial "Error getting description of vm: vm_1"
}

@test "vedv::hypervisor::get_description(): Should succeed" {
  (
    VBoxManage() {
      echo 'image_cache=value1 ova_file_sum=value2'
    }

    run vedv::hypervisor::get_description 'vm_name'

    assert_success
    assert_output 'image_cache=value1 ova_file_sum=value2'
  )
}

# Tests for vedv::hypervisor::add_forwarding_port()
@test "vedv::hypervisor::add_forwarding_port(): Should fail With unset vm_name" {
  run vedv::hypervisor::add_forwarding_port "" "rule_name" 8080 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::add_forwarding_port(): Should fail With unset rule_name" {
  run vedv::hypervisor::add_forwarding_port "vm_name" "" 8080 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'rule_name' must not be empty"
}

@test "vedv::hypervisor::add_forwarding_port(): Should fail With unset host_port" {
  run vedv::hypervisor::add_forwarding_port "vm_name" "rule_name" "" 8080

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'host_port' must not be empty"
}

@test "vedv::hypervisor::add_forwarding_port(): Should fail With unset guest_port" {
  run vedv::hypervisor::add_forwarding_port "vm_name" "rule_name" 8080 ""
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'guest_port' must not be empty"
}

@test "vedv::hypervisor::add_forwarding_port(): Should fail With vm_name that doesn't exist" {
  run vedv::hypervisor::add_forwarding_port "vm_name" "rule_name" 8080 8080

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output --partial "Error adding forwarding port, rule name: rule_name"
}

@test "vedv::hypervisor::add_forwarding_port(): Should succeed With correct args" {
  (
    VBoxManage() { :; }

    run vedv::hypervisor::add_forwarding_port "vm_name" "ssh" 2022 22

    assert_success
  )
}

# Tests for vedv::hypervisor::delete_forwarding_port()
@test "vedv::hypervisor::delete_forwarding_port(): Should fail With unset vm_name" {
  run vedv::hypervisor::delete_forwarding_port "" "rule_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::delete_forwarding_port(): Should fail With unset rule_name" {
  run vedv::hypervisor::delete_forwarding_port "vm_name" ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'rule_name' must not be empty"
}

@test "vedv::hypervisor::delete_forwarding_port(): Should fail With vm_name that doesn't exist" {
  run vedv::hypervisor::delete_forwarding_port "vm_name" "rule_name"

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output --partial "Error deleting forwarding port, rule name: rule_name"
}

@test "vedv::hypervisor::delete_forwarding_port(): Should succeed With correct args" {
  (
    VBoxManage() { :; }

    run vedv::hypervisor::delete_forwarding_port "vm_name" "ssh"

    assert_success
  )
}

# Tests for vedv::hypervisor::assign_random_host_forwarding_port()
@test "vedv::hypervisor::assign_random_host_forwarding_port(): Should succeed With correct args" {
  get_a_dynamic_port() { echo 2024; }
  vedv::hypervisor::delete_forwarding_port() { :; }
  vedv::hypervisor::add_forwarding_port() { :; }

  run vedv::hypervisor::assign_random_host_forwarding_port "vm_name" "ssh" 22

  assert_success
  assert_output 2024
}

@test "vedv::hypervisor::restore_snapshot(): NO TEST" {
  :
}

@test "vedv::hypervisor::remove_inaccessible_hdds(): TEST" {
  skip
  local create_m_out=''
  for i in {1..3}; do
    create_m_out+="$(VBoxManage createmedium --filename "/tmp/disk${i}.vmdk" --size 1024 2>/dev/null)\n"
  done

  for i in {1..2}; do
    rm -f "/tmp/disk${i}.vmdk"
  done

  run vedv::hypervisor::remove_inaccessible_hdds

  VBoxManage closemedium "/tmp/disk3.vmdk" --delete 2>/dev/null

  assert_success
  assert_output "$(echo -e "$create_m_out" | sed 's/.*UUID:\s\+//' | head -n 2)"
}

# Tests for vedv::hypervisor::get_forwarding_ports()

@test "vedv::hypervisor::get_forwarding_ports(): Should fail With empty vm_name" {
  local -r vm_name=""

  run vedv::hypervisor::get_forwarding_ports "$vm_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::get_forwarding_ports(): Should fail With vm_name that doesn't exist" {
  local -r vm_name="vm_name"

  VBoxManage() {
    return 1
  }

  run vedv::hypervisor::get_forwarding_ports "$vm_name"

  assert_failure "$ERR_VIRTUALBOX_OPERATION"
  assert_output "Error getting forwarding ports of vm: vm_name"
}

@test "vedv::hypervisor::get_forwarding_ports(): Should succeed" {
  local -r vm_name="vm_name"

  VBoxManage() {
    cat <<'EOF'
Forwarding(0)="ssh,tcp,,2022,,22"
Forwarding(1)="http,tcp,,8080,,80"
EOF
  }

  run vedv::hypervisor::get_forwarding_ports "$vm_name"

  assert_success
  assert_output 'ssh,tcp,,2022,,22
http,tcp,,8080,,80'
}

# Tests for vedv::hypervisor::start()

@test "vedv::hypervisor::start(): Should fail With empty vm_name" {
  local -r vm_name=""

  run vedv::hypervisor::start "$vm_name"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::start(): Should fail With vm_name that doesn't exist" {
  local -r vm_name="vm_name1"

  VBoxManage() {
    # assert_equal "$*" "startvm vm_name1 --type headless"
    return 1
  }

  run vedv::hypervisor::start "$vm_name"

  assert_failure
  assert_output "Failed to start VM ${vm_name}"
}

@test "vedv::hypervisor::start(): Should succeed" {
  local -r vm_name="vm_name1"
  local -r show_gui='true'

  VBoxManage() {
    # assert_equal "$*" "startvm vm_name1 --type gui"
    :
  }

  run vedv::hypervisor::start "$vm_name" "$show_gui"

  assert_success
  assert_output ""
}

# Tests for vedv::hypervisor::export()
@test "vedv::hypervisor::export() Should fail With empty vm_name" {
  local -r vm_name=""
  local -r ova_file=""
  local -r exported_vm_name=""

  run vedv::hypervisor::export "$vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Argument 'vm_name' is required"
}

@test "vedv::hypervisor::export() Should fail With empty ova_file" {
  local -r vm_name="image123"
  local -r ova_file=""
  local -r exported_vm_name=""

  run vedv::hypervisor::export "$vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Argument 'ova_file' is required"
}

@test "vedv::hypervisor::export() Should fail If is_running fails" {
  local -r vm_name="image123"
  local -r ova_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r exported_vm_name=""

  vedv::hypervisor::is_running() {
    assert_equal "$*" "image123"
    return 1
  }

  run vedv::hypervisor::export "$vm_name" "$ova_file" "$exported_vm_name"

  assert_failure
  assert_output "Failed to check if vm is running"
}

@test "vedv::hypervisor::export() Should succeed" {
  local -r vm_name="image123"
  local -r ova_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r exported_vm_name="exported_vm_name"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$vm_name" &>/dev/null

  run vedv::hypervisor::export "$vm_name" "$ova_file" "$exported_vm_name"

  assert_success
  assert_output ""

  assert [ -f "$ova_file" ]
}

# Tests for vedv::hypervisor::modifyvm()
@test "vedv::hypervisor::modifyvm(): Should fail With empty vm_name" {
  local -r vm_name=""
  local -ri cpus=""
  local -ri memory=""

  run vedv::hypervisor::modifyvm "$vm_name" "$cpus" "$memory"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::modifyvm(): Should succeed If cpus and memory are empty" {
  local -r vm_name="vm_name"
  local -ri cpus=""
  local -ri memory=""

  run vedv::hypervisor::modifyvm "$vm_name" "$cpus" "$memory"

  assert_success
  assert_output ""
}

@test "vedv::hypervisor::modifyvm(): Should fail If modifyvm fails" {
  local -r vm_name="vm_name"
  local -ri cpus=2
  local -ri memory=512

  VBoxManage() {
    if [[ "$1" == "modifyvm" ]]; then
      return 1
    fi
  }

  run vedv::hypervisor::modifyvm "$vm_name" "$cpus" "$memory"

  assert_failure
  assert_output "Error modifying vm: vm_name"
}

@test "vedv::hypervisor::modifyvm(): Should succeed" {
  local -r vm_name="image123"
  local -ri cpus=3
  local -ri memory=740

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$vm_name" &>/dev/null

  VBoxManage() {
    if [[ "$1" == "modifyvm" ]]; then
      assert_equal "$*" "modifyvm image123 --cpus 3 --memory 740"
    fi
    command VBoxManage "$@"
  }

  run vedv::hypervisor::modifyvm "$vm_name" "$cpus" "$memory"

  assert_success
  assert_output ""

  run VBoxManage showvminfo --machinereadable image123

  assert_success
  assert_output --regexp "cpus=${cpus}"
  assert_output --regexp "memory=${memory}"
}

@test "vedv::hypervisor::get_state(): Should fail With empty vm_name" {
  local -r vm_name=""

  run vedv::hypervisor::get_state "$vm_name"

  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::hypervisor::get_state(): Should succeed" {
  skip
  local -r vm_name="image123"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$vm_name" &>/dev/null || :

  run vedv::hypervisor::get_state "$vm_name"

  assert_success
  assert_output ""

  VBoxManage startvm "$vm_name" --type "headless" &>/dev/null

  run vedv::hypervisor::get_state "$vm_name"

  assert_success
  assert_output ""

  VBoxManage controlvm "$vm_name" savestate

  run vedv::hypervisor::get_state "$vm_name"

  assert_success
  assert_output ""

  VBoxManage startvm "$vm_name" --type "headless" &>/dev/null
  VBoxManage controlvm "$vm_name" poweroff &>/dev/null

  run vedv::hypervisor::get_state "$vm_name"

  assert_success
  assert_output ""
}
