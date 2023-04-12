# shellcheck disable=SC2317

load test_helper

setup_file() {
  vedv::image_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_ENTITY_HYPERVISOR
}

# Test vedv::image_entity::constructor()
@test 'vedv::image_entity::constructor() Succeed' {
  :
}

# Tests for vedv::image_entity::gen_vm_name_from_ova_file()
@test "vedv::image_entity::gen_vm_name_from_ova_file(), with 'image_file' unset should throw an error" {
  run vedv::image_entity::gen_vm_name_from_ova_file

  assert_failure 1
  # shellcheck disable=SC2016
  assert_output --partial '$1: unbound variable'
}

@test "vedv::image_entity::gen_vm_name_from_ova_file(), should write the generated vm name" {
  local -r image_file="$TEST_OVA_FILE"

  run vedv::image_entity::gen_vm_name_from_ova_file "$image_file"

  assert_success
  assert_output --regexp '^image:alpine-x86_64\|crc:.*\|$'
}

# Tests for vedv::image_entity::gen_vm_name()
@test "vedv::image_entity::gen_vm_name() should generate a valid vm name" {
  local -r image_name="foo"
  local -r image_id="12345678"

  petname() { echo "$image_name"; }
  utils::crc_sum() { echo "$image_id"; }

  run vedv::image_entity::gen_vm_name "$image_name"

  assert_success
  assert_output "image:${image_name}|crc:${image_id}|"
}

@test "vedv::image_entity::gen_vm_name() should generate a valid vm name with given image name" {
  local -r image_name="foo"
  local -r image_id="12345678"

  utils::crc_sum() { echo "$image_id"; }

  run vedv::image_entity::gen_vm_name "$image_name"

  assert_success
  assert_output "image:foo|crc:${image_id}|"
}

# Tests for vedv::image_entity::get_vm_name()
@test "vedv::image_entity::get_vm_name() Should throw an error With empty 'image_id'" {
  run vedv::image_entity::get_vm_name ""

  assert_failure "$ERR_INVAL_ARG"
}

@test "vedv::image_entity::get_vm_name() Should throw an error With invalid 'image_id'" {
  run vedv::image_entity::get_vm_name "-aab"

  assert_failure "$ERR_INVAL_ARG"
}

@test "vedv::image_entity::get_vm_name() Should success" {
  eval "vedv::${__VEDV_IMAGE_ENTITY_HYPERVISOR}::list_wms_by_partial_name() { echo \"image:image1\$1\"; }"

  run vedv::image_entity::get_vm_name "12345678"

  assert_success
  assert_output 'image:image1|crc:12345678|'
}

@test "vedv::image_entity::get_vm_name_by_image_name() Should throw an error With empty 'image_id'" {
  run vedv::image_entity::get_vm_name_by_image_name ""

  assert_failure "$ERR_INVAL_ARG"
}

@test "vedv::image_entity::get_vm_name_by_image_name() Should success" {
  eval "vedv::${__VEDV_IMAGE_ENTITY_HYPERVISOR}::list_wms_by_partial_name() { echo \"\$1crc:12345678|\"; }"

  run vedv::image_entity::get_vm_name_by_image_name "image1"

  assert_success
  assert_output 'image:image1|crc:12345678|'
}

# Tests for vedv::image_entity::__set_attribute()

@test "vedv::image_entity::__set_attribute() Should fails With empty 'image_id'" {
  run vedv::image_entity::__set_attribute "" 'image_cache' 'value'

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' must not be empty"
}

@test "vedv::image_entity::__set_attribute() Should fails With empty 'attribute'" {
  run vedv::image_entity::__set_attribute 'image_id' "" 'value'

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'attribute' must not be empty"
}

@test "vedv::image_entity::__set_attribute() Should fails With invalid 'attribute'" {
  run vedv::image_entity::__set_attribute 'image_id' 'invalid' 'value'

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid attribute: invalid, valid attributes are: image_cache|ova_file_sum|ssh_port"
}

@test "vedv::image_entity::__set_attribute() Should set 'image_cache' value" {
  # Arrange
  local -r image_id='123456'
  local -r attribute='image_cache'
  local -r value='image-cache|crc:78910|'

  local -r image_name="image1"
  local -r vm_name="${image_name}:image1|crc:${image_id}|"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
  }
  vedv::virtualbox::set_description() {
    assert_equal "$*" "${vm_name} image_cache='${value}'
ova_file_sum=''
ssh_port="
  }
  # Act
  run vedv::image_entity::__set_attribute "$image_id" "$attribute" "$value"
  # Assert
  assert_success
  assert_output ""
}

@test "vedv::image_entity::__set_attribute() Should set 'ova_file_sum' value" {
  # Arrange
  local -r image_id='123456'
  local -r attribute='ova_file_sum'
  local -r value='1234567890'

  local -r image_name="image1"
  local -r vm_name="${image_name}:image1|crc:${image_id}|"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
    cat <<EOF
image_cache='image-cache|crc:78910|'
ova_file_sum=''
ssh_port=
EOF
  }
  vedv::virtualbox::set_description() {
    assert_equal "$*" "${vm_name} image_cache='image-cache|crc:78910|'
ova_file_sum='${value}'
ssh_port="
  }
  # Act
  run vedv::image_entity::__set_attribute "$image_id" "$attribute" "$value"
  # Assert
  assert_success
  assert_output ""
}

@test "vedv::image_entity::__set_attribute() Should set 'ssh_port' value" {
  # Arrange
  local -r image_id='123456'
  local -r attribute='ssh_port'
  local -ri value=2022

  local -r image_name="image1"
  local -r vm_name="${image_name}:image1|crc:${image_id}|"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
    cat <<EOF
image_cache='image-cache|crc:78910|'
ova_file_sum='1234567890'
ssh_port=
EOF
  }
  vedv::virtualbox::set_description() {
    assert_equal "$*" "${vm_name} image_cache='image-cache|crc:78910|'
ova_file_sum='1234567890'
ssh_port=${value}"
  }
  # Act
  run vedv::image_entity::__set_attribute "$image_id" "$attribute" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::validate_vm_name()
@test "vedv::image_entity::validate_vm_name() prints error message for empty vm name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::image_entity::validate_vm_name "$name"
  # Assert
  assert_failure
}

@test "vedv::image_entity::validate_vm_name() returns 1 for invalid vm name: foo_bar" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::image_entity::validate_vm_name "$name"
  # Assert
  assert_failure
}

@test "vedv::image_entity::validate_vm_name() returns 0 for valid vm name" {
  # Arrange
  local -r name="image:foo-bar|crc:123456|"
  # Act
  run vedv::image_entity::validate_vm_name "$name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::get_image_name_by_vm_name()
@test "vedv::image_entity::get_image_name_by_vm_name() prints error message for empty vm name" {
  # Arrange
  local -r image_vm_name=""

  # Act
  run vedv::image_entity::get_image_name_by_vm_name "$image_vm_name"

  # Assert
  assert_failure
  assert_output "Argument must not be empty"
}

@test "vedv::image_entity::get_image_name_by_vm_name() returns image name for valid vm name" {
  # Arrange
  local -r image_vm_name="image:foo-bar|crc:123456|"
  # Act
  run vedv::image_entity::get_image_name_by_vm_name "$image_vm_name"
  # Assert
  assert_success
  assert_output "foo-bar"
}

# Test vedv::image_entity::get_image_id_by_vm_name()
@test "vedv::image_entity::get_image_id_by_vm_name() returns error for empty vm name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::image_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::image_entity::get_image_id_by_vm_name() returns error for invalid vm name" {
  # Arrange
  local -r name="foo_bar"
  # Act
  run vedv::image_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid image vm name: 'foo_bar'"
}

@test "vedv::image_entity::get_image_id_by_vm_name() returns image id for valid vm name" {
  # Arrange
  local -r name="image:foo-bar|crc:123456|"
  # Act
  run vedv::image_entity::get_image_id_by_vm_name "$name"
  # Assert
  assert_success
  assert_output "123456"
}

# Test vedv::image_entity::get_id_by_image_name()
@test "vedv::image_entity::get_id_by_image_name() returns error for empty image name" {
  # Arrange
  local -r name=""
  # Act
  run vedv::image_entity::get_id_by_image_name "$name"
  # Assert
  assert_failure
  assert_output 'Argument must not be empty'
}

@test "vedv::image_entity::get_id_by_image_name() returns error for invalid image name" {
  # Arrange
  local -r name="foo/bar"
  # Act
  run vedv::image_entity::get_id_by_image_name "$name"
  # Assert
  assert_failure
  assert_output "Invalid argument 'foo/bar'"
}

@test "vedv::image_entity::get_id_by_image_name() Should fail if doesn't exist a vm with the given image name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::image_entity::get_vm_name_by_image_name() { echo ''; }
  # Act
  run vedv::image_entity::get_id_by_image_name "$name"
  # Assert
  assert_failure
  assert_output "Image with name 'foo-bar' not found"
}

@test "vedv::image_entity::get_id_by_image_name() returns image id for valid image name" {
  # Arrange
  local -r name="foo-bar"
  # Stub
  vedv::image_entity::get_vm_name_by_image_name() {
    echo "image:${1}|crc:123456|"
  }
  # Act
  run vedv::image_entity::get_id_by_image_name "$name"
  # Assert
  assert_success
  assert_output "123456"
}

# Test vedv::image_entity::__validate_attribute()
@test "vedv::image_entity::__validate_attribute() should return ERR_INVAL_ARG if attribute is empty" {
  run vedv::image_entity::__validate_attribute ""

  assert_failure
  assert_output "Argument 'attribute' must not be empty"
}

@test "vedv::image_entity::__validate_attribute() should return ERR_INVAL_ARG if attribute is invalid" {
  local -r attribute="foo_bar"
  run vedv::image_entity::__validate_attribute "$attribute"

  assert_failure
  assert_output "Invalid attribute: ${attribute}, valid attributes are: image_cache|ova_file_sum|ssh_port"
}

@test "vedv::image_entity::__validate_attribute() should return 0 if attribute is image_cache" {
  run vedv::image_entity::__validate_attribute image_cache
  assert_success
}

@test "vedv::image_entity::__validate_attribute() should return 0 if attribute is ova_file_sum" {
  run vedv::image_entity::__validate_attribute ova_file_sum
  assert_success
}

@test "vedv::image_entity::__validate_attribute() should return 0 if attribute is ssh_port" {
  run vedv::image_entity::__validate_attribute ssh_port
  assert_success
}

# Test vedv::image_entity::__get_attribute()
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() should return non-zero if image_id is invalid" {
  local -r image_id='foo/bar'
  local -r attribute='image_cache'

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output "Invalid argument '${image_id}'"
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() should return non-zero if attribute is invalid" {
  local -r image_id='1234'
  local -r attribute='foo_bar'

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output 'Invalid attribute: foo_bar, valid attributes are: image_cache|ova_file_sum|ssh_port'
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() Should fail On error getting vm name" {
  local -r image_id='1234'
  local -r attribute='image_cache'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output "Error getting the vm name for the image id: '1234'"
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() Should fail If doesn't exist a vm with the given image id" {
  local -r image_id='1234'
  local -r attribute='image_cache'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo ""
  }

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output "Argument must not be empty"
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() Should fail If there is a error getting the description of the vm" {
  local -r image_id='1234'
  local -r attribute='image_cache'

  local -r vm_name="image:foo-bar|crc:${image_id}|"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
    return 1
  }

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output "Error getting the description for the image vm name: 'image:foo-bar|crc:1234|'"
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() Should fail If there is no description of the vm" {
  local -r image_id='1234'
  local -r attribute='image_cache'

  local -r vm_name="image:foo-bar|crc:${image_id}|"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
    echo ""
  }

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_failure
  assert_output "Description for the image vm name: 'image:foo-bar|crc:1234|' is empty"
}
# bats test_tags=only
@test "vedv::image_entity::__get_attribute() Should succeed" {
  local -r image_id='1234'
  local -r attribute='image_cache'

  local -r vm_name="image:foo-bar|crc:${image_id}|"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "$vm_name"
  }
  vedv::virtualbox::get_description() {
    assert_equal "$*" "$vm_name"
    cat <<EOF
image_cache='image-cache|crc:123456|'
ova_file_sum='000000'
ssh_port=22
EOF
  }

  run vedv::image_entity::__get_attribute "$image_id" "$attribute"

  assert_success
  assert_output "image-cache|crc:123456|"
}

# Test vedv::image_entity::get_ova_file_sum()
@test 'vedv::image_entity::get_ova_file_sum() returns 0 and get expected value for valid image id' {
  vedv::image_entity::__get_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'ova_file_sum' ]]; then return 1; fi
    echo '1234'
  }

  run vedv::image_entity::get_ova_file_sum 'image-id'

  assert_success
  assert_output '1234'
}

# Test vedv::image_entity::set_ova_file_sum()
@test 'vedv::image_entity::set_ova_file_sum() returns 0 and writes expected value for valid image id' {
  vedv::image_entity::__set_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'ova_file_sum' || "$3" != '1234' ]]; then return 1; fi
    return 0
  }

  run vedv::image_entity::set_ova_file_sum 'image-id' '1234'

  assert_success
  assert_output ''
}

# Test vedv::image_entity::get_image_cache()
@test 'vedv::image_entity::get_image_cache() returns 0 and get expected value for valid image id' {
  vedv::image_entity::__get_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'image_cache' ]]; then return 1; fi
    echo '1234'
  }

  run vedv::image_entity::get_image_cache 'image-id'

  assert_success
  assert_output '1234'
}

# Test vedv::image_entity::set_image_cache()
@test 'vedv::image_entity::set_image_cache() returns 0 and writes expected value for valid image id' {
  vedv::image_entity::__set_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'image_cache' || "$3" != '1234' ]]; then return 1; fi
    return 0
  }

  run vedv::image_entity::set_image_cache 'image-id' '1234'

  assert_success
  assert_output ''
}

# Test vedv::image_entity::get_ssh_port()
@test 'vedv::image_entity::get_ssh_port() returns 0 and get expected value for valid image id' {
  vedv::image_entity::__get_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'ssh_port' ]]; then return 1; fi
    echo '1234'
  }

  run vedv::image_entity::get_ssh_port 'image-id'

  assert_success
  assert_output '1234'
}

# Test vedv::image_entity::set_ssh_port()
@test 'vedv::image_entity::set_ssh_port() returns 0 and writes expected value for valid image id' {
  vedv::image_entity::__set_attribute() {
    if [[ "$1" != 'image-id' || "$2" != 'ssh_port' || "$3" != '1234' ]]; then return 1; fi
    return 0
  }

  run vedv::image_entity::set_ssh_port 'image-id' '1234'

  assert_success
  assert_output ''
}

# Test vedv::image_entity::__get_snapshots_names() function
@test "vedv::image_entity::__get_snapshots_names() Should fail When 'image_id' is empty" {
  # Arrange
  local -r image_id=""
  local -r _type="layer"
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}
@test "vedv::image_entity::__get_snapshots_names() Should fail When '_type' is empty" {
  # Arrange
  local -r image_id="image_id"
  local -r _type=""
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument '_type' is required"
}

@test "vedv::image_entity::__get_snapshots_names() Should fail When '_type' is invalid" {
  # Arrange
  local -r image_id="image_id"
  local -r _type="invalid_type"
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid type: ${_type}, valid values are: container|layer"
}

@test "vedv::image_entity::__get_snapshots_names() Should fail When getting vm name fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _type="container"
  # Stubs
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get image vm name for image '${image_id}'"
}

@test "vedv::image_entity::__get_snapshots_names() Should fail When vm name is empty" {
  # Arrange
  local -r image_id="image_id"
  local -r _type="container"
  # Stubs
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
  }
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Image vm name for image '${image_id}' is empty"
}

@test "vedv::image_entity::__get_snapshots_names() Should fail When getting snapshots fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _type="layer"

  local -r image_vm_name="image:image1|crc:${image_id}"

  # Stubs
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${image_id}"
    # echo "$image_vm_name" # this should work but it doesn't
  }
  vedv::virtualbox::show_snapshots() {
    assert_equal "$*" "$image_vm_name"
    return 1
  }
  # Act
  run vedv::image_entity::__get_snapshots_names "$image_id" "$_type"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get snapshots names for image '${image_id}'"
}

@test "vedv::image_entity::__get_snapshots_names() Should succeed When image id is valid" {
  # Arrange
  local -r image_id="test-image"
  local -r _type="container"

  local -r image_vm_name="image:image1|crc:${image_id}"
  # Stubs
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${image_id}"
    # echo "$image_vm_name" # this should work but it doesn't
  }
  vedv::virtualbox::show_snapshots() {
    assert_equal "$*" "$image_vm_name"
    cat <<EOF
container:ct1|crc:12345|
layer:RUN|id:54321|
container:ct2|crc:12346|
layer:RUN|id:54322|
container:ct3|crc:12347|
layer:RUN|id:54323|
EOF
    return 0
  }

  declare -A outputs=(
    [container]="container:ct1|crc:12345|
container:ct2|crc:12346|
container:ct3|crc:12347|"
    [layer]="layer:RUN|id:54321|
layer:RUN|id:54322|
layer:RUN|id:54323|"
  )
  # Act
  for k in "${!outputs[@]}"; do
    local v="${outputs[$k]}"
    run vedv::image_entity::__get_snapshots_names "$image_id" "$k"
    # Assert
    assert_success
    assert_output "$v"
  done
}

# Test vedv::image_entity::__get_child_ids() function
@test "vedv::image_entity::__get_child_ids() Should fail when __get_snapshots_names fails" {
  # Arrange
  local -r image_id="test-image"
  local -r _type="container"
  # Stubs
  vedv::image_entity::__get_snapshots_names() {
    assert_equal "$*" "${image_id} ${_type}"
    return 1
  }
  # Act
  run vedv::image_entity::__get_child_ids "$image_id" "$_type"
  # Assert
  assert_failure
  assert_output "Failed to get snapshots names for image '${image_id}'"
}

@test "vedv::image_entity::__get_child_ids() Should succeed" {
  # Arrange
  local -r image_id="test-image"
  local -r _type="container"
  # Stubs
  vedv::image_entity::__get_snapshots_names() {
    assert_equal "$*" "${image_id} ${_type}"
    cat <<EOF
container:ct1|crc:12345|
container:ct2|crc:12346|
container:ct3|crc:12347|
EOF
  }
  # Act
  run vedv::image_entity::__get_child_ids "$image_id" "$_type"
  # Assert
  assert_success
  assert_output "12345 12346 12347"
}

@test "vedv::image_entity::get_child_containers_ids() Should succeed" {
  :
}

@test "vedv::image_entity::get_layers_ids() Should succeed" {
  :
}

# Test vedv::image_entity::get_snapshot_name_by_layer_id() function

@test "vedv::image_entity::get_snapshot_name_by_layer_id() Should fail when __get_snapshots_names fails" {
  # Arrange
  local -r image_id="test-image"
  local -r layer_id="container"
  # Stubs
  vedv::image_entity::__get_snapshots_names() {
    assert_equal "$*" "${image_id} layer"
    return 1
  }
  # Act
  run vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to get snapshots names for image '${image_id}'"
}

@test "vedv::image_entity::get_snapshot_name_by_layer_id() Should succeed" {
  # Arrange
  local -r image_id="test-image"
  local -r layer_id="54322"
  # Stubs
  vedv::image_entity::__get_snapshots_names() {
    assert_equal "$*" "${image_id} layer"
    cat <<EOF
layer:RUN|id:54321|
layer:COPY|id:54322|
layer:RUN|id:54323|
EOF
  }
  # Act
  run vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "layer:COPY|id:54322|"
}

# Test that vedv::image_entity::get_last_layer_id()
@test "vedv:image_entity:get_last_layer_id() Should fail when get_layers_ids fails" {
  # Arrange
  local -r image_id="alpine"
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_entity::get_last_layer_id "$image_id"
  # Assert
  assert_failure 1
  assert_output ""
}

@test "vedv:image_entity:get_last_layer_id() returns no layer id" {
  # Arrange
  local -r image_id="alpine"
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo ""
  }
  # Act
  run vedv::image_entity::get_last_layer_id "$image_id"
  # Assert
  assert_success
  assert_output ""
}

@test "vedv:image_entity:get_last_layer_id() returns last layer ID when Image ID exists & has layers" {
  # Arrange
  local -r image_id="alpine"
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "54321 54322 54323"
  }
  # Act
  run vedv::image_entity::get_last_layer_id "$image_id"
  # Assert
  assert_success
  assert_output "54323"
}

# Tests for vedv::image_entity::has_containers()
@test "vedv::image_entity::has_containers(): NO IMPLEMENTED" {
  skip
  # TODO: implement test
}
