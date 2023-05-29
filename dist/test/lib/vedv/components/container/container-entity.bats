# shellcheck disable=SC2317

load test_helper

setup() {
  export VEDV_CONTAINER_ENTITY_TYPE
  export VEDV_CONTAINER_ENTITY_VALID_ATTRIBUTES
}

# Tests for vedv::container_entity::gen_vm_name()
@test "vedv::container_entity::gen_vm_name() DUMMY" {
  :
}

# Tests for vedv::container_entity::get_vm_name()
@test "vedv::container_entity::get_vm_name() DUMMY" {
  :
}

# Test for vedv::container_entity::get_vm_name_by_container_name()
@test "vedv::container_entity::get_vm_name_by_container_name() DUMMY" {
  :
}

# Test vedv::container_entity::get_container_name_by_vm_name()
@test "vedv::container_entity::get_container_name_by_vm_name() DUMMY" {
  :
}

# Test vedv::container_entity::get_id_by_vm_name()
@test "vedv::container_entity::get_id_by_vm_name() DUMMY" {
  :
}

# Test vedv::container_entity::get_id_by_container_name()
@test "vedv::container_entity::get_id_by_container_name() DUMMY" {
  :
}

# Test vedv::container_entity::get_ssh_port()
@test 'vedv::container_entity::get_ssh_port() DUMMY' {
  :
}

# Test vedv::container_entity::set_ssh_port()
@test 'vedv::container_entity::set_ssh_port() DUMMY' {
  :
}

# Test vedv::container_entity::set_parent_image_id()
@test 'vedv::container_entity::set_parent_image_id() DUMMY' {
  :
}

# Test vedv::container_entity::cache::get_user_name()
# bats test_tags=only
@test 'vedv::container_entity::cache::get_user_name() Should succeed' {
  # Setup
  local -r container_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_user_name() {
    :
  }
  # Act
  run vedv::container_entity::cache::get_user_name "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_user_name()
@test 'vedv::container_entity::cache::set_user_name() Should succeed' {
  # Setup
  local -r container_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_user_name() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::cache::set_user_name "$container_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_workdir()
@test 'vedv::container_entity::cache::get_workdir() Should succeed' {
  # Setup
  local -r container_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_workdir() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::cache::get_workdir "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_workdir()
@test 'vedv::container_entity::cache::set_workdir() Should succeed' {
  # Setup
  local -r container_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_workdir() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::cache::set_workdir "$container_id" "$value"
  # Assert
  assert_success
  assert_output ""
}
