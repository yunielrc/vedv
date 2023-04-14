# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  delete_vms_directory

  vedv::image_service::constructor "$TEST_HYPERVISOR" "$TEST_SSH_IP"
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_SERVICE_SSH_IP
  vedv::image_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_ENTITY_HYPERVISOR
}

teardown() {
  delete_vms_by_partial_vm_name "$VM_TAG"
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name "image-cache|"
}

create_container_vm() {
  create_vm "$(gen_container_vm_name "$1")"
}

gen_container_vm_name() {
  local container_name="${1:-}"

  if [[ -z "$container_name" ]]; then
    container_name="$(petname)"
  fi

  local -r crc_sum="$(echo "${container_name}-${VM_TAG}" | cksum | cut -d' ' -f1)"
  echo "container:${container_name}-${VM_TAG}|crc:${crc_sum}|"
}

# Tests for vedv::container_service::create()
@test "vedv::container_service::create(), with name unset, should throw an error" {
  run vedv::container_service::create

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::container_service::create(), should create a container vm" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name="na-${VM_TAG}"

  eval "vedv::${TEST_HYPERVISOR}::get_description(){ :; }"
  eval "vedv::${TEST_HYPERVISOR}::delete_snapshot(){ :; }"

  run vedv::container_service::create "$image" "$container_name"

  assert_success
  assert_output --partial "na-${VM_TAG}"
}

@test "vedv::container_service::create(), should throw error if there is another container with the same name" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name="dyli-${VM_TAG}"

  vedv::hypervisor::get_description() { :; }
  vedv::hypervisor::delete_snapshot() { :; }

  vedv::container_service::create "$image" "$container_name"
  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Container with name: 'dyli-${VM_TAG}' already exist"
}

@test 'vedv::container_service::__execute_operation_upon_containers(), without params should throw an error' {
  run vedv::container_service::__execute_operation_upon_containers

  assert_failure 69
  assert_output "Invalid argument 'operation': it's empty"
}

@test 'vedv::container_service::__execute_operation_upon_containers(), With invalid operation Should throw an error ' {
  run vedv::container_service::__execute_operation_upon_containers 'invalid_operation'

  assert_failure 69
  assert_output 'Invalid operation: invalid_operation, valid operations are: start|stop|rm'
}

@test 'vedv::container_service::__execute_operation_upon_containers(), With 2 non-existent containers Should throw an error' {
  run vedv::container_service::__execute_operation_upon_containers start '3582343034' '3582343035'

  assert_failure 81
  assert_output --partial 'No such containers: 3582343034 3582343035 '
}

@test 'vedv::container_service::__execute_operation_upon_containers(), if hypervisor fail should throw an error' {
  # shellcheck disable=SC2317
  vedv::hypervisor::list_vms_by_partial_name() { echo 'container:dyli|crc:12345'; }
  vedv::hypervisor::stop() { return 1; }

  run vedv::container_service::__execute_operation_upon_containers stop '3582343034' '3582343035'

  assert_failure 81
  assert_output --partial 'Failed to stop containers: 3582343034 3582343035 '
}

@test 'vedv::container_service::__execute_operation_upon_containers(), should execute operations on containers' {
  local -r container_name='dyli'

  vedv::hypervisor::list_vms_by_partial_name() { echo 'container:dyli|crc:12345'; }
  vedv::hypervisor::start() { :; }

  run vedv::container_service::__execute_operation_upon_containers start "$container_name"

  assert_success
  assert_output 'dyli '
}

@test 'vedv::container_service::start(), should start containers' {
  # shellcheck disable=SC2317
  vedv::container_service::__execute_operation_upon_containers() {
    echo "$*"
  }
  run vedv::container_service::start 'container1' 'container2'

  assert_success
  assert_output 'start container1 container2'
}

@test 'vedv::container_service::stop(), should stop containers' {
  # shellcheck disable=SC2317
  vedv::container_service::__execute_operation_upon_containers() {
    echo "$*"
  }
  run vedv::container_service::stop 'container1' 'container2'

  assert_success
  assert_output 'stop container1 container2'
}

@test 'vedv::container_service::rm(), should remove containers' {
  # shellcheck disable=SC2317
  vedv::container_service::__execute_operation_upon_containers() {
    echo "$*"
  }
  run vedv::container_service::rm 'container1' 'container2'

  assert_success
  assert_output 'rm container1 container2'
}

@test "vedv::container_service::list(), Should show anything" {

  run vedv::container_service::list

  assert_success
  assert_output ''
}

@test "vedv::container_service::list(), With 'list_all=false' Should show only running vms" {
  local -r container_name1='ct1'
  local -r container_name2="ct2"
  local -r vm_name1="$(create_container_vm "$container_name1")"
  create_container_vm "$container_name2"

  VBoxManage startvm "$vm_name1" --type headless
  run vedv::container_service::list

  assert_success
  assert_output --regexp "^[0-9]+\s+${container_name1}-${VM_TAG}\$"
}

@test "vedv::container_service::list(), With list_all=true Should show all containers" {
  skip
  local -r container_name1='ct1'
  local -r container_name2='ct2'

  create_container_vm "$container_name1"
  create_container_vm "$container_name2"

  run vedv::container_service::list true

  assert_success
  assert_output --regexp "^[0-9]+\s+${container_name1}-${VM_TAG}\$
^[0-9]+\s+${container_name2}-${VM_TAG}\$"
}

@test "vedv::container_service::list(), With list_all=true and partial_name=value Should show only containers With that name" {
  local -r container_name1='ct1'
  local -r container_name2="ct2"
  local -r vm_name1="$(create_container_vm "$container_name1")"
  create_container_vm "$container_name2"

  run vedv::container_service::list true "$container_name1"

  assert_success
  assert_output --regexp "^[0-9]+\s+${container_name1}-${VM_TAG}\$"
}

# Tests for vedv::container_service::__exits_with_name()
# bats test_tags=only
@test "vedv::container_service::__exits_with_name() Should fails With empty container name" {
  local -r container_name=""

  run vedv::container_service::__exits_with_name "$container_name"

  assert_failure
  assert_output "Argument 'container_name' is required"
}
# bats test_tags=only
@test "vedv::container_service::__exits_with_name() Should fails If exists_vm_with_partial_name fails" {
  local -r container_name=""

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$1" "container:${container_name}|"
    return 1
  }

  run vedv::container_service::__exits_with_name "$container_name"

  assert_failure
  assert_output "Argument 'container_name' is required"
}
# bats test_tags=only
@test "vedv::container_service::__exits_with_name() Should return true if container exists" {
  local -r container_name="my_container"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$1" "container:${container_name}|"
    echo true
  }

  run vedv::container_service::__exits_with_name "$container_name"

  assert_success
  assert_output true
}
# bats test_tags=only
@test "vedv::container_service::__exits_with_name() Should return false if container does not exists" {
  local -r container_name="non_existing_container"

  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$1" "container:${container_name}|"
    echo false
  }

  run vedv::container_service::__exits_with_name "$container_name"

  assert_success
  assert_output false
}
