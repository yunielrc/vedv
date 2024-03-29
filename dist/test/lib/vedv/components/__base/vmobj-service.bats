# shellcheck disable=SC2317

load test_helper

setup_file() {
  vedv::vmobj_entity::constructor \
    "$(mktemp -d)" \
    'container|image' \
    '([image]="" [container]="parent_image_id")' \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD"

  export __VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR
  export __VEDV_VMOBJ_ENTITY_TYPE
  export __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR
  export __VEDV_DEFAULT_USER
  export __VEDV_DEFAULT_PASSWORD
  # shellcheck disable=SC2034
  local -rA vedv_vmobj_service_use_cache_dict=([container]=true)

  vedv::vmobj_service::constructor \
    "$TEST_SSH_IP" \
    "$TEST_SSH_USER" \
    "$(arr2str vedv_vmobj_service_use_cache_dict)"

  export __VEDV_VMOBJ_SERVICE_SSH_IP
  export __VEDV_VMOBJ_SERVICE_SSH_USER
  export __VEDV_VMOBJ_SERVICE_USE_CACHE_DICT
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
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_ids_or_names"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should fail With empty ids_or_names" {
  local -r type='container'
  local -r vmobj_ids_or_names=''
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_ids_or_names"

  assert_failure
  assert_output "At least one container id or name is required"
}

@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should fail If get_id fails" {
  local -r type='container'
  local -r vmobj_ids_or_names='name1 id1 name2 id2'

  vedv::vmobj_entity::get_id() {
    assert_regex "$*" '(name1|id1|name2|id2)'
    return 1
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_ids_or_names"

  assert_failure
  assert_output "name1 id1 name2 id2
Error getting vmobj id for containers: 'name1' 'id1' 'name2' 'id2' "
}
# bats test_tags=only
@test "vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() Should succeed" {
  local -r type='container'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  vedv::vmobj_entity::get_id() {
    assert_regex "$*" '(name1|id2|name3|id4)'

    case "$1" in
    name1)
      echo 'id11'
      ;;
    name3)
      echo 'id33'
      ;;
    *)
      echo "$1"
      ;;
    esac

    return 0
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_ids_or_names"

  assert_success
  assert_output "id11 id2 id33 id4"
}

# Tests for vedv::vmobj_service::exec_func_on_many_vmobjs()

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail With invalid type" {
  local -r type='invalid'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail With empty exec_func" {
  local -r type='container'
  local -r exec_func=''
  local -r vmobj_ids_or_names='name1 id2 name3 id4'
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_failure
  assert_output "Invalid argument 'exec_func': it's empty"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail With empty vmobj_ids_or_names" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names=''
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_failure
  assert_output "At least one container id or name is required"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail If __get_ids_from_vmobj_names_or_ids fails" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  vedv::vmobj_entity::get_id() {
    assert_regex "$*" '(name1|id2|name3|id4)'

    case "$1" in
    name1)
      echo 'id11'
      ;;
    name3)
      echo 'id33'
      ;;
    *)
      echo "$1"
      ;;
    esac

    return 1
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_failure
  assert_output "Error getting vmobj id for containers: 'name1' 'id2' 'name3' 'id4' "
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should fail If exec_func fails" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  func1() {
    assert_regex "$*" '(id1|id2|id3|id4)'
    return 1
  }

  vedv::vmobj_entity::get_id() {
    assert_regex "$*" '(name1|id2|name3|id4)'

    case "$1" in
    name1)
      echo 'id11'
      ;;
    name3)
      echo 'id33'
      ;;
    *)
      echo "$1"
      ;;
    esac

    return 0
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_failure
  assert_output "Failed to execute function on containers: 'id11''id2''id33''id4'"
}

@test "vedv::vmobj_service::exec_func_on_many_vmobj() Should succeed" {
  local -r type='container'
  local -r exec_func='func1'
  local -r vmobj_ids_or_names='name1 id2 name3 id4'

  func1() {
    assert_regex "$*" '(id1|id2|id3|id4)'
  }

  vedv::vmobj_entity::get_id() {
    assert_regex "$*" '(name1|id2|name3|id4)'

    case "$1" in
    name1)
      echo 'id11'
      ;;
    name3)
      echo 'id33'
      ;;
    *)
      echo "$1"
      ;;
    esac

    return 0
  }
  # shellcheck disable=SC2086
  run vedv::vmobj_service::exec_func_on_many_vmobj "$type" "$exec_func" "$vmobj_ids_or_names"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::__stop_base()

@test "vedv::vmobj_service::__stop_base() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id=""
  local -r hypervisor_stop_func_wo_args=""
  local -r stop_type=""

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::__stop_base() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r vmobj_id=""
  local -r hypervisor_stop_func_wo_args=""
  local -r stop_type=""

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::__stop_base() should return error when hypervisor_stop_func_wo_args is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args=""
  local -r stop_type=""

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Invalid argument 'hypervisor_stop_func_wo_args': it's empty"
}

@test "vedv::vmobj_service::__stop_base() should return error when stop_type is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type=""

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Invalid argument 'stop_type': it's empty"
}

@test "vedv::vmobj_service::__stop_base() Should fail if is_started fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Failed to get start status for container: '12345'"
}

@test "vedv::vmobj_service::__stop_base() Should succeed If vm is already stopped" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo false
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::__stop_base() should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::__stop_base() should fail If vm_name is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "There is no vm name for container: '12345'"
}

@test "vedv::vmobj_service::__stop_base() should fail If stop fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  stop_func() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
    return 1
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_failure
  assert_output "Failed to stop container: '12345'"
}

@test "vedv::vmobj_service::__stop_base() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r hypervisor_stop_func_wo_args="stop_func"
  local -r stop_type="stop"

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    echo "container:foo-bar|crc:12345|"
  }
  stop_func() {
    assert_equal "$*" "container:foo-bar|crc:12345|"
  }

  run vedv::vmobj_service::__stop_base \
    "$type" "$vmobj_id" \
    "$hypervisor_stop_func_wo_args" \
    "$stop_type"

  assert_success
  assert_output "12345"
}

# Tests for vedv::vmobj_service::start_one()

@test "vedv::vmobj_service::start_one() should return error when type is empty" {
  local -r type=""
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::start_one() should return error when vmobj_id is empty" {
  local -r type="container"
  local -r vmobj_id=""
  local -r wait_for_ssh=true
  local -r show=false

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::start_one() Should fail if is_started fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Failed to get start status for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should succeed If vm is already started" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

  vedv::vmobj_service::exists_with_id() {
    echo true
  }
  vedv::vmobj_service::is_started() {
    assert_equal "$*" "container 12345"
    echo true
  }

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::start_one() Should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If vm_name is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "There is no vm name for container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If assign_random_host_forwarding_port fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Failed to assign random host forwarding port to container: '12345'"
}

@test "vedv::vmobj_service::start_one() Should fail If ssh port is empty" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Empty ssh port for container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If set_ssh_port fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Failed to set ssh port 2022 to container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If hypervisor::start fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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
    assert_equal "$*" "container:foo-bar|crc:12345| false"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "Failed to start container: 12345"
}

@test "vedv::vmobj_service::start_one() Should fail If wait_for_ssh_service fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r wait_for_ssh=true
  local -r show=false

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
    assert_equal "$*" "container:foo-bar|crc:12345| false"
  }
  vedv::ssh_client::wait_for_ssh_service() {
    assert_equal "$*" "${TEST_SSH_IP} 2022"
    return 1
  }

  run vedv::vmobj_service::start_one "$type" "$vmobj_id" "$wait_for_ssh" "$show"

  assert_failure
  assert_output "12345
Failed to wait for ssh service on port 2022"
}

# Tests for vedv::vmobj_service::kill_one()
@test "vedv::vmobj_service::kill_one() should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::poweroff kill"
  }

  run vedv::vmobj_service::kill_one "$type" "$vmobj_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::kill()
@test "vedv::vmobj_service::kill() should succeed" {
  local -r type="container"
  local -r vmobj_names_or_ids="123 name1"

  vedv::vmobj_service::exec_func_on_many_vmobj() {
    assert_equal "$*" "container vedv::vmobj_service::kill_one 'container' 123 name1"
  }

  run vedv::vmobj_service::kill "$type" "$vmobj_names_or_ids"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::save_state_one()
@test "vedv::vmobj_service::save_state_one() should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::save_state_stop save_state"
  }

  run vedv::vmobj_service::save_state_one "$type" "$vmobj_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::save_state()
@test "vedv::vmobj_service::save_state() should succeed" {
  local -r type="container"
  local -r vmobj_names_or_ids="123 name1"

  vedv::vmobj_service::exec_func_on_many_vmobj() {
    assert_equal "$*" "container vedv::vmobj_service::save_state_one 'container' 123 name1"
  }

  run vedv::vmobj_service::save_state "$type" "$vmobj_names_or_ids"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::stop_one()
@test "vedv::vmobj_service::stop_one() fail i f __stop_base fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::shutdown stop"
    return 1
  }

  run vedv::vmobj_service::stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to shutdown container: 12345"
}

@test "vedv::vmobj_service::stop_one() should fail If get_vm_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::shutdown stop"
  }

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}

@test "vedv::vmobj_service::stop_one() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::shutdown stop"
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
  run vedv::vmobj_service::stop_one "$type" "$vmobj_id"

  assert_success
  assert_output "12345"
}

@test "vedv::vmobj_service::stop_one() Should fail If poweroff fails" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_service::__stop_base() {
    assert_equal "$*" "container 12345 vedv::hypervisor::shutdown stop"
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

  run vedv::vmobj_service::stop_one "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to stop container: 12345, trying to poweroff it...
Failed to poweroff container: 12345"
}

# Tests for vedv::vmobj_service::stop() {

@test "vedv::vmobj_service::stop() Should succeed" {
  local -r type="container"
  local -r vmobj_names_or_ids="container1 container2"

  vedv::vmobj_service::exec_func_on_many_vmobj() {
    assert_equal "$*" "container vedv::vmobj_service::stop_one 'container' container1 container2"
    echo "12345 123456"
  }

  run vedv::vmobj_service::stop "$type" "$vmobj_names_or_ids"

  assert_success
  assert_output "12345 123456"
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
    assert_equal "$*" 'container:foo-bar|crc:[[:digit:]]\{6,11\}|'
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
    assert_equal "$*" 'container:foo-bar|crc:[[:digit:]]\{6,11\}|'
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
    assert_equal "$*" 'container:[[:lower:]]\(\.\|-\|_\|[[:lower:]]\|[[:digit:]]\)\{1,28\}\([[:lower:]]\|[[:digit:]]\)|crc:123456|'
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
    assert_equal "$*" 'container:[[:lower:]]\(\.\|-\|_\|[[:lower:]]\|[[:digit:]]\)\{1,28\}\([[:lower:]]\|[[:digit:]]\)|crc:123456|'
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

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If get_user fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="exec_func"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Failed to get default user for container"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If user is empty" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="exec_func"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func"

  assert_failure
  assert_output "Invalid argument 'user': it's empty"
}

@test "vedv::vmobj_service::__exec_ssh_func(), Should fail If start_one fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r exec_func="ssh_func"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container 12345 true"
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

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container 12345 true"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
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

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container 12345 true"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
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

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container 12345 true"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
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

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail If get_workdir fail" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd="cmd"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd"

  assert_failure
  assert_output "Failed to get default workdir for container"
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should succeed With workdir <none>" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd="cmd"
  local -r user=""
  local -r workdir="<none>"

  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" $'container 12345 vedv::ssh_client::run_cmd "$user" "$ip" "$password" \'cmd\' "$port" \'\' \'\' \'\' '
  }

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" "$user" "$workdir"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should succeed With workdir" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd="cmd"
  local -r user=""
  local -r workdir="/home/vedv"

  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" $'container 12345 vedv::ssh_client::run_cmd "$user" "$ip" "$password" \'cmd\' "$port" \'/home/vedv\' \'\' \'\' '
  }

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" "$user" "$workdir"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::execute_cmd_by_id(), Should fail If __exec_ssh_func fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd="cmd"
  local -r user=""
  local -r workdir="<none>"

  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" "container 12345 vedv::ssh_client::run_cmd \"\$user\" \"\$ip\" \"\$password\" 'cmd' \"\$port\" '' '' '' "
    return 1
  }

  run vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" "$user" "$workdir"

  assert_failure
  assert_output "Failed to execute command in container: 12345"
}

# Tests for vedv::vmobj_service::execute_cmd()

@test "vedv::vmobj_service::execute_cmd(), Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r cmd=":"

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
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

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    echo 12345
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_regex "$*" "container 12345 :"
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

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    return 1
  }

  run vedv::vmobj_service::connect "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get container id by name or id: 12345"
}

@test "vedv::vmobj_service::connect(), Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    echo 12345
  }
  vedv::vmobj_service::connect_by_id() {
    assert_equal "$*" "container 12345 "
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
  assert_output "File '': does not exist"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail With empty dest" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest=""

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Invalid argument 'dest': it's empty"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail If get_workdir fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest"

  assert_failure
  assert_output "Failed to get default workdir for container"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail If get_joined_vedvfileignore fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"
  local -r user="user"
  local -r workdir="<none>"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir"

  assert_failure
  assert_output "Failed to get joined vedvfileignore"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail If __exec_ssh_func fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"
  local -r user="user"
  local -r workdir="/home/vedv"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    echo "/tmp/vedvfileignore"
  }
  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" "container 12345 vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${src}' 'dest' '/tmp/vedvfileignore' '/home/vedv' '' '' user"
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir"

  assert_failure
  assert_output "Failed to copy to container: 12345"
}

@test "vedv::vmobj_service::copy_by_id(), Should fail if ssh_copy fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"
  local -r user="user"
  local -r workdir="/home/vedv"
  local -r chown="nalyd"
  local -r chmod="644"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    echo "/tmp/vedvfileignore"
  }
  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" "container 12345 vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${src}' 'dest' '/tmp/vedvfileignore' '/home/vedv' 'nalyd' '644' user"
    return 1
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir" "$chown" "$chmod"

  assert_failure
  assert_output "Failed to copy to container: 12345"
}

@test "vedv::vmobj_service::copy_by_id(), Should Succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"
  local -r user="user"
  local -r workdir="/home/vedv"
  local -r chown="nalyd"
  local -r chmod="644"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    echo "/tmp/vedvfileignore"
  }
  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" "container 12345 vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${src}' 'dest' '/tmp/vedvfileignore' '/home/vedv' 'nalyd' '644' user"
  }

  run vedv::vmobj_service::copy_by_id "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir" "$chown" "$chmod"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::copy_by_id(), Should Succeed ignoring vedvfileignore files" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="$(mktemp)"
  local -r dest="dest"
  local -r user="user"
  local -r workdir="/home/vedv"
  local -r chown="nalyd"
  local -r chmod="644"
  local -r _no_vedvfileignore='true'

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    assert_equal "$*" 'INVALID_CALL'
  }
  vedv::vmobj_service::__exec_ssh_func() {
    assert_equal "$*" "container 12345 vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${src}' 'dest' '/dev/null' '/home/vedv' 'nalyd' '644' user"
  }

  run vedv::vmobj_service::copy_by_id \
    "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir" "$chown" "$chmod" "$_no_vedvfileignore"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::copy()

@test "vedv::vmobj_service::copy(), Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
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

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    echo 12345
  }
  vedv::vmobj_service::copy_by_id() {
    assert_equal "$*" "container 12345 src dest     false"
  }

  run vedv::vmobj_service::copy "$type" "$vmobj_id" "$src" "$dest"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::copy(), Should succeed with all arguments" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r src="src"
  local -r dest="dest"
  local -r user='vedv'
  local -r workdir='/home/vedv'
  local -r chown="nalyd"
  local -r chmod="644"

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    echo 12345
  }
  vedv::vmobj_service::copy_by_id() {
    assert_equal "$*" "container 12345 src dest vedv /home/vedv nalyd 644 false"
  }

  run vedv::vmobj_service::copy "$type" "$vmobj_id" "$src" "$dest" "$user" "$workdir" "$chown" "$chmod"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::set_user()

@test "vedv::vmobj_service::fs::set_user() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r user_name=""

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::fs::set_user() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r user_name=""

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::set_user() Should fail With empty user_name" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name=""

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Invalid argument 'user_name': it's empty"
}

@test "vedv::vmobj_service::fs::set_user() Should fail If get_user fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Error getting attribute user name from the container '12345'"
}

@test "vedv::vmobj_service::fs::set_user() Should succeed If the user is already set" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "user"
  }

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::fs::set_user() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' '' && vedv-setuser 'user' root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Failed to set user 'user' to container: 12345"
}

@test "vedv::vmobj_service::fs::set_user() Should fail If cache::set_user_name fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' 'vedv' && vedv-setuser 'user' root <none>"
  }
  vedv::vmobj_entity::cache::set_user_name() {
    assert_equal "$*" "container 12345 user"
    return 1
  }

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_failure
  assert_output "Failed to set user to container: 12345"
}

@test "vedv::vmobj_service::fs::set_user() Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r user_name="user"

  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "container 12345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-adduser 'user' 'vedv' && vedv-setuser 'user' root <none>"
  }
  vedv::vmobj_entity::cache::set_user_name() {
    assert_equal "$*" "container 12345 user"
  }

  run vedv::vmobj_service::fs::set_user "$type" "$vmobj_id" "$user_name"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::set_workdir()

@test "vedv::vmobj_service::fs::set_workdir() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""
  local -r workdir=""

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::fs::set_workdir() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r workdir=""

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::set_workdir() Should fail With empty workdir" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir=""

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_failure
  assert_output "Invalid argument 'workdir': it's empty"
}

@test "vedv::vmobj_service::fs::set_workdir() Should Succeed if workdir is already set" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir="workdir1"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 22345"
    echo "workdir1"
  }

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::fs::set_workdir() Should fail if get_user fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir="workdir1"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 22345"
    echo "workdir1"
  }
  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 22345"
    return 1
  }

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::fs::set_workdir() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir="workdir1"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 22345"
    echo "workdir2"
  }
  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 22345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-setworkdir 'workdir1' 'vedv' root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_failure
  assert_output "Failed to set workdir 'workdir1' to container: 22345"
}

@test "vedv::vmobj_service::fs::set_workdir() Should fail If cache::set_workdir fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir="workdir1"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 22345"
    echo "workdir2"
  }
  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 22345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-setworkdir 'workdir1' 'vedv' root <none>"
    echo "/home/vedv/workdir1"
  }
  vedv::vmobj_entity::cache::set_workdir() {
    assert_equal "$*" "container 22345 /home/vedv/workdir1"
    return 1
  }

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_failure
  assert_output "Failed to set workdir to container: 22345"
}

@test "vedv::vmobj_service::fs::set_workdir() Should succeed" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r workdir="workdir1"

  vedv::vmobj_service::fs::get_workdir() {
    assert_equal "$*" "container 22345"
    echo "workdir2"
  }
  vedv::vmobj_service::fs::get_user() {
    assert_equal "$*" "container 22345"
    echo "vedv"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-setworkdir 'workdir1' 'vedv' root <none>"
    echo "/home/vedv/workdir1"
  }
  vedv::vmobj_entity::cache::set_workdir() {
    assert_equal "$*" "container 22345 /home/vedv/workdir1"
  }

  run vedv::vmobj_service::fs::set_workdir "$type" "$vmobj_id" "$workdir"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::get_user()
@test "vedv::vmobj_service::fs::get_user() Should fail If get_user_name fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo "true"
  }
  vedv::vmobj_entity::cache::get_user_name() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::get_user "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get cached user for container: 12345"
}

@test "vedv::vmobj_service::fs::get_user() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo 'false'
  }
  vedv::vmobj_entity::cache::get_user_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getuser root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::get_user "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get user of container: 12345"
}

@test "vedv::vmobj_service::fs::get_user() Should succeed without cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='false'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_user_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getuser root <none>"
    echo 'vedv'
  }

  run vedv::vmobj_service::fs::get_user "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

@test "vedv::vmobj_service::fs::get_user() Should succeed with cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='true'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_user_name() {
    assert_equal "$*" "container 12345"
    echo 'vedv'
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::fs::get_user "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::vmobj_service::fs::get_workdir()
# Tests for vedv::vmobj_service::fs::get_workdir()

@test "vedv::vmobj_service::fs::get_workdir() Should fail If get_workdir fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo "true"
  }
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::get_workdir "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get cached workdir for container: 12345"
}

@test "vedv::vmobj_service::fs::get_workdir() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo 'false'
  }
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getworkdir root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::get_workdir "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get workdir of container: 12345"
}

@test "vedv::vmobj_service::fs::get_workdir() Should succeed without cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='false'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getworkdir root <none>"
    echo 'vedv'
  }

  run vedv::vmobj_service::fs::get_workdir "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

@test "vedv::vmobj_service::fs::get_workdir() Should succeed with cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='true'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "container 12345"
    echo 'vedv'
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::fs::get_workdir "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::vmobj_service::fs::add_environment_var()

@test "vedv::vmobj_service::fs::add_environment_var() Should fail With empty type" {
  local -r type=""
  local -r vmobj_id="22345"
  local -r env_var="env_var1"

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::fs::add_environment_var() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r env_var="env_var1"

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::add_environment_var() Should fail With empty env_var" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r env_var=""

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_failure
  assert_output "Invalid argument 'env_var': it's empty"
}

@test "vedv::vmobj_service::fs::add_environment_var() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r env_var="env_var1"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addenv_var $'env_var1' root <none>  bash"
    return 1
  }

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_failure
  assert_output "Failed to add environment variable 'env_var1' to container: 22345"
}

@test "vedv::vmobj_service::fs::add_environment_var() Should fail If cache::set_environment fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r env_var='EVAR3="VALUE 3"'

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addenv_var $'EVAR3=\"VALUE 3\"' root <none>  bash"
    cat <<EOF
EVAR1='VALUE1'
EVAR2='VALUE2'
EVAR3="VALUE 3"
EOF
  }
  vedv::vmobj_entity::cache::set_environment() {
    assert_equal "$*" "container 22345 EVAR1='VALUE1'
EVAR2='VALUE2'
EVAR3=\"VALUE 3\""
    return 1
  }

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_failure
  assert_output "Failed to set env for container: 22345"
}

@test "vedv::vmobj_service::fs::add_environment_var() Should succeed" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r env_var='EVAR3="VALUE 3"'

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addenv_var $'EVAR3=\"VALUE 3\"' root <none>  bash"
    cat <<EOF
EVAR1='VALUE1'
EVAR2='VALUE2'
EVAR3="VALUE 3"
EOF
  }
  vedv::vmobj_entity::cache::set_environment() {
    assert_equal "$*" "container 22345 EVAR1='VALUE1'
EVAR2='VALUE2'
EVAR3=\"VALUE 3\""
  }

  run vedv::vmobj_service::fs::add_environment_var "$type" "$vmobj_id" "$env_var"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::list_environment_vars()
@test "vedv::vmobj_service::fs::list_environment_vars() Should fail If get_environment fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo "true"
  }
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::list_environment_vars "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get cached environment for container: 12345"
}

@test "vedv::vmobj_service::fs::list_environment_vars() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo 'false'
  }
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getenv_vars root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::list_environment_vars "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to list environment variables of container: 12345"
}

@test "vedv::vmobj_service::fs::list_environment_vars() Should succeed without cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='false'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getenv_vars root <none>"
    echo 'vedv'
  }

  run vedv::vmobj_service::fs::list_environment_vars "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

@test "vedv::vmobj_service::fs::list_environment_vars() Should succeed with cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='true'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "container 12345"
    echo 'vedv'
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::fs::list_environment_vars "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::vmobj_service::get_use_cache()
@test "vedv::vmobj_service::get_use_cache() Should fail With invalid type" {
  local -r type='invalid'

  run vedv::vmobj_service::get_use_cache "$type"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::get_use_cache() Should fail if ..._CACHE_DICT is not set" {
  local -r type='container'
  # shellcheck disable=SC2030
  __VEDV_VMOBJ_SERVICE_USE_CACHE_DICT=''

  run vedv::vmobj_service::get_use_cache "$type"

  assert_failure
  assert_output "Use cache dict is not set"
}

@test "vedv::vmobj_service::get_use_cache() Should echo false If dict key does not exist" {
  local -r type='image'

  run vedv::vmobj_service::get_use_cache "$type"

  assert_success
  assert_output "false"
}

@test "vedv::vmobj_service::get_use_cache() Should echo true" {
  local -r type='container'

  run vedv::vmobj_service::get_use_cache "$type"

  assert_success
  assert_output "true"
}

# Tests for vedv::vmobj_service::set_use_cache()

@test "vedv::vmobj_service::set_use_cache() Should fail With invalid type" {
  local -r type='invalid'
  local -r use_cache='true'

  run vedv::vmobj_service::set_use_cache "$type" "$use_cache"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::set_use_cache() Should fail With empty use_cache" {
  local -r type='container'
  local -r use_cache=''

  run vedv::vmobj_service::set_use_cache "$type" "$use_cache"

  assert_failure
  assert_output "Argument 'value' is required"
}

@test "vedv::vmobj_service::set_use_cache() Success" {
  local -r type='container'
  local -r use_cache='false'

  __wrapper_set_use_cache() {
    vedv::vmobj_service::set_use_cache "$type" "$use_cache"
    # shellcheck disable=SC2031
    echo "$__VEDV_VMOBJ_SERVICE_USE_CACHE_DICT"
  }

  run __wrapper_set_use_cache

  assert_success
  assert_output '([container]="false" )'
}

# Tests for vedv::vmobj_service::fs::set_shell()
@test "vedv::vmobj_service::fs::set_shell(): Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r shell="sh"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-setshell 'sh' root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::set_shell "$type" "$vmobj_id" "$shell"

  assert_failure
  assert_output "Failed to set shell 'sh' to container: 12345"
}

@test "vedv::vmobj_service::fs::set_shell(): Should fail If cache::set_shell fails" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r shell="shell"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-setshell 'shell' root <none>"
    echo '/bin/shell'
  }

  vedv::vmobj_entity::cache::set_shell() {
    assert_equal "$*" "container 12345 /bin/shell"
    return 1
  }

  run vedv::vmobj_service::fs::set_shell "$type" "$vmobj_id" "$shell"

  assert_failure
  assert_output "Failed to set shell to container: 12345"
}

@test "vedv::vmobj_service::fs::set_shell(): Should succeed" {
  local -r type="container"
  local -r vmobj_id=12345
  local -r shell="shell"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-setshell 'shell' root <none>"
    echo '/bin/shell'
  }

  vedv::vmobj_entity::cache::set_shell() {
    assert_equal "$*" "container 12345 /bin/shell"
  }

  run vedv::vmobj_service::fs::set_shell "$type" "$vmobj_id" "$shell"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::get_shell()
@test "vedv::vmobj_service::fs::get_shell() Should fail If get_shell fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo "true"
  }
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::get_shell "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get cached shell for container: 12345"
}

@test "vedv::vmobj_service::fs::get_shell() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo 'false'
  }
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getshell root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::get_shell "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get shell of container: 12345"
}

@test "vedv::vmobj_service::fs::get_shell() Should succeed without cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='false'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getshell root <none>"
    echo 'vedv'
  }

  run vedv::vmobj_service::fs::get_shell "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

@test "vedv::vmobj_service::fs::get_shell() Should succeed with cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='true'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "container 12345"
    echo 'vedv'
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::fs::get_shell "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::vmobj_service::fs::add_exposed_ports()

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail With empty type" {
  local -r type=""
  local -r vmobj_id="22345"
  local -r ports="ports1"

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r ports="ports1"

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail With empty ports" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r ports=""

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Invalid argument 'eports': it's empty"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail With invalid ports" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r ports="8081/tca" # it must be 8081/tcp

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Invalid argument 'ports': it's invalid"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r ports="8081/udp"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addexpose_ports $'8081/udp' root <none>  bash"
    return 1
  }

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Failed to add expose ports '8081/udp' to container: 22345"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should fail If cache::set_exposed_ports fails" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r ports="8083/tcp"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addexpose_ports $'8083/tcp' root <none>  bash"
    cat <<EOF
8080/tcp
8081/tcp
8082/tcp
8083/tcp
EOF
  }
  vedv::vmobj_entity::cache::set_exposed_ports() {
    assert_equal "$*" "container 22345 8080/tcp
8081/tcp
8082/tcp
8083/tcp"
    return 1
  }

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_failure
  assert_output "Failed to set exposed ports for container: 22345"
}

@test "vedv::vmobj_service::fs::add_exposed_ports() Should succeed" {
  local -r type="container"
  local -r vmobj_id="22345"
  local -r ports="8083/tcp"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 22345 vedv-addexpose_ports $'8083/tcp' root <none>  bash"
    cat <<EOF
8080/tcp
8081/tcp
8082/tcp
8083/tcp
EOF
  }
  vedv::vmobj_entity::cache::set_exposed_ports() {
    assert_equal "$*" "container 22345 8080/tcp
8081/tcp
8082/tcp
8083/tcp"
  }

  run vedv::vmobj_service::fs::add_exposed_ports "$type" "$vmobj_id" "$ports"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::list_exposed_ports_by_id()

@test "vedv::vmobj_service::fs::list_exposed_ports_by_id() Should fail If get_exposed_ports fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo "true"
  }
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::fs::list_exposed_ports_by_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get cached exposed ports for container: 12345"
}

@test "vedv::vmobj_service::fs::list_exposed_ports_by_id() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="12345"
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "container"
    echo 'false'
  }
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getexpose_ports root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::list_exposed_ports_by_id "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to list exposed ports of container: 12345"
}

@test "vedv::vmobj_service::fs::list_exposed_ports_by_id() Should succeed without cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='false'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 12345 vedv-getexpose_ports root <none>"
    echo 'vedv'
  }

  run vedv::vmobj_service::fs::list_exposed_ports_by_id "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

@test "vedv::vmobj_service::fs::list_exposed_ports_by_id() Should succeed with cache" {
  local -r type="container"
  local -r vmobj_id="12345"
  local -r use_cache='true'
  # Stub
  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "container 12345"
    echo 'vedv'
  }
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::vmobj_service::fs::list_exposed_ports_by_id "$type" "$vmobj_id" "$use_cache"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::vmobj_service::fs::list_exposed_ports()

@test "vedv::vmobj_service::fs::list_exposed_ports() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_name_or_id=""

  run vedv::vmobj_service::fs::list_exposed_ports "$type" "$vmobj_name_or_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id_or_name': it's empty"
}

@test "vedv::vmobj_service::fs::list_exposed_ports() Should fail If get_ids_from_vmobj_names_or_ids fails" {
  local -r type="container"
  local -r vmobj_name_or_id="container1"

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "container1"
    return 1
  }

  run vedv::vmobj_service::fs::list_exposed_ports "$type" "$vmobj_name_or_id"

  assert_failure
  assert_output "Failed to get container id by name or id: container1"
}

@test "vedv::vmobj_service::fs::list_exposed_ports() Should succeed" {
  local -r type="container"
  local -r vmobj_name_or_id="container1"

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "container1"
    echo "12345"
  }
  vedv::vmobj_service::fs::list_exposed_ports_by_id() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::fs::list_exposed_ports "$type" "$vmobj_name_or_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::cache_data()

@test "vedv::vmobj_service::cache_data() Should fail With empty type" {
  local -r type=""
  local -r vmobj_id="12345"

  run vedv::vmobj_service::cache_data "$type" "$vmobj_id"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_service::cache_data() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::cache_data "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::cache_data() Should fail If get_data_dictionary fails" {
  local -r type="container"
  local -r vmobj_id="1234567890"

  vedv::vmobj_service::fs::get_data_dictionary() {
    assert_equal "$*" "container 1234567890"
    return 1
  }

  run vedv::vmobj_service::cache_data "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get user name for container"
}

@test "vedv::vmobj_service::cache_data() Should fail If set_dictionary fails" {
  local -r type="container"
  local -r vmobj_id="1234567890"

  vedv::vmobj_service::fs::get_data_dictionary() {
    assert_equal "$*" "container 1234567890"
    echo '( [user_name]="vedv" [workdir]="/home/vedv" [environment]="EVAR1=VALUE1" [shell]="/bin/shell" [exposed_ports]="8080/tcp" [cpus]="2" [memory]="1024")'
  }

  vedv::vmobj_entity::set_dictionary() {
    assert_equal "$*" 'container 1234567890 ([user_name]="vedv" [shell]="/bin/shell" [workdir]="/home/vedv" [exposed_ports]="8080/tcp" [cpus]="2" [memory]="1024" [environment]="EVAR1=VALUE1" )'
    return 1
  }

  run vedv::vmobj_service::cache_data "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to set data dict for container: 1234567890"
}

@test "vedv::vmobj_service::cache_data() Should succeed" {
  local -r type="container"
  local -r vmobj_id="1234567890"

  vedv::vmobj_service::fs::get_data_dictionary() {
    assert_equal "$*" "container 1234567890"
    echo '( [user_name]="vedv" [workdir]="/home/vedv" [environment]="EVAR1=VALUE1" [shell]="/bin/shell" [exposed_ports]="8080/tcp" [cpus]="2" [memory]="1024")'
  }

  vedv::vmobj_entity::set_dictionary() {
    assert_equal "$*" 'container 1234567890 ([user_name]="vedv" [shell]="/bin/shell" [workdir]="/home/vedv" [exposed_ports]="8080/tcp" [cpus]="2" [memory]="1024" [environment]="EVAR1=VALUE1" )'
  }

  run vedv::vmobj_service::cache_data "$type" "$vmobj_id"

  assert_success
  assert_output ""
}

@test "vedv::vmobj_service::start_one_batch() Should succeed" {
  local -r type="container"
  local -r wait_for_ssh="false"
  local -r show="true"
  local -r vmobj_id="12345"

  vedv::vmobj_service::start_one() {
    assert_equal "$*" "container 12345 false true"
  }

  run vedv::vmobj_service::start_one_batch "$type" "$wait_for_ssh" "$show" "$vmobj_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::start()

@test "vedv::vmobj_service::start() Should succeed" {
  local -r type="container"
  local -r vmobj_names_or_ids="container1 container2"
  local -r wait_for_ssh="false"
  local -r show="true"

  vedv::vmobj_service::exec_func_on_many_vmobj() {
    assert_equal "$*" "container vedv::vmobj_service::start_one_batch 'container' 'false' 'true' container1 container2"
    echo "12345 123456"
  }

  run vedv::vmobj_service::start "$type" "$vmobj_names_or_ids" "$wait_for_ssh" "$show"

  assert_success
  assert_output "12345 123456"
}

# Tests for vedv::vmobj_service::after_create()

@test "vedv::vmobj_service::after_create() Should fail" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_entity::memcache_delete_data() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::after_create "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to delete memcache for container: 12345"
}

@test "vedv::vmobj_service::after_create() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_entity::memcache_delete_data() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::after_create "$type" "$vmobj_id"

  assert_success
  assert_output ""
}
# Tests for vedv::vmobj_service::after_remove()

@test "vedv::vmobj_service::after_remove() Should fail" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_entity::memcache_delete_data() {
    assert_equal "$*" "container 12345"
    return 1
  }

  run vedv::vmobj_service::after_remove "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to delete memcache for container: 12345"
}

@test "vedv::vmobj_service::after_remove() Should succeed" {
  local -r type="container"
  local -r vmobj_id="12345"

  vedv::vmobj_entity::memcache_delete_data() {
    assert_equal "$*" "container 12345"
  }

  run vedv::vmobj_service::after_remove "$type" "$vmobj_id"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::modify_system()

@test "vedv::vmobj_service::modify_system() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id="1234567890"
  local -r cpus="1"
  local -r memory="1024"

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::modify_system() Should fail With empty vmobj_id" {
  local -r type="image"
  local -r vmobj_id=""
  local -r cpus="1"
  local -r memory="1024"

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::modify_system() Should fail If cpus and memory are empty" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus=""
  local -r memory=""

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "At least one of cpus or memory must be set"
}

@test "vedv::vmobj_service::modify_system() Should fail If cpus and memory are 0" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="0"
  local -r memory="0"

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "At least one of cpus or memory must be set"
}

@test "vedv::vmobj_service::modify_system() Should fail If get_vm_name fails" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    return 1
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to get vm name for image: 1234567890"
}

@test "vedv::vmobj_service::modify_system() Should fail If get_state fails" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    echo "image:image123|crc:1234567890"
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:image123|crc:1234567890"
    return 1
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to get vm state for image: 1234567890"
}

@test "vedv::vmobj_service::modify_system() Should fail If start_one fails" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    echo "image:image123|crc:1234567890"
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:image123|crc:1234567890"
    echo "saved"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "image 1234567890 false"
    return 1
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to start image: '1234567890'"
}

@test "vedv::vmobj_service::modify_system() Should fail If secure_stop_one fails" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    echo "image:image123|crc:1234567890"
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:image123|crc:1234567890"
    echo "saved"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "image 1234567890 false"
  }
  vedv::vmobj_service::stop_one() {
    assert_equal "$*" "image 1234567890"
    return 1
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to secure stop image: 1234567890"
}

@test "vedv::vmobj_service::modify_system() Should fail If modifyvm fails" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    echo "image:image123|crc:1234567890"
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:image123|crc:1234567890"
    echo "saved"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "image 1234567890 false"
  }
  vedv::vmobj_service::stop_one() {
    assert_equal "$*" "image 1234567890"
  }
  vedv::hypervisor::modifyvm() {
    assert_equal "$*" "image:image123|crc:1234567890 4 1024"
    return 1
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to set cpus for image: 1234567890"
}

@test "vedv::vmobj_service::modify_system() Should succeed" {
  local -r type="image"
  local -r vmobj_id="1234567890"
  local -r cpus="4"
  local -r memory="1024"

  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "image 1234567890"
    echo "image:image123|crc:1234567890"
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:image123|crc:1234567890"
    echo "saved"
  }
  vedv::vmobj_service::start_one() {
    assert_equal "$*" "image 1234567890 false"
  }
  vedv::vmobj_service::stop_one() {
    assert_equal "$*" "image 1234567890"
  }
  vedv::hypervisor::modifyvm() {
    assert_equal "$*" "image:image123|crc:1234567890 4 1024"
  }

  run vedv::vmobj_service::modify_system \
    "$type" "$vmobj_id" "$cpus" "$memory"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::change_users_password()
@test "vedv::vmobj_service::change_users_password() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id="1234567890"
  local -r new_passw="vedv"

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_service::change_users_password() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""
  local -r new_passw="vedv"

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::change_users_password() Should fail With empty new_passw" {
  local -r type="container"
  local -r vmobj_id="1234567890"
  local -r new_passw=""

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_failure
  assert_output "Invalid argument 'new_passw': it's empty"
}

@test "vedv::vmobj_service::change_users_password() Should fail If execute_cmd_by_id fails" {
  local -r type="container"
  local -r vmobj_id="1234567890"
  local -r new_passw="vedv"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 1234567890 vedv-change_users_password 'vedv' root <none>"
    return 1
  }

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_failure
  assert_output "Failed to change password for container: 1234567890"
}

@test "vedv::vmobj_service::change_users_password() Should fail If set_password fails" {
  local -r type="container"
  local -r vmobj_id="1234567890"
  local -r new_passw="vedv"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 1234567890 vedv-change_users_password 'vedv' root <none>"
  }
  vedv::vmobj_entity::set_password() {
    assert_equal "$*" "container 1234567890 vedv"
    return 1
  }

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_failure
  assert_output "Failed to set password for container: 1234567890"
}

@test "vedv::vmobj_service::change_users_password() Should succeed" {
  local -r type="container"
  local -r vmobj_id="1234567890"
  local -r new_passw="vedv"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 1234567890 vedv-change_users_password 'vedv' root <none>"
  }
  vedv::vmobj_entity::set_password() {
    assert_equal "$*" "container 1234567890 vedv"
  }

  run vedv::vmobj_service::change_users_password \
    "$type" "$vmobj_id" "$new_passw"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_service::fs::get_data_dictionary()
@test "vedv::vmobj_service::fs::get_data_dictionary() Should fail With invalid type" {
  local -r type="invalid"
  local -r vmobj_id=""

  run vedv::vmobj_service::fs::get_data_dictionary \
    "$type" "$vmobj_id"

  assert_failure
  assert_output --partial "Invalid type: invalid, valid types are:"
}

@test "vedv::vmobj_service::fs::get_data_dictionary() Should fail With empty vmobj_id" {
  local -r type="container"
  local -r vmobj_id=""

  run vedv::vmobj_service::fs::get_data_dictionary \
    "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::get_data_dictionary() Should fail If execute_cmd_by_id" {
  local -r type="container"
  local -r vmobj_id=""

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 1234567890 vedv-getdata_dictionary root <none>"
    return 1
  }

  run vedv::vmobj_service::fs::get_data_dictionary \
    "$type" "$vmobj_id"

  assert_failure
  assert_output "Invalid argument 'vmobj_id': it's empty"
}

@test "vedv::vmobj_service::fs::get_data_dictionary() Should succeed" {
  local -r type="container"
  local -r vmobj_id="1234567890"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "container 1234567890 vedv-getdata_dictionary root <none>"
  }

  run vedv::vmobj_service::fs::get_data_dictionary \
    "$type" "$vmobj_id"

  assert_success
  assert_output ""
}
