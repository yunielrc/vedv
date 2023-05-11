# shellcheck disable=SC2317

load test_helper

setup_file() {
  vedv::vmobj_entity::constructor \
    'container|image' \
    '([image]="image_cache|ova_file_sum|ssh_port|user_name" [container]="parent_vmobj_id|ssh_port|user_name")'
  export __VEDV_VMOBJ_ENTITY_TYPE
  export __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR

  vedv::vmobj_service::constructor \
    "$TEST_SSH_IP" \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD"
  export __VEDV_VMOBJ_SERVICE_SSH_IP
  export __VEDV_VMOBJ_SERVICE_SSH_USER
  export __VEDV_VMOBJ_SERVICE_SSH_PASSWORD

}

# Tests for vedv::vmobj_service::is_started()

@test "vedv::vmobj_service::is_started() Should fail With invalid 'type' argument" {
  local -r type="invalid"
  local -r vmobj_id=""

  run vedv::vmobj_service::is_started "$type" "$vmobj_id"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::is_started() Should fail If 'vmobj_id' is empty" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::is_started "$type" "$vmobj_id"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vmobj_id' is required"
}

@test "vedv::vmobj_service::is_started() Should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="1234"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 1234'
    return 1
  }

  run vedv::vmobj_service::is_started "$type" "$vmobj_id"

  assert_failure "$ERR_VMOBJ_OPERATION"
  assert_output "Failed to get vm name for container: '1234'"
}

@test "vedv::vmobj_service::is_started() Should fail If is_running fails" {
  local -r type="container"
  local -r vmobj_id="1234"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 1234'
    echo 'container:foo-foo|crc:1234|'
  }
  vedv::hypervisor::is_running() {
    assert_equal "$*" 'container:foo-foo|crc:1234|'
    return 1
  }

  run vedv::vmobj_service::is_started "$type" "$vmobj_id"

  assert_failure "$ERR_HYPERVISOR_OPERATION"
  assert_output "Failed to check if is running vm: 'container:foo-foo|crc:1234|'"
}

@test "vedv::vmobj_service::is_started() Should succeed" {
  local -r type="container"
  local -r vmobj_id="1234"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 1234'
    echo 'container:foo-foo|crc:1234|'
  }
  vedv::hypervisor::is_running() {
    assert_equal "$*" 'container:foo-foo|crc:1234|'
    echo true
  }

  run vedv::vmobj_service::is_started "$type" "$vmobj_id"

  assert_success
  assert_output 'true'
}

# Tests for vedv::vmobj_service::get_ids_from_vmobj_names_or_ids()

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should fail With invalid type" {
  local -r type='invalid'
  local -r vmobj_ids_or_names='name1 id1 name2 id2'
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" $vmobj_ids_or_names

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should fail With empty ids_or_names" {
  local -r type='container'
  local -r vmobj_ids_or_names=''
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" $vmobj_ids_or_names

  assert_failure
  assert_output 'At least one container is required'
}

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should fail If get_id_by_vmobj_name fails" {
  local -r type='container'
  local -r vmobj_ids_or_names='name1 id1 name2 id2'

  vedv::vmobj_entity::get_id_by_vmobj_name() {
    assert_regex "$*" 'container (name1|id1|name2|id2)'
    return 1
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" $vmobj_ids_or_names

  assert_failure
  assert_output "name1 id1 name2 id2
Error getting vmobj id for containers: 'name1' 'id1' 'name2' 'id2' "
}

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should succeed" {
  local -r type='container'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  vedv::vmobj_entity::get_id_by_vmobj_name() {
    assert_regex "$*" 'container\s+(name1|id2|name3|id4)'

    case "$2" in
    name1)
      echo 'id1'
      ;;
    name3)
      echo 'id3'
      ;;
    *)
      echo "$2"
      ;;
    esac
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" $vmobj_ids_or_names

  assert_success
  assert_output "id1 id2 id3 id4"
}

# Tests for vedv::vmobj_service::exec_func_on_many_vmobjs()

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail With invalid type" {
  local -r type='invalid'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" $vmobj_ids_or_names

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail With empty exec_func" {
  local -r type='container'
  local -r exec_func=''
  local -r vmobj_ids_or_names='name1 id2 name3 id4'
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" $vmobj_ids_or_names

  assert_failure
  assert_output "Invalid argument 'exec_func': it's empty"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail If __get_ids_from_vmobj_names_or_ids fails" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" 'container name1 id2 name3 id4'
    return 1
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" $vmobj_ids_or_names

  assert_failure
  assert_output "Error getting vmobj ids"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail If exec_func fails" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  func1() {
    assert_regex "$*" '(id1|id2|id3|id4)'
    return 1
  }

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" 'container name1 id2 name3 id4'
    echo 'id1 id2 id3 id4'
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" $vmobj_ids_or_names

  assert_failure
  assert_output "Failed to execute function on containers: 'id1''id2''id3''id4'"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should succeed" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  func1() {
    assert_regex "$*" '(id1|id2|id3|id4)'
  }

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" 'container name1 id2 name3 id4'
    echo 'id1 id2 id3 id4'
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" $vmobj_ids_or_names

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::start_one()

@test "vedv::vmobj_service::start_one() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::start_one() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r vmobj_id=""
  local -r wait_for_ssh=true

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::start_one() Should fail if is_started fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Failed to get start status for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should succeed If vm is already started" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::start_one() Should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If vm_name is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "There is no vm name for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If assign_random_host_forwarding_port fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::assign_random_host_forwarding_port() {
    assert_equal "$*" "container:foo-bar|crc:12345| ssh 22"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Failed to assign random host forwarding port to container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If ssh port is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::assign_random_host_forwarding_port() {
    assert_equal "$*" "container:foo-bar|crc:12345| ssh 22"
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Empty ssh port for container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If set_ssh_port fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::assign_random_host_forwarding_port() {
    assert_equal "$*" "container:foo-bar|crc:12345| ssh 22"
    echo 2022
  }
  vedv::vmobj_entity::set_ssh_port() {
    assert_equal "$*" "container 12345 2022"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Failed to set ssh port 2022 to container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If hypervisor::start fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::assign_random_host_forwarding_port() {
    assert_equal "$*" "container:foo-bar|crc:12345| ssh 22"
    echo 2022
  }
  vedv::vmobj_entity::set_ssh_port() {
    assert_equal "$*" "container 12345 2022"
  }
  vedv::hypervisor::start() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "Failed to start container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If wait_for_ssh_service fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::assign_random_host_forwarding_port() {
    assert_equal "$*" "container:foo-bar|crc:12345| ssh 22"
    echo 2022
  }
  vedv::vmobj_entity::set_ssh_port() {
    assert_equal "$*" "container 12345 2022"
  }
  vedv::hypervisor::start() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
  }
  vedv::ssh_client::wait_for_ssh_service() {
    assert_equal "$*" "${TEST_SSH_IP} 2022"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$wait_for_ssh" "$vmobj_id"

  assert_failure
  assert_output "12345
Failed to wait for ssh service on port 2022"
}

# Tests for vedv::vmobj_service::stop_one()

@test "vedv::vmobj_service::stop_one() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id="12345"
  local -r save_state=false

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::stop_one() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r save_state=false
  local -r vmobj_id=""

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::stop_one() Should fail if is_started fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "Failed to get start status for container: '12345'"
}

@test "vedv::vmobj_service::stop_one() Should succeed If vm is already stopped" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::stop_one() should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::stop_one() should fail If vm_name is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "There is no vm name for container: '12345'"
}

@test "vedv::vmobj_service::stop_one() should fail If hypervisor::stop fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::stop() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_failure
  assert_output "Failed to stop container: '12345'"
}

@test "vedv::vmobj_service::stop_one() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r save_state=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::stop() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
  }

  run vedv::vmobj_service::stop_one "$type" "$save_state" "$vmobj_id"

  assert_success
  assert_output "12345"
}

# Tests for vedv::vmobj_service::secure_stop_one()

@test "vedv::vmobj_service::secure_stop_one() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id="12345"

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::secure_stop_one() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::secure_stop_one() Should fail if is_started fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get start status for container: '12345'"
}

@test "vedv::vmobj_service::secure_stop_one() Should succeed If vm is already stopped" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::secure_stop_one() should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::secure_stop_one() should fail If vm_name is empty" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "There is no vm name for container: '12345'"
}

@test "vedv::vmobj_service::secure_stop_one() should fail If hypervisor::shutdown fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::shutdown() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to stop container: '12345'"
}

@test "vedv::vmobj_service::secure_stop_one() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::shutdown() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::is_running() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    echo false
  }
  utils::sleep() {
    assert_equal "$*" 1
  }
  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::secure_stop_one() Should fail If poweroff fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::shutdown() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
  }
  vedv::hypervisor::is_running() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    echo true
  }
  utils::sleep() {
    assert_equal "$*" 1
  }
  vedv::hypervisor::poweroff() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::secure_stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to stop container: 12345, trying to poweroff it...
Failed to poweroff container: 12345"
}

# Tests for vedv::vmobj_service::exists_with_name()

@test "vedv::vmobj_service::exists_with_name() should return error when type is empty" {
  local -r type=""
  local -r vmobj_name="foo-bar"

  run vedv::vmobj_service::exists_with_name "$type" "$vmobj_name"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::exists_with_name() should return error when vmobj_name is empty" {
  local -r type="container"
  local -r vmobj_name=""

  run vedv::vmobj_service::exists_with_name "$type" "$vmobj_name"

  assert_failure
  assert_output "Argument 'vmobj_name' is required"
}

@test "vedv::vmobj_service::exists_with_name() should return error when exists_vm_with_partial_name fails" {
  local -r type="container"
  local -r vmobj_name="foo-bar"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "container:foo-bar|"
    return 1
  }

  run vedv::vmobj_service::exists_with_name "$type" "$vmobj_name"

  assert_failure
  assert_output "Hypervisor failed to check if container with name 'foo-bar' exists"
}

@test "vedv::vmobj_service::exists_with_name() should succeed" {
  local -r type="container"
  local -r vmobj_name="foo-bar"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "container:foo-bar|"
    echo true
  }

  run vedv::vmobj_service::exists_with_name "$type" "$vmobj_name"

  assert_success
  assert_output "true"
}

# Tests for vedv::vmobj_service::exists_with_id()

@test "vedv::vmobj_service::exists_with_id() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id="123456"

  run vedv::vmobj_service::exists_with_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::exists_with_id() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::exists_with_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Argument 'vmobj_id' is required"
}

@test "vedv::vmobj_service::exists_with_id() should return error when exists_vm_with_partial_name fails" {
  local -r type="container"
  local -r vmobj_id="123456"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "|crc:123456|"
    return 1
  }

  run vedv::vmobj_service::exists_with_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Hypervisor failed to check if container with id '123456' exists"
}

@test "vedv::vmobj_service::exists_with_id() should succeed" {
  local -r type="container"
  local -r vmobj_id="123456"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "|crc:123456|"
    echo true
  }

  run vedv::vmobj_service::exists_with_id "$type" "$vmobj_id"

  assert_success
  assert_output "true"
}

# Tests for vedv::vmobj_service::list()

@test "vedv::vmobj_service::list(), Should fail with invalid type" {
  local -r type="invalid"

  run vedv::vmobj_service::list "$type"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::list(), Should fail If hypervisor::list_running fails" {
  local -r type="container"

  vedv::hypervisor::list() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::hypervisor::list_running() {
    assert_equal "$*" ""
    return 1
  }

  run vedv::vmobj_service::list "$type"

  assert_failure
  assert_output "Error getting virtual machines names"
}

@test "vedv::vmobj_service::list(), Should fail If hypervisor::list fails" {
  local -r type="container"
  local -r list_all=true

  vedv::hypervisor::list() {
    assert_equal "$*" ""
    return 1
  }
  vedv::hypervisor::list_running() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::list "$type" "$list_all"

  assert_failure
  assert_output "Error getting virtual machines names"
}

@test "vedv::vmobj_service::list(), Should fail If get_vmobj_id_by_vm_name fails" {
  local -r type="container"

  vedv::hypervisor::list() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::hypervisor::list_running() {
    assert_equal "$*" ""
    cat <<EOF
image:fii-boom|crc:12347|
container:foo-bar|crc:12345|
container:pri-pal|crc:12346|
container:dan-din|crc:12348|

EOF
  }
  vedv::vmobj_entity::get_vmobj_id_by_vm_name() {
    assert_equal "$*" "container container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::list "$type"

  assert_failure
  assert_output "Failed to get container id for vm: 'container:foo-bar|crc:12345|'"
}

@test "vedv::vmobj_service::list(), Should fail If get_vmobj_name_by_vm_name fails" {
  local -r type="container"

  vedv::hypervisor::list() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::hypervisor::list_running() {
    assert_equal "$*" ""
    cat <<EOF
image:fii-boom|crc:12347|
container:foo-bar|crc:12345|
container:pri-pal|crc:12346|
container:dan-din|crc:12348|

EOF
  }
  vedv::vmobj_entity::get_vmobj_id_by_vm_name() {
    assert_equal "$*" "container container:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
    assert_equal "$*" "container container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::list "$type"

  assert_failure
  assert_output "Failed to get container name for vm: 'container:foo-bar|crc:12345|'"
}

@test "vedv::vmobj_service::list(), Should succeed" {
  local -r type="container"

  vedv::hypervisor::list() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::hypervisor::list_running() {
    assert_equal "$*" ""
    cat <<EOF
image:fii-boom|crc:12347|
container:foo-bar|crc:12345|
container:pri-pal|crc:12346|
container:dan-din|crc:12348|

EOF
  }
  vedv::vmobj_entity::get_vmobj_id_by_vm_name() {
    assert_regex "$*" "container\s+container:.*\|crc:.*\|"
    echo "$2" | grep -o 'crc:.*|$' | sed -e 's/crc://' -e 's/|$//'
  }
  vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
    assert_regex "$*" "container\s+container:.*\|crc:.*\|"
    echo "$2" | grep -o '^container:.*|' | sed -e 's/^container://' -e 's/|.*//'
  }

  run vedv::vmobj_service::list "$type"

  assert_success
  assert_output "12345 foo-bar
12346 pri-pal
12348 dan-din"
}

# Tests for vedv::vmobj_service::__exec_ssh_func
@test "vedv::vmobj_service::__exec_ssh_func(), Should fail with invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r exec_func=""

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r exec_func=""

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail With empty exec_func" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func=""

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Invalid argument 'exec_func': it's empty"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail With empty user" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="exec_func"
  __VEDV_VMOBJ_SERVICE_SSH_USER=""

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo ""
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Invalid argument 'user': it's empty"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If start_one fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="ssh_func"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container true 12345"
    return 1
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Failed to start container: 12345"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If get_ssh_port fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="ssh_func"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container true 12345"
  }
  vedv::vmobj_entity::get_ssh_port() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Failed to get ssh port for container: 12345"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If exec_func fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="ssh_func"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container true 12345"
  }
  vedv::vmobj_entity::get_ssh_port() {
    assert_equal "$*" "container 12345"
    echo 2022
  }
  ssh_func() {
    assert_equal "$*" ""
    return 1
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Failed to execute function on container: 12345"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="ssh_func"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }

  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container true 12345"
  }
  vedv::vmobj_entity::get_ssh_port() {
    assert_equal "$*" "container 12345"
    echo 2022
  }
  ssh_func() {
    assert_equal "$*" ""
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::execute_cmd_by_id()

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail with invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r cmd=""

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r cmd=""

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail With empty cmd" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd=""

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Invalid argument 'cmd': it's empty"
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail If __exec_ssh_func fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd="cmd"

  vedv::vmobj_service::__exec_ssh_func() {
    assert_regex "$*" "container 12345 vedv::ssh_client::run_cmd.*"
    return 1
  }

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Failed to execute command in container: 12345"
}

# Tests for vedv::vmobj_service::execute_cmd()

@test "vedv::vmobj_service::execute_cmd(), Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd=":"

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::execute_cmd "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Failed to get container id by name or id: 12345"
}

@test "vedv::vmobj_service::execute_cmd(), Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd=":"
  local -r user=""

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    echo 12345
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 : "
  }

  run vedv::vmobj_service::execute_cmd "$type" "$vmobj_id" "$cmd" "$user"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::connect_by_id()

@test "vedv::vmobj_service::connect_by_id(), Should fail with invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""

  run vedv::vmobj_service::connect_by_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::connect_by_id(), Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::connect_by_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::connect_by_id(), Should fail If __exec_ssh_func fails" {
  local -r type="container"
  local -r vmobj_id=12345

  vedv::vmobj_service::__exec_ssh_func() {
    assert_regex "$*" "container 12345 vedv::ssh_client::connect.*"
    return 1
  }

  run vedv::vmobj_service::connect_by_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to connect to container: 12345"
}

# Tests for vedv::vmobj_service::connect()

@test "vedv::vmobj_service::connect(), Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_id=12345

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::connect "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get container id by name or id: 12345"
}

@test "vedv::vmobj_service::connect(), Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    echo 12345
  }
  vedv::vmobj_service::connect_by_id() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::connect "$type" "$vmobj_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::copy_by_id()

@test "vedv::vmobj_service::copy_by_id(), Should fail with invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r src="src"
  local -r dest="dest"

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r src="src"
  local -r dest="dest"

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail With empty src" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src=""
  local -r dest="dest"

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Invalid argument 'src': it's empty"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail With empty dest" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest=""

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Invalid argument 'dest': it's empty"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail If get_joined_vedvfileignore fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"

  vedv:image_vedvfile_service::get_joined_vedvfileignore() {
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Failed to get joined vedvfileignore"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail If __exec_ssh_func fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"

  vedv:image_vedvfile_service::get_joined_vedvfileignore() {
    echo "/tmp/vedvfileignore"
  }
  vedv::vmobj_service::__exec_ssh_func() {
    assert_regex "$*" "container 12345 vedv::ssh_client::copy.*"
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Failed to copy to container: 12345"
}

# Tests for vedv::vmobj_service::copy()

@test "vedv::vmobj_service::copy(), Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::copy "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Failed to get container id by name or id: 12345"
}

@test "vedv::vmobj_service::copy(), Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"

  vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
    assert_equal "$*" "container 12345"
    echo 12345
  }
  vedv::vmobj_service::copy_by_id() {
    assert_equal "$*" "container 12345 src dest "
  }

  run vedv::vmobj_service::copy "$type" "$vmobj_id" "$src" "$dest"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::set_user()
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r user_name=""

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r user_name=""

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail With empty user_name" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name=""

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid argument 'user_name': it's empty"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail If get_user_name fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Error getting attribute user name from the container '12345'"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should succeed If the user is already set" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "user"
  }

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_success
  assert_output ""
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' '${__VEDV_VMOBJ_SERVICE_SSH_PASSWORD}' root"
    return 1
  }

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Failed to set user 'user' to container: 12345"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should fail If set_user_name fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' '${__VEDV_VMOBJ_SERVICE_SSH_PASSWORD}' root"
  }
  vedv::vmobj_entity::set_user_name() {
    assert_equal "$*" "container 12345 user"
    return 1
  }

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Error setting attribute user name 'user' to the container: 12345"
}
# bats test_tags=only
@test "vedv::vmobj_service::set_user() Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_entity::get_user_name() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' '${__VEDV_VMOBJ_SERVICE_SSH_PASSWORD}' root"
  }
  vedv::vmobj_entity::set_user_name() {
    assert_equal "$*" "container 12345 user"
  }

  run vedv::vmobj_service::set_user "$type" "$vmobj_id" "$user_name"

  assert_success
  assert_output ""
}
