# shellcheck disable=SC2317

load test_helper

setup_file() {
  vedv::container_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_CONTAINER_ENTITY_HYPERVISOR
}

# Test vedv::container_entity::constructor()
@test 'vedv::container_entity::constructor() Succeed' {
  :
}

# Test vedv::container_entity::__validate_vm_name()

@test "vedv::container_entity::__validate_vm_name() prints error message for empty vm name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::container_entity::__validate_vm_name "$name"
  # Assert
  assert_failure
}

@test "vedv::container_entity::__validate_vm_name() returns 1 for invalid vm name: foo_bar" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::container_entity::__validate_vm_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid container vm name: 'foo_bar'"
}

@test "vedv::container_entity::__validate_vm_name() returns 0 for valid vm name" {
  # Arrange
  local -r name="container:foo-bar|crc:123456|"
  # Act
  run vedv::container_entity::__validate_vm_name "$name"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::container_entity::gen_vm_name()
@test "vedv::container_entity::gen_vm_name() should generate a valid vm name without give container name" {
  petname() { echo "gen-foo"; }
  utils::crc_sum() { echo "12345678"; }

  run vedv::container_entity::gen_vm_name

  assert_success
  assert_output "container:gen-foo|crc:12345678|"
}

@test "vedv::container_entity::gen_vm_name() should generate a valid vm name with given container name" {
  local -r container_name="foo-bar"

  petname() { echo "$container_name"; }
  utils::crc_sum() { echo "12345678"; }

  run vedv::container_entity::gen_vm_name "$container_name"

  assert_success
  assert_output "container:${container_name}|crc:12345678|"
}

# Tests for vedv::container_entity::get_vm_name()

@test "vedv::container_entity::get_vm_name() Should throw an error With empty 'container_id'" {
  run vedv::container_entity::get_vm_name ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output 'Argument must not be empty'
}

@test "vedv::container_entity::get_vm_name() Should throw an error With invalid 'container_id'" {
  run vedv::container_entity::get_vm_name "-aab"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid argument '-aab'"
}

@test "vedv::container_entity::get_vm_name() Should success" {
  vedv::virtualbox::list_wms_by_partial_name() { echo "container:foo-bar${1}"; }

  run vedv::container_entity::get_vm_name "12345678"

  assert_success
  assert_output 'container:foo-bar|crc:12345678|'
}

@test "vedv::container_entity::get_vm_name() Should return nothing if no vm found" {
  vedv::virtualbox::list_wms_by_partial_name() { echo ""; }

  run vedv::container_entity::get_vm_name "12345678"

  assert_success
  assert_output ''
}

@test "vedv::container_entity::get_vm_name() Should fails If hypervisor fails" {
  vedv::virtualbox::list_wms_by_partial_name() { return 1; }

  run vedv::container_entity::get_vm_name "12345678"

  assert_failure
  assert_output 'Failed to get vm name of container: 12345678'
}

# Test for vedv::container_entity::get_vm_name_by_container_name()

@test "vedv::container_entity::get_vm_name_by_container_name() Should throw an error With empty 'container_name'" {
  run vedv::container_entity::get_vm_name_by_container_name ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument must not be empty"
}

@test "vedv::container_entity::get_vm_name_by_container_name() Should throw an error With invalid 'container_name'" {
  run vedv::container_entity::get_vm_name_by_container_name "-aab"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid argument '-aab'"
}

@test "vedv::container_entity::get_vm_name_by_container_name() Should success" {
  vedv::virtualbox::list_wms_by_partial_name() { echo "${1}crc:12345678|"; }

  run vedv::container_entity::get_vm_name_by_container_name "foo-bar"

  assert_success
  assert_output 'container:foo-bar|crc:12345678|'
}

@test "vedv::container_entity::get_vm_name_by_container_name() Should return nothing if no vm found" {
  vedv::virtualbox::list_wms_by_partial_name() { echo ""; }

  run vedv::container_entity::get_vm_name_by_container_name "foo-bar"

  assert_success
  assert_output ''
}

@test "vedv::container_entity::get_vm_name_by_container_name() Should fails If hypervisor fails" {
  vedv::virtualbox::list_wms_by_partial_name() { return 1; }

  run vedv::container_entity::get_vm_name_by_container_name "foo-bar"

  assert_failure
  assert_output 'Failed to get vm name of container: foo-bar'
}

# Test vedv::container_entity::get_container_name_by_vm_name()

@test "vedv::container_entity::get_container_name_by_vm_name() prints error message for empty vm name" {
  # Act
  run vedv::container_entity::get_container_name_by_vm_name ""
  # Assert
  assert_failure
  assert_output "Argument must not be empty"
}

@test "vedv::container_entity::get_container_name_by_vm_name() returns container name for valid vm name" {
  # Arrange
  local -r container_vm_name="container:foo-bar|crc:123456|"
  # Act
  run vedv::container_entity::get_container_name_by_vm_name "$container_vm_name"
  # Assert
  assert_success
  assert_output "foo-bar"
}

# Test vedv::container_entity::get_container_id_by_vm_name()
@test "vedv::container_entity::get_container_id_by_vm_name() returns error for empty vm name" {
  # Act
  run vedv::container_entity::get_container_id_by_vm_name ""
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::container_entity::get_container_id_by_vm_name() returns error for invalid vm name" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::container_entity::get_container_id_by_vm_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid container vm name: 'foo_bar'"
}

@test "vedv::container_entity::get_container_id_by_vm_name() returns container id for valid vm name" {
  # Arrange
  local -r name="container:foo-bar|crc:123456|"
  # Act
  run vedv::container_entity::get_container_id_by_vm_name "$name"
  # Assert
  assert_success
  assert_output "123456"
}

# Test vedv::container_entity::get_id_by_container_name()

@test "vedv::container_entity::get_id_by_container_name() returns error for empty container name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::container_entity::get_id_by_container_name "$name"
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::container_entity::get_id_by_container_name() returns error for invalid container name" {
  # Arrange
  local -r name="foo/bar"
  # Act
  run vedv::container_entity::get_id_by_container_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid argument 'foo/bar'"
}

@test "vedv::container_entity::get_id_by_container_name() Should fail if doesn't exist a vm with the given container name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::container_entity::get_vm_name_by_container_name() { echo ''; }
  # Act
  run vedv::container_entity::get_id_by_container_name "$name"
  # Assert
  assert_failure
  assert_output "Container with name 'foo-bar' not found"
}

@test "vedv::container_entity::get_id_by_container_name() returns Container id for valid Container name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::container_entity::get_vm_name_by_container_name() {
    echo "container:${1}|crc:123456|"
  }
  # Act
  run vedv::container_entity::get_id_by_container_name "$name"
  # Assert
  assert_success
  assert_output "123456"
}
