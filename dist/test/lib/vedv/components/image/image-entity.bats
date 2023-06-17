# shellcheck disable=SC2317

load test_helper

# Tests for vedv::image_entity::gen_vm_name()
@test "vedv::image_entity::gen_vm_name() Should succeed" {
  :
}

# Tests for vedv::image_entity::get_vm_name()
@test "vedv::image_entity::get_vm_name() Should succeed" {
  :
}

# Test for vedv::image_entity::get_vm_name_by_image_name()
@test "vedv::image_entity::get_vm_name_by_image_name() Should succeed" {
  :
}

# Test vedv::image_entity::get_image_name_by_vm_name()
@test "vedv::image_entity::get_image_name_by_vm_name() Should succeed" {
  :
}

# Test vedv::image_entity::get_id_by_vm_name()
@test "vedv::image_entity::get_id_by_vm_name() Should succeed" {
  :
}

# Test vedv::image_entity::get_id_by_image_name()
@test "vedv::image_entity::get_id_by_image_name() Should succeed" {
  :
}

# Test vedv::image_entity::get_ssh_port()
@test 'vedv::image_entity::get_ssh_port() Should succeed' {
  :
}

# Test vedv::image_entity::set_ssh_port()
@test 'vedv::image_entity::set_ssh_port() Should succeed' {
  :
}

# Test vedv::image_entity::get_ova_file_sum()
@test 'vedv::image_entity::get_ova_file_sum() Should succeed' {
  :
}

# Test vedv::image_entity::set_ova_file_sum()
@test 'vedv::image_entity::set_ova_file_sum() Should succeed' {
  :
}

# Test vedv::image_entity::get_image_cache()
@test 'vedv::image_entity::get_image_cache() Should succeed' {
  :
}

# Test vedv::image_entity::set_image_cache()
@test 'vedv::image_entity::set_image_cache() Should succeed' {
  :
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
  assert_output "Invalid type: ${_type}, valid values are: layer"
}

@test "vedv::image_entity::__get_snapshots_names() Should fail When getting vm name fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _type="layer"
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
  local -r _type="layer"
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
  vedv::hypervisor::show_snapshots() {
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
  local -r _type="layer"

  local -r image_vm_name="image:image1|crc:${image_id}"
  # Stubs
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${image_id}"
    # echo "$image_vm_name" # this should work but it doesn't
  }
  vedv::hypervisor::show_snapshots() {
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

# Test vedv::image_entity::__get_snapshots_ids() function
@test "vedv::image_entity::__get_snapshots_ids() Should fail when __get_snapshots_names fails" {
  # Arrange
  local -r image_id="test-image"
  local -r _type="container"
  # Stubs
  vedv::image_entity::__get_snapshots_names() {
    assert_equal "$*" "${image_id} ${_type}"
    return 1
  }
  # Act
  run vedv::image_entity::__get_snapshots_ids "$image_id" "$_type"
  # Assert
  assert_failure
  assert_output "Failed to get snapshots names for image '${image_id}'"
}

@test "vedv::image_entity::__get_snapshots_ids() Should succeed" {
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
  run vedv::image_entity::__get_snapshots_ids "$image_id" "$_type"
  # Assert
  assert_success
  assert_output "12345 12346 12347"
}

# Tests for vedv::image_entity::get_child_containers_ids()
@test "vedv::image_entity::get_child_containers_ids() Should succeed" {
  vedv::vmobj_entity::__get_attribute() {
    assert_equal "$*" "image image_id child_containers_ids"
    echo "12345 12346 12347"
  }

  run vedv::image_entity::get_child_containers_ids "image_id"

  assert_success
  assert_output "12345 12346 12347"
}
# Tests for vedv::image_entity::add_child_container_id()
@test "vedv::image_entity::add_child_container_id() Should fail With invalid image_id" {
  # Arrange
  local -r image_id="test-image"
  local -r container_id="test-container"
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'test-image'"
}

@test "vedv::image_entity::add_child_container_id() Should fail With invalid child_container_id" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="test-container"
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'test-container'"
}

@test "vedv::image_entity::add_child_container_id() Should fail If get_child_containers_ids fails" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Failed to get child containers ids for image '223456789'"
}

@test "vedv::image_entity::add_child_container_id() Should fail If container_id is already added" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    echo "123456789 123456788 123456787"
  }
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Failed to add child container '123456789' to image '223456789', it is already added"
}

@test "vedv::image_entity::add_child_container_id() Should succeed" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    echo "123456787 123456788"
  }
  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" "image 223456789 child_containers_ids 123456787 123456788 123456789"
  }
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_success
  assert_output ""
}

@test "vedv::image_entity::add_child_container_id() Should succeed without previous saved child containers" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" "image 223456789 child_containers_ids 123456789"
  }
  # Act
  run vedv::image_entity::add_child_container_id "$image_id" "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_entity::remove_child_container_id()
@test "vedv::image_entity::remove_child_container_id() Should fail With invalid image_id" {
  # Arrange
  local -r image_id="test-image"
  local -r container_id="test-container"
  # Act
  run vedv::image_entity::remove_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'test-image'"
}

@test "vedv::image_entity::remove_child_container_id() Should fail With invalid child_container_id" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="test-container"
  # Act
  run vedv::image_entity::remove_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'test-container'"
}

@test "vedv::image_entity::remove_child_container_id() Should fail If get_child_containers_ids fails" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_entity::remove_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Failed to get child containers ids for image '223456789'"
}

@test "vedv::image_entity::remove_child_container_id() Should fail If container_id is not added" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    echo "123456788 123456787"
  }
  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" "INVALID_CALL"
  }
  # Act
  run vedv::image_entity::remove_child_container_id "$image_id" "$container_id"
  # Assert
  assert_failure
  assert_output "Failed to remove child container '123456789' from image '223456789', it was not found"
}

@test "vedv::image_entity::remove_child_container_id() Should succeed" {
  # Arrange
  local -r image_id="223456789"
  local -r container_id="123456789"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "$image_id"
    echo "123456788 123456789 123456787"
  }
  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" "image 223456789 child_containers_ids 123456788 123456787"
  }
  # Act
  run vedv::image_entity::remove_child_container_id "$image_id" "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_entity::get_layers_ids()
@test "vedv::image_entity::get_layers_ids() Should succeed" {
  vedv::image_entity::__get_snapshots_ids() {
    assert_equal "$*" "image_id layer"
    echo "12345 12346 12347"
  }

  run vedv::image_entity::get_layers_ids "image_id" "layer"

  assert_success
  assert_output "12345 12346 12347"
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
@test "vedv::image_entity:get_last_layer_id() Should fail when get_layers_ids fails" {
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

@test "vedv::image_entity:get_last_layer_id() returns no layer id" {
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

# Test vedv::image_entity::cache::get_user_name()
# bats test_tags=only
@test 'vedv::image_entity::cache::get_user_name() Should succeed' {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_user_name() {
    :
  }
  # Act
  run vedv::image_entity::cache::get_user_name "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::set_user_name()
@test 'vedv::image_entity::cache::set_user_name() Should succeed' {
  # Setup
  local -r image_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_user_name() {
    assert_equal "$*" "image ct1 val1"
  }
  # Act
  run vedv::image_entity::cache::set_user_name "$image_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::get_workdir()
@test 'vedv::image_entity::cache::get_workdir() Should succeed' {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "image ct1"
  }
  # Act
  run vedv::image_entity::cache::get_workdir "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::set_workdir()
@test 'vedv::image_entity::cache::set_workdir() Should succeed' {
  # Setup
  local -r image_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_workdir() {
    assert_equal "$*" "image ct1 val1"
  }
  # Act
  run vedv::image_entity::cache::set_workdir "$image_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::get_environment()
@test 'vedv::image_entity::cache::get_environment() Should succeed' {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "image ct1"
  }
  # Act
  run vedv::image_entity::cache::get_environment "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::set_environment()
@test 'vedv::image_entity::cache::set_environment() Should succeed' {
  # Setup
  local -r image_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_environment() {
    assert_equal "$*" "image ct1 val1"
  }
  # Act
  run vedv::image_entity::cache::set_environment "$image_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::get_exposed_ports()
@test 'vedv::image_entity::cache::get_exposed_ports() Should succeed' {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "image ct1"
  }
  # Act
  run vedv::image_entity::cache::get_exposed_ports "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::set_exposed_ports()
@test 'vedv::image_entity::cache::set_exposed_ports() Should succeed' {
  # Setup
  local -r image_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_exposed_ports() {
    assert_equal "$*" "image ct1 val1"
  }
  # Act
  run vedv::image_entity::cache::set_exposed_ports "$image_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::get_shell()
@test 'vedv::image_entity::cache::get_shell() Should succeed' {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "image ct1"
  }
  # Act
  run vedv::image_entity::cache::get_shell "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::image_entity::set_shell()
@test 'vedv::image_entity::cache::set_shell() Should succeed' {
  # Setup
  local -r image_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_shell() {
    assert_equal "$*" "image ct1 val1"
  }
  # Act
  run vedv::image_entity::cache::set_shell "$image_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_entity::validate_id()
@test "vedv::image_entity::validate_id() Should succeed" {
  # Setup
  local -r image_id="ct1"
  # Mock
  vedv::vmobj_entity::validate_id() {
    assert_equal "$*" "ct1"
  }
  # Act
  run vedv::image_entity::validate_id "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_entity::validate_name()
@test "vedv::image_entity::validate_name() Should succeed" {
  # Setup
  local -r image_name="ct1"
  # Mock
  vedv::vmobj_entity::validate_name() {
    assert_equal "$*" "ct1"
  }
  # Act
  run vedv::image_entity::validate_name "$image_name"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::vmobj_entity::validate_layer_name()
@test "vedv::image_entity::validate_layer_name() Should fail if layer name is empty" {
  # Setup
  local -r layer_name=""
  # Act
  run vedv::image_entity::validate_layer_name "$layer_name"
  # Assert
  assert_failure
  assert_output "Invalid layer name ''"
}

@test "vedv::image_entity::validate_layer_name() Should fail if layer name is invalid" {
  # Setup
  local -r layer_name='abc'
  # Act
  run vedv::image_entity::validate_layer_name "$layer_name"
  # Assert
  assert_failure
  assert_output "Invalid layer name 'abc'"
}

@test "vedv::image_entity::validate_layer_name() Should succeed if layer name is valid" {
  # Setup
  local -r layer_name='FROM'
  # Act
  run vedv::image_entity::validate_layer_name "$layer_name"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_entity::get_layer_at()
@test "vedv::image_entity::get_layer_at() Should fail With invalid image_id" {
  # Setup
  local -r image_id="invalid"
  local -ri index=0
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_entity::get_layer_at() Should fail With invalid index" {
  # Setup
  local -r image_id="234567890"
  local -ri index=-1
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_failure
  assert_output "Index must be greater or equal to 0"
}

@test "vedv::image_entity::get_layer_at() Should fail If get_layers_ids fails" {
  # Setup
  local -r image_id="234567890"
  local -ri index=0
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "234567890"
    return 1
  }
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_failure
  assert_output "Failed to get layers ids for image '234567890'"
}

@test "vedv::image_entity::get_layer_at() Should fail If there is no layers ids" {
  # Setup
  local -r image_id="234567890"
  local -ri index=0
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "234567890"
  }
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_failure
  assert_output "Failed to get layer id for image '234567890', it has no layers"
}

@test "vedv::image_entity::get_layer_at() Should fail If index is out of range" {
  # Setup
  local -r image_id="234567890"
  local -ri index=3
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "234567890"
    echo "1234567890 234567890 345678901"
  }
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_failure
  assert_output "Failed to get layer id for image '234567890', index '3' is out of range"
}

@test "vedv::image_entity::get_layer_at() Should succeed" {
  # Setup
  local -r image_id="234567890"
  local -ri index=1
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "234567890"
    echo "1234567890 234567890 345678901"
  }
  # Act
  run vedv::image_entity::get_layer_at "$image_id" "$index"
  # Assert
  assert_success
  assert_output "234567890"
}

# Tests for vedv::image_entity::get_first_layer_id()
@test "vedv::image_entity::get_first_layer_id() Should succeed" {
  # Setup
  local -r image_id="1234567890"
  # Mock
  vedv::image_entity::get_layer_at() {
    assert_equal "$*" "1234567890 0"
    echo "1234567890"
  }
  # Act
  run vedv::image_entity::get_first_layer_id "$image_id"
  # Assert
  assert_success
  assert_output "1234567890"
}

# Tests for vedv::image_entity::get_layer_index()
@test "vedv::image_entity::get_layer_index() Should fail With invalid image_id" {
  # Setup
  local -r image_id="invalid"
  local -r layer_id="234567890"
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_entity::get_layer_index() Should fail With invalid layer_id" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="invalid"
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_entity::get_layer_index() Should fail If get_layers_ids fails" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "1234567890"
    return 1
  }
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to get layers ids for image '1234567890'"
}

@test "vedv::image_entity::get_layer_index() Should return -1 If there is no layers ids" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "1234567890"
  }
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "-1"
}

@test "vedv::image_entity::get_layer_index() Should return -1 If layer_id is not in layers ids" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "1234567890"
    echo "334567890 434567890"
  }
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "-1"
}

@test "vedv::image_entity::get_layer_index() Should succeed" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="334567890"
  # Mock
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "1234567890"
    echo "234567890 334567890 434567890"
  }
  # Act
  run vedv::image_entity::get_layer_index "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "1"
}

# Tests for vedv::image_entity::has_layer_id()
@test "vedv::image_entity::has_layer_id() Should fail With invalid image_id" {
  # Setup
  local -r image_id="invalid"
  local -r layer_id="234567890"
  # Act
  run vedv::image_entity::has_layer_id "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_entity::has_layer_id() Should fail With invalid layer_id" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="invalid"
  # Act
  run vedv::image_entity::has_layer_id "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_entity::has_layer_id() Should fail If get_layer_index fails" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layer_index() {
    assert_equal "$*" "1234567890 234567890"
    return 1
  }
  # Act
  run vedv::image_entity::has_layer_id "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to get layer index for image '1234567890'"
}

@test "vedv::image_entity::has_layer_id() Should return false If layer_id is not in layers ids" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layer_index() {
    assert_equal "$*" "1234567890 234567890"
    echo "-1"
  }
  # Act
  run vedv::image_entity::has_layer_id "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "false"
}

@test "vedv::image_entity::has_layer_id() Should return true If layer_id is in layers ids" {
  # Setup
  local -r image_id="1234567890"
  local -r layer_id="234567890"
  # Mock
  vedv::image_entity::get_layer_index() {
    assert_equal "$*" "1234567890 234567890"
    echo "1"
  }
  # Act
  run vedv::image_entity::has_layer_id "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output "true"
}
