load test_helper

# Test vedv::image_cache_entity::constructor()
@test 'vedv::image_cache_entity::constructor() Succeed' {
  :
}

# Test vedv::image_cache_entity::validate_vm_name()
@test "vedv::image_cache_entity::validate_vm_name() prints error message for empty vm name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::image_cache_entity::validate_vm_name "$name"
  # Assert
  assert_failure
}

@test "vedv::image_cache_entity::validate_vm_name() returns 1 for invalid vm name: foo_bar" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::image_cache_entity::validate_vm_name "$name"
  # Assert
  assert_failure
}

@test "vedv::image_cache_entity::validate_vm_name() returns 0 for valid vm name" {
  # Arrange
  local -r name="image-cache|crc:123456|"
  # Act
  run vedv::image_cache_entity::validate_vm_name "$name"
  # Assert
  assert_success
  assert_output ""
}

# Test for vedv::image_cache_entity::get_vm_name()
@test "vedv::image_cache_entity::get_vm_name() Should throw an error With empty 'image_id'" {
  run vedv::image_cache_entity::get_vm_name ""

  assert_failure "$ERR_INVAL_ARG"
}

@test "vedv::image_cache_entity::get_vm_name() Should throw an error With invalid 'image_id'" {
  run vedv::image_cache_entity::get_vm_name "-aab"

  assert_failure "$ERR_INVAL_ARG"
}

@test "vedv::image_cache_entity::get_vm_name() Should success" {
  vedv::hypervisor::list_vms_by_partial_name() {
    echo "image-cache${1}"
  }

  run vedv::image_cache_entity::get_vm_name "12345678"

  assert_success
  assert_output 'image-cache|crc:12345678|'
}

# Test vedv::image_cache_entity::get_image_id_by_vm_name()
@test "vedv::image_cache_entity::get_image_id_by_vm_name() returns error for empty vm name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::image_cache_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::image_cache_entity::get_image_id_by_vm_name() returns error for invalid vm name" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::image_cache_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid image vm name: 'foo_bar'"
}

@test "vedv::image_cache_entity::get_image_id_by_vm_name() returns image id for valid vm name" {
  # Arrange
  local -r name="image-cache|crc:123456|"
  # Act
  run vedv::image_cache_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_success
  assert_output "123456"
}
