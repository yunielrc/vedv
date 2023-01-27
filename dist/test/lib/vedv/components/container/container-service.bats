# shellcheck disable=SC2016
load test_helper

setup_file() {
  vedv::container_service::constructor 'virtualbox'
  vedv::image_service::constructor 'virtualbox'

  export __VEDV_CONTAINER_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
}

teardown() {
  delete_vms_by_partial_vm_name "$VM_TAG"
  delete_vms_by_partial_vm_name 'image:alpine-x86_64|crc:87493131'
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
  echo "container:${container_name}-${VM_TAG}|crc:${crc_sum}"
}

@test "vedv::container_service::__gen_container_vm_name_from_image_vm_name(), with 'image_vm_name' unset should throw an error" {
  run vedv::container_service::__gen_container_vm_name_from_image_vm_name

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::container_service::__gen_container_vm_name_from_image_vm_name(), should generate the name" {
  local image_vm_name='image:base-image|crc:261268494'
  run vedv::container_service::__gen_container_vm_name_from_image_vm_name "$image_vm_name"

  assert_success
  assert_output 'container:base-image|crc:261268494'
}

@test "vedv::container_service::__gen_container_vm_name(), should generate the name" {
  petname() { echo 'tintin-pet'; }
  run vedv::container_service::__gen_container_vm_name

  assert_success
  assert_output 'container:tintin-pet|crc:1823374605'
}

@test "vedv::container_service::__gen_container_vm_name(), with name, should generate the name" {
  local -r container_name='rinti-love'
  run vedv::container_service::__gen_container_vm_name "$container_name"

  assert_success
  assert_output 'container:rinti-love|crc:1085124909'
}

@test 'vedv::container_service::_get_container_name(), should print container name' {
  local -r container_vm_name='container:lala-lolo|crc:1234567'

  run vedv::container_service::_get_container_name "$container_vm_name"

  assert_output 'lala-lolo'
}

@test 'vedv::container_service::_get_container_id(), should print container id' {
  local -r container_vm_name='container:lala-lolo|crc:1234567'

  run vedv::container_service::_get_container_id "$container_vm_name"

  assert_output '1234567'
}

@test "vedv::container_service::create(), with name unset, should throw an error" {
  run vedv::container_service::create

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::container_service::create(), should create a container vm" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name="na-${VM_TAG}"
  run vedv::container_service::create "$image" "$container_name"

  assert_success
  assert_output "na-${VM_TAG}"
}

@test "vedv::container_service::create(), should throw error if there is another container with the same name" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name="dyli-${VM_TAG}"

  vedv::container_service::create "$image" "$container_name"
  run vedv::container_service::create "$image" "$container_name"

  assert_failure 80
  assert_output "container with name: 'dyli-${VM_TAG}' already exist"
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
  vedv::virtualbox::list_wms_by_partial_name() { echo 'container:dyli|crc:1234567'; }
  vedv::virtualbox::stop() { return 1; }

  run vedv::container_service::__execute_operation_upon_containers stop '3582343034' '3582343035'

  assert_failure 81
  assert_output --partial 'Failed to stop containers: 3582343034 3582343035 '
}

@test 'vedv::container_service::__execute_operation_upon_containers(), should execute operations on containers' {
  local -r container_name='dyli'
  vedv::virtualbox::list_wms_by_partial_name() { echo 'container:dyli|crc:1234567'; }
  vedv::virtualbox::start() { return 0; }

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

@test "vedv::container_service::list(), With $(list_all=true) Should show all containers" {
  local -r container_name1='ct1'
  local -r container_name2='ct2'

  create_container_vm "$container_name1"
  create_container_vm "$container_name2"

  run vedv::container_service::list true

  assert_success
  assert_output --regexp "^[0-9]+\s+${container_name1}-${VM_TAG}\$
^[0-9]+\s+${container_name2}-${VM_TAG}\$"
}

@test "vedv::container_service::list(), With $(list_all=true) and $(partial_name=value) Should show only containers With that name" {
  local -r container_name1='ct1'
  local -r container_name2="ct2"
  local -r vm_name1="$(create_container_vm "$container_name1")"
  create_container_vm "$container_name2"

  run vedv::container_service::list true "$container_name1"

  assert_success
  assert_output --regexp "^[0-9]+\s+${container_name1}-${VM_TAG}\$"
}
