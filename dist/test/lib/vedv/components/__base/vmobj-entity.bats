# shellcheck disable=SC2317

load test_helper

setup_file() {
  vedv::vmobj_entity::constructor \
    'container|image' \
    '([image]="image_cache|ova_file_sum|ssh_port" [container]="parent_image_id|ssh_port")' \
    "$TEST_SSH_USER"

  export __VEDV_VMOBJ_ENTITY_TYPE
  export __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR
  export __VEDV_DEFAULT_USER
}

# Test vedv::vmobj_entity::constructor()
@test 'vedv::vmobj_entity::constructor() Succeed' {
  :
}

# Tests for vedv::vmobj_entity::validate_type()

@test "vedv::vmobj_entity::validate_type() Should fail with empty type" {
  local -r type=""

  run vedv::vmobj_entity::validate_type "$type"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_entity::validate_type() Should fail with invalid type" {
  local -r type="invalid_type"

  run vedv::vmobj_entity::validate_type "$type"

  assert_failure
  assert_output "Invalid type: invalid_type, valid types are: container|image"
}

@test "vedv::vmobj_entity::validate_type() Should succeed with valid type" {
  local -r type="container"

  run vedv::vmobj_entity::validate_type "$type"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_entity::__validate_attribute()

@test "vedv::vmobj_entity::__validate_attribute() Should fail with empty type" {
  local -r type=""
  local -r attribute=""

  run vedv::vmobj_entity::__validate_attribute "$type" "$attribute"

  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_entity::__validate_attribute() Should fail with empty attribute" {
  local -r type="container"
  local -r attribute=""

  run vedv::vmobj_entity::__validate_attribute "$type" "$attribute"

  assert_failure
  assert_output "Argument 'attribute' must not be empty"
}

@test "vedv::vmobj_entity::__validate_attribute() Should fail with invalid attribute" {
  local -r type="container"
  local -r attribute="att1"

  run vedv::vmobj_entity::__validate_attribute "$type" "$attribute"

  assert_failure
  assert_output "Invalid attribute: att1, valid attributes are: parent_image_id|ssh_port"
}

@test "vedv::vmobj_entity::__validate_attribute() Should succeed with valid attribute" {
  local -r type="container"
  local -r attribute="parent_image_id"

  run vedv::vmobj_entity::__validate_attribute "$type" "$attribute"

  assert_success
  assert_output ""
}

# Test vedv::vmobj_entity::__validate_vm_name()

@test "vedv::vmobj_entity::__validate_vm_name() prints error message for empty vm type" {
  # Arrange
  local -r type=""
  local -r vm_name=""
  # Act
  run vedv::vmobj_entity::__validate_vm_name "$type" "$vm_name"
  # Assert
  assert_failure
  assert_output "Argument 'type' must not be empty"
}

@test "vedv::vmobj_entity::__validate_vm_name() prints error message for empty vm name" {
  # Arrange
  local -r type="container"
  local -r vm_name=""
  # Act
  run vedv::vmobj_entity::__validate_vm_name "$type" "$vm_name"
  # Assert
  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::vmobj_entity::__validate_vm_name() returns 1 for invalid vm name: foo_bar" {
  # Arrange
  local -r type="container"
  local -r name="foo_bar"
  # Act
  run vedv::vmobj_entity::__validate_vm_name "$type" "$name"
  # Assert
  assert_failure
  assert_output "Invalid container vm name: 'foo_bar'"
}

@test "vedv::vmobj_entity::__validate_vm_name() returns 0 for valid vm name" {
  # Arrange
  local -r type="container"
  local -r name="container:foo-bar|crc:123456|"
  # Act
  run vedv::vmobj_entity::__validate_vm_name "$type" "$name"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_entity::gen_vm_name()
@test "vedv::vmobj_entity::gen_vm_name() should generate a valid vm name without given container name" {
  petname() { echo "gen-foo"; }
  utils::crc_sum() { echo "12345678"; }

  run vedv::vmobj_entity::gen_vm_name 'container'

  assert_success
  assert_output "container:gen-foo|crc:12345678|"
}

@test "vedv::vmobj_entity::gen_vm_name() should generate a valid vm name with given container name" {
  local -r container_name="foo-bar"

  petname() { echo "$container_name"; }
  utils::crc_sum() { echo "12345678"; }

  run vedv::vmobj_entity::gen_vm_name 'container' "$container_name"

  assert_success
  assert_output "container:${container_name}|crc:12345678|"
}

# Tests for vedv::vmobj_entity::get_vm_name()

@test "vedv::vmobj_entity::get_vm_name() Should throw an error With empty 'container_id'" {
  run vedv::vmobj_entity::get_vm_name 'container' ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output 'Argument must not be empty'
}

@test "vedv::vmobj_entity::get_vm_name() Should throw an error With invalid 'container_id'" {
  run vedv::vmobj_entity::get_vm_name 'container' "-aab"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid argument '-aab'"
}

@test "vedv::vmobj_entity::get_vm_name() Should success" {
  vedv::hypervisor::list_vms_by_partial_name() { echo "container:foo-bar${1}"; }

  run vedv::vmobj_entity::get_vm_name 'container' "12345678"

  assert_success
  assert_output 'container:foo-bar|crc:12345678|'
}

@test "vedv::vmobj_entity::get_vm_name() Should return nothing if no vm found" {
  vedv::hypervisor::list_vms_by_partial_name() { echo ""; }

  run vedv::vmobj_entity::get_vm_name 'container' "12345678"

  assert_success
  assert_output ''
}

@test "vedv::vmobj_entity::get_vm_name() Should fails If hypervisor fails" {
  vedv::hypervisor::list_vms_by_partial_name() { return 1; }

  run vedv::vmobj_entity::get_vm_name 'container' "12345678"

  assert_failure
  assert_output 'Failed to get vm name of container: 12345678'
}

# Test for vedv::vmobj_entity::get_vm_name_by_vmobj_name()

@test "vedv::vmobj_entity::get_vm_name_by_vmobj_name() Should throw an error With empty 'container_name'" {
  run vedv::vmobj_entity::get_vm_name_by_vmobj_name 'container' ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument must not be empty"
}

@test "vedv::vmobj_entity::get_vm_name_by_vmobj_name() Should throw an error With invalid 'container_name'" {
  run vedv::vmobj_entity::get_vm_name_by_vmobj_name 'container' "-aab"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid argument '-aab'"
}

@test "vedv::vmobj_entity::get_vm_name_by_vmobj_name() Should success" {
  vedv::hypervisor::list_vms_by_partial_name() { echo "${1}crc:12345678|"; }

  run vedv::vmobj_entity::get_vm_name_by_vmobj_name 'container' "foo-bar"

  assert_success
  assert_output 'container:foo-bar|crc:12345678|'
}

@test "vedv::vmobj_entity::get_vm_name_by_vmobj_name() Should return nothing if no vm found" {
  vedv::hypervisor::list_vms_by_partial_name() { echo ""; }

  run vedv::vmobj_entity::get_vm_name_by_vmobj_name 'container' "foo-bar"

  assert_success
  assert_output ''
}

@test "vedv::vmobj_entity::get_vm_name_by_vmobj_name() Should fails If hypervisor fails" {
  vedv::hypervisor::list_vms_by_partial_name() { return 1; }

  run vedv::vmobj_entity::get_vm_name_by_vmobj_name 'container' "foo-bar"

  assert_failure
  assert_output 'Failed to get vm name of container: foo-bar'
}

# Test vedv::vmobj_entity::get_vmobj_name_by_vm_name()

@test "vedv::vmobj_entity::get_vmobj_name_by_vm_name() prints error message for empty vm name" {
  # Act
  run vedv::vmobj_entity::get_vmobj_name_by_vm_name 'container' ""
  # Assert
  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::vmobj_entity::get_vmobj_name_by_vm_name() returns container name for valid vm name" {
  # Arrange
  local -r container_vm_name="container:foo-bar|crc:123456|"
  # Act
  run vedv::vmobj_entity::get_vmobj_name_by_vm_name 'container' "$container_vm_name"
  # Assert
  assert_success
  assert_output "foo-bar"
}

# Test vedv::vmobj_entity::get_vmobj_id_by_vm_name()

@test "vedv::vmobj_entity::get_vmobj_id_by_vm_name() returns error for empty vm name" {
  # Act
  run vedv::vmobj_entity::get_vmobj_id_by_vm_name 'container' ""
  # Assert
  assert_failure
  assert_output "Argument 'vm_name' must not be empty"
}

@test "vedv::vmobj_entity::get_vmobj_id_by_vm_name() returns error for invalid vm name" {
  # Arrange
  local -r vm_name="foo_bar"
  # Act
  run vedv::vmobj_entity::get_vmobj_id_by_vm_name 'container' "$vm_name"
  # Assert
  assert_failure
  assert_output "Invalid container vm name: 'foo_bar'"
}

@test "vedv::vmobj_entity::get_vmobj_id_by_vm_name() returns container id for valid vm name" {
  # Arrange
  local -r vm_name="container:foo-bar|crc:123456|"
  # Act
  run vedv::vmobj_entity::get_vmobj_id_by_vm_name 'container' "$vm_name"
  # Assert
  assert_success
  assert_output "123456"
}

# Test vedv::vmobj_entity::get_id_by_vmobj_name()
@test "vedv::vmobj_entity::get_id_by_vmobj_name() returns error for empty container name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::vmobj_entity::get_id_by_vmobj_name 'container' "$name"
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::vmobj_entity::get_id_by_vmobj_name() returns error for invalid container name" {
  # Arrange
  local -r name="foo/bar"
  # Act
  run vedv::vmobj_entity::get_id_by_vmobj_name 'container' "$name"
  # Assert
  assert_failure
  assert_output "Invalid argument 'foo/bar'"
}

@test "vedv::vmobj_entity::get_id_by_vmobj_name() Should fail if doesn't exist a vm with the given container name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::vmobj_entity::get_vm_name_by_vmobj_name() { echo ''; }
  # Act
  run vedv::vmobj_entity::get_id_by_vmobj_name 'container' "$name"
  # Assert
  assert_failure
  assert_output "Container with name 'foo-bar' not found"
}

@test "vedv::vmobj_entity::get_id_by_vmobj_name() returns container id for valid container name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::vmobj_entity::get_vm_name_by_vmobj_name() {
    echo "container:${1}|crc:123456|"
  }
  # Act
  run vedv::vmobj_entity::get_id_by_vmobj_name 'container' "$name"
  # Assert
  assert_success
  assert_output "123456"
}

# Tests for vedv::vmobj_entity::get_dictionary()

@test "vedv::vmobj_entity::get_dictionary() Should fail With invalid type" {
  # Setup
  local -r type="invalid"
  local -r vmobj_id="12345"
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail With invalid vmobj_id" {
  # Setup
  local -r type="container"
  local -r vmobj_id=""
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Argument must not be empty"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail If get_vm_name fails" {
  # Setup
  local -r type="container"
  local -r vmobj_id="67890"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 67890"
    return 1
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Error getting the vm name for the container: '67890'"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail With empty vm_name" {
  # Setup
  local -r type="container"
  local -r vmobj_id="67890"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 67890"
    echo ""
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Vm name for the container: '67890' is empty"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail If getting description fails" {
  # Setup
  local -r type="container"
  local -r vmobj_id="23456"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 23456"
    echo "container:foo-bar|crc:23456|"
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" "container:foo-bar|crc:23456|"
    return 1
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Error getting the description for the vm name: 'container:foo-bar|crc:23456|'"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail If description is empty" {
  # Setup
  local -r type="container"
  local -r vmobj_id="23456"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 23456"
    echo "container:foo-bar|crc:23456|"
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" "container:foo-bar|crc:23456|"
    echo ""
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Description for the vm name: 'container:foo-bar|crc:23456|' is empty"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail If dictionary is empty" {
  # Setup
  local -r type="container"
  local -r vmobj_id="23456"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 23456"
    echo "container:foo-bar|crc:23456|"
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" "container:foo-bar|crc:23456|"
    echo '()'
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Empty dictionary for the vm name: 'container:foo-bar|crc:23456|'"
}

@test "vedv::vmobj_entity::get_dictionary() Should fail If get_vmobj_name_by_vm_name fails" {
  # Setup
  local -r type="container"
  local -r vmobj_id="23456"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 23456"
    echo "container:foo-bar|crc:23456|"
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" "container:foo-bar|crc:23456|"
    echo '([parent_image_id]="alpine1" [ssh_port]=22)'
  }
  vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
    assert_equal "$*" "container container:foo-bar|crc:23456|"
    return 1
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_failure
  assert_output "Error getting the vmobj name for the vm name: 'container:foo-bar|crc:23456|'"
}

@test "vedv::vmobj_entity::get_dictionary() Should succeed" {
  # Setup
  local -r type="container"
  local -r vmobj_id="23456"
  # Stub
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container 23456"
    echo "container:foo-bar|crc:23456|"
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" "container:foo-bar|crc:23456|"
    echo '([parent_image_id]="alpine1" [ssh_port]=22)'
  }
  vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
    assert_equal "$*" "container container:foo-bar|crc:23456|"
    echo "foo-bar"
  }
  # Execute
  run vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id"
  # Assert
  assert_success
  assert_output '([type]="container" [id]="23456" [parent_image_id]="alpine1" [ssh_port]="22" [vm_name]="container:foo-bar|crc:23456|" [name]="foo-bar" )'
}

# Test vedv::vmobj_entity::__get_attribute()
@test 'vedv::vmobj_entity::__get_attribute() Should fail With invalid type' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'

  run vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" "$attribute"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test 'vedv::vmobj_entity::__get_attribute() Should fail With invalid vmobj_id' {
  local -r type='container'
  local -r vmobj_id=''
  local -r attribute='ssh_port'

  run vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" "$attribute"

  assert_failure
  assert_output "Argument must not be empty"
}

@test 'vedv::vmobj_entity::__get_attribute() Should fail With invalid attribute' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='invalid'

  run vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" "$attribute"

  assert_failure
  assert_output "Invalid attribute: invalid, valid attributes are: parent_image_id|ssh_port"
}

@test 'vedv::vmobj_entity::__get_attribute() Should fail If getting dictionary fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'

  vedv::vmobj_entity::get_dictionary() {
    assert_equal "$*" 'container 23456'
    return 1
  }

  run vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" "$attribute"

  assert_failure
  assert_output "Failed to get the dictionary for the container: '23456'"
}

@test 'vedv::vmobj_entity::__get_attribute() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'

  vedv::vmobj_entity::get_dictionary() {
    assert_equal "$*" 'container 23456'
    echo '([parent_image_id]="alpine1" [ssh_port]=22)'
  }

  run vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" "$attribute"

  assert_success
  assert_output "22"
}

# Test vedv::vmobj_entity::__set_attribute()

@test 'vedv::vmobj_entity::__set_attribute() Should fail With invalid type' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value='22'

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail With invalid vmobj_id' {
  local -r type='container'
  local -r vmobj_id=''
  local -r attribute='ssh_port'
  local -r value='22'

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Argument must not be empty"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail With invalid attribute' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='invalid'
  local -r value='22'

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Invalid attribute: invalid, valid attributes are: parent_image_id|ssh_port"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If get_vm_name fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=22

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    return 1
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Error getting the vm name for the container: '23456'"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If vm_name is empty' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=22

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Vm name for the container: '23456' is empty"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If get_description fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=22

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
    return 1
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Error getting the description for the vm name: 'container:foo-foo|crc:23456|'"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If __create_new_vmobj_dict fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=22

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
  }
  vedv::vmobj_entity::__create_new_vmobj_dict() {
    assert_equal "$*" 'container'
    return 1
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Failed to create a new vmobj dictionary for the container: '23456'"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If dictionary has invalid syntax' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=22

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
    echo '([parent_image_id]="alpine1" [ssh_port]=22'
  }
  vedv::vmobj_entity::__get_valid_attributes() {
    assert_equal "$*" 'INVALID_CALL'
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output --partial "eval:"
}

@test 'vedv::vmobj_entity::__set_attribute() Should fail If set_description fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=2022

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
    echo '([parent_image_id]="alpine1" [ssh_port]=22)'
  }
  vedv::vmobj_entity::__get_valid_attributes() {
    assert_equal "$*" 'INVALID_CALL'
  }
  vedv::hypervisor::set_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456| ([parent_image_id]="alpine1" [ssh_port]="2022" )'
    return 1
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_failure
  assert_output "Failed to set description of vm: container:foo-foo|crc:23456|"
}

@test 'vedv::vmobj_entity::__set_attribute() Should succeed With existing dictionary' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=2022

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
    echo '([parent_image_id]="alpine1" [ssh_port]=22)'
  }
  vedv::vmobj_entity::__get_valid_attributes() {
    assert_equal "$*" 'INVALID_CALL'
  }
  vedv::hypervisor::set_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456| ([parent_image_id]="alpine1" [ssh_port]="2022" )'
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_success
  assert_output ""
}

@test 'vedv::vmobj_entity::__set_attribute() Should succeed With new dictionary' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r attribute='ssh_port'
  local -r value=2022

  vedv::vmobj_entity::__validate_attribute() {
    assert_equal "$*" 'container ssh_port'
  }
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" 'container 23456'
    echo 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::get_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456|'
  }
  vedv::hypervisor::set_description() {
    assert_equal "$*" 'container:foo-foo|crc:23456| ([parent_image_id]="" [ssh_port]="2022" )'
  }

  run vedv::vmobj_entity::__set_attribute "$type" "$vmobj_id" "$attribute" "$value"

  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_entity::__create_new_vmobj_dict()
@test 'vedv::vmobj_entity::__create_new_vmobj_dict() Should fail With invalid type' {
  local -r type='invalid'

  run vedv::vmobj_entity::__create_new_vmobj_dict "$type"

  assert_failure
  assert_output "Invalid type: invalid, valid types are: container|image"
}

@test 'vedv::vmobj_entity::__create_new_vmobj_dict() Should fail If __get_valid_attributes fails' {
  local -r type='container'

  vedv::vmobj_entity::__get_valid_attributes() {
    assert_equal "$*" 'container'
    return 1
  }

  run vedv::vmobj_entity::__create_new_vmobj_dict "$type"

  assert_failure
  assert_output "Failed to get the valid attributes for container"
}

@test 'vedv::vmobj_entity::__create_new_vmobj_dict() Should succeed' {
  local -r type='container'

  run vedv::vmobj_entity::__create_new_vmobj_dict "$type"

  assert_success
  assert_output '([parent_image_id]="" [ssh_port]="" )'
}

# Test vedv::vmobj_entity::set_ssh_port()

@test 'vedv::vmobj_entity::set_ssh_port() Should fail If __set_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 ssh_port 2022'
    return 1
  }

  run vedv::vmobj_entity::set_ssh_port "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::set_ssh_port() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 ssh_port 2022'
  }

  run vedv::vmobj_entity::set_ssh_port "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::get_ssh_port()

@test 'vedv::vmobj_entity::get_ssh_port() Should fail If __get_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 ssh_port'
    return 1
  }

  run vedv::vmobj_entity::get_ssh_port "$type" "$vmobj_id"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::get_ssh_port() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 ssh_port'
  }

  run vedv::vmobj_entity::get_ssh_port "$type" "$vmobj_id"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::set_user_name()

@test 'vedv::vmobj_entity::cache::set_user_name() Should fail If __set_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 user_name 2022'
    return 1
  }

  run vedv::vmobj_entity::cache::set_user_name "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::set_user_name() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 user_name 2022'
  }

  run vedv::vmobj_entity::cache::set_user_name "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::get_user_name()

@test 'vedv::vmobj_entity::cache::get_user_name() Should fail If __get_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 user_name'
    return 1
  }

  run vedv::vmobj_entity::cache::get_user_name "$type" "$vmobj_id"

  assert_failure
  assert_output "Failed to get user name of the vmobj: ${vmobj_id}"
}

@test 'vedv::vmobj_entity::cache::get_user_name() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 user_name'
  }

  run vedv::vmobj_entity::cache::get_user_name "$type" "$vmobj_id"

  assert_success
  assert_output 'vedv'
}

# Test vedv::vmobj_entity::cache::set_workdir()

@test 'vedv::vmobj_entity::cache::set_workdir() Should fail If __set_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 workdir 2022'
    return 1
  }

  run vedv::vmobj_entity::cache::set_workdir "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::set_workdir() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'invalid 23456 workdir 2022'
  }

  run vedv::vmobj_entity::cache::set_workdir "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::get_workdir()

@test 'vedv::vmobj_entity::cache::get_workdir() Should fail If __get_attribute fails' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 workdir'
    return 1
  }

  run vedv::vmobj_entity::cache::get_workdir "$type" "$vmobj_id"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::get_workdir() Should succeed' {
  local -r type='invalid'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'invalid 23456 workdir'
  }

  run vedv::vmobj_entity::cache::get_workdir "$type" "$vmobj_id"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::set_environment()

@test 'vedv::vmobj_entity::cache::set_environment() Should fail If __set_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 environment 2022'
    return 1
  }

  run vedv::vmobj_entity::cache::set_environment "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::set_environment() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 environment 2022'
  }

  run vedv::vmobj_entity::cache::set_environment "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::get_environment()

@test 'vedv::vmobj_entity::cache::get_environment() Should fail If __get_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 environment'
    return 1
  }

  run vedv::vmobj_entity::cache::get_environment "$type" "$vmobj_id"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::get_environment() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 environment'
  }

  run vedv::vmobj_entity::cache::get_environment "$type" "$vmobj_id"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::set_exposed_ports()

@test 'vedv::vmobj_entity::cache::set_exposed_ports() Should fail If __set_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 exposed_ports 2022'
    return 1
  }

  run vedv::vmobj_entity::cache::set_exposed_ports "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::set_exposed_ports() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 exposed_ports 2022'
  }

  run vedv::vmobj_entity::cache::set_exposed_ports "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::get_exposed_ports()

@test 'vedv::vmobj_entity::cache::get_exposed_ports() Should fail If __get_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 exposed_ports'
    return 1
  }

  run vedv::vmobj_entity::cache::get_exposed_ports "$type" "$vmobj_id"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::get_exposed_ports() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 exposed_ports'
  }

  run vedv::vmobj_entity::cache::get_exposed_ports "$type" "$vmobj_id"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::set_shell()

@test 'vedv::vmobj_entity::cache::set_shell() Should fail If __set_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 shell 2022'
    return 1
  }

  run vedv::vmobj_entity::cache::set_shell "$type" "$vmobj_id" "$value"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::set_shell() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'
  local -r value=2022

  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" 'container 23456 shell 2022'
  }

  run vedv::vmobj_entity::cache::set_shell "$type" "$vmobj_id" "$value"

  assert_success
  assert_output ''
}

# Test vedv::vmobj_entity::cache::get_shell()

@test 'vedv::vmobj_entity::cache::get_shell() Should fail If __get_attribute fails' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 shell'
    return 1
  }

  run vedv::vmobj_entity::cache::get_shell "$type" "$vmobj_id"

  assert_failure
  assert_output ''
}

@test 'vedv::vmobj_entity::cache::get_shell() Should succeed' {
  local -r type='container'
  local -r vmobj_id='23456'

  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" 'container 23456 shell'
  }

  run vedv::vmobj_entity::cache::get_shell "$type" "$vmobj_id"

  assert_success
  assert_output ''
}
