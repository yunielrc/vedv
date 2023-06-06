# shellcheck disable=SC2317

load test_helper

setup() {
  export VEDV_CONTAINER_ENTITY_TYPE
  export VEDV_CONTAINER_ENTITY_VALID_ATTRIBUTES
}

# Tests for vedv::container_entity::gen_vm_name()
# bats test_tags=only
@test "vedv::container_entity::gen_vm_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::gen_vm_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::gen_vm_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::container_entity::get_vm_name()
# bats test_tags=only
@test "vedv::container_entity::get_vm_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_vm_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_vm_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test for vedv::container_entity::get_vm_name_by_container_name()
@test "vedv::container_entity::get_vm_name_by_container_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_vm_name_by_vmobj_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_vm_name_by_container_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_container_name_by_vm_name()
# bats test_tags=only
@test "vedv::container_entity::get_container_name_by_vm_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_container_name_by_vm_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_id_by_vm_name()
# bats test_tags=only
@test "vedv::container_entity::get_id_by_vm_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_vmobj_id_by_vm_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_id_by_vm_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_id_by_container_name()
@test "vedv::container_entity::get_id_by_container_name() Should succeed" {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_id_by_vmobj_name() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_id_by_container_name "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_ssh_port()
@test 'vedv::container_entity::get_ssh_port() Should succeed' {
  # Setup
  local -r container_name="ct1"
  # Mock
  vedv::vmobj_entity::get_ssh_port() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::get_ssh_port "$container_name"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_ssh_port()
@test 'vedv::container_entity::set_ssh_port() Should succeed' {
  # Setup
  local -r container_name="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::set_ssh_port() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::set_ssh_port "$container_name" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_parent_image_id()
# bats test_tags=only
@test 'vedv::container_entity::set_parent_image_id() Should succeed' {
  # Setup
  local -r container_name="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::__set_attribute() {
    assert_equal "$*" "container ct1 parent_image_id val1"
  }
  # Act
  run vedv::container_entity::set_parent_image_id "$container_name" "$value"
  # Assert
  assert_success
  assert_output ""
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

# Test vedv::container_entity::get_environment()
@test 'vedv::container_entity::cache::get_environment() Should succeed' {
  # Setup
  local -r container_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_environment() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::cache::get_environment "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_environment()
@test 'vedv::container_entity::cache::set_environment() Should succeed' {
  # Setup
  local -r container_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_environment() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::cache::set_environment "$container_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_exposed_ports()
@test 'vedv::container_entity::cache::get_exposed_ports() Should succeed' {
  # Setup
  local -r container_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_exposed_ports() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::cache::get_exposed_ports "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_exposed_ports()
@test 'vedv::container_entity::cache::set_exposed_ports() Should succeed' {
  # Setup
  local -r container_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_exposed_ports() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::cache::set_exposed_ports "$container_id" "$value"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::get_shell()
@test 'vedv::container_entity::cache::get_shell() Should succeed' {
  # Setup
  local -r container_id="ct1"
  # Mock
  vedv::vmobj_entity::cache::get_shell() {
    assert_equal "$*" "container ct1"
  }
  # Act
  run vedv::container_entity::cache::get_shell "$container_id"
  # Assert
  assert_success
  assert_output ""
}

# Test vedv::container_entity::set_shell()
@test 'vedv::container_entity::cache::set_shell() Should succeed' {
  # Setup
  local -r container_id="ct1"
  local -r value="val1"
  # Mock
  vedv::vmobj_entity::cache::set_shell() {
    assert_equal "$*" "container ct1 val1"
  }
  # Act
  run vedv::container_entity::cache::set_shell "$container_id" "$value"
  # Assert
  assert_success
  assert_output ""
}
