# shellcheck disable=SC2016
load test_helper

setup_file() {
  vedv::container_service::constructor 'virtualbox'
  vedv::image_service::constructor 'virtualbox'

  export __VEDV_CONTAINER_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
}

teardown() {
  delete_vms_by_partial_vm_name 'testunit-container-service'
  delete_vms_by_partial_vm_name 'image:alpine-x86_64|crc:87493131'
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

@test "vedv::container_service::__gen_container_vm_name, should generate the name" {
  petname() { echo 'tintin-pet'; }
  run vedv::container_service::__gen_container_vm_name

  assert_success
  assert_output 'container:tintin-pet|crc:1823374605'
}

@test "vedv::container_service::__gen_container_vm_name, with name, should generate the name" {
  local -r container_name='rinti-love'
  run vedv::container_service::__gen_container_vm_name "$container_name"

  assert_success
  assert_output 'container:rinti-love|crc:1085124909'
}

@test "vedv::container_service::create, with name unset, should throw an error" {
  run vedv::container_service::create

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::container_service::create, should create a container vm" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name='happy-dyli-testunit-container-service'
  run vedv::container_service::create "$image" "$container_name"

  assert_success
  assert_output 'container:happy-dyli-testunit-container-service|crc:2520159523'
}

@test "vedv::container_service::create, should throw error if there is another container with the same name" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name='happy-dyli-testunit-container-service'

  vedv::container_service::create "$image" "$container_name"
  run vedv::container_service::create "$image" "$container_name"

  assert_failure 80
  assert_output "container with name: 'happy-dyli-testunit-container-service' already exist"
}
