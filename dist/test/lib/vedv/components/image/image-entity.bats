# shellcheck disable=SC2317

load test_helper

# Tests for vedv::image_entity::gen_vm_name_from_ova_file()
@test "vedv::image_entity::gen_vm_name_from_ova_file(), with 'image_file' unset should throw an error" {
  run vedv::image_entity::gen_vm_name_from_ova_file

  assert_failure 1
  # shellcheck disable=SC2016
  assert_output --partial '$1: unbound variable'
}

@test "vedv::image_entity::gen_vm_name_from_ova_file(), should write the generated vm name" {
  local -r image_file="$TEST_OVA_FILE"
  petname() {
    echo 'alpine-x86_64'
  }
  run vedv::image_entity::gen_vm_name_from_ova_file "$image_file"

  assert_success
  assert_output --regexp '^image:alpine-x86_64\|crc:.*\|$'
}

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
  local -r _type="container"

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
