# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  vedv::vmobj_entity::constructor \
    'container|image' \
    '([image]="image_cache|ova_file_sum|ssh_port" [container]="parent_image_id|ssh_port")'

  export __VEDV_VMOBJ_ENTITY_TYPE
  export __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR

  vedv::vmobj_service::constructor \
    "$TEST_SSH_IP" \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD"
  export __VEDV_VMOBJ_SERVICE_SSH_IP
  export __VEDV_VMOBJ_SERVICE_SSH_USER
  export __VEDV_VMOBJ_SERVICE_SSH_PASSWORD
}

# Tests for vedv::container_service::create()
@test "vedv::container_service::create() Should fail With empty image" {
  local -r image=''
  local -r container_name=''

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Invalid argument 'image': it's empty"
}

@test "vedv::container_service::create() Should fail If exits_with_name fails" {
  local -r image='image1'
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to check if container with name: 'container1' already exist"
}

@test "vedv::container_service::create() Should fail If container exists" {
  local -r image='image1'
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo true
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Container with name: 'container1' already exist"
}

@test "vedv::container_service::create() Should fail If petname fails" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() { return 1; }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to generate a random name"
}

@test "vedv::container_service::create() Should fail If image_service::pull fails" {
  local -r image="$TEST_OVA_FILE"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() { echo "image_name"; }

  vedv::image_service::pull() {
    assert_equal "$*" "${TEST_OVA_FILE} image_name"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output --partial "Failed to pull image:"
}

@test "vedv::container_service::create() Should fail If get_vm_name_by_image_name fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get image vm name for image: 'image1'"
}

@test "vedv::container_service::create() Should fail If image_vm_name is empty" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Image: 'image1' does not exist"
}

@test "vedv::container_service::create() Should fail If gen_vm_name fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" "container1"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to generate container vm name for container: 'container1'"
}

@test "vedv::container_service::create() Should fail If get_id_by_vm_name fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" "container1"
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get image id for image: 'image1'"
}

@test "vedv::container_service::create() Should fail If get_last_layer_id fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" "container1"
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get last image layer id for image: 'image1'"
}

@test "vedv::container_service::create() Should fail If get_snapshot_name_by_layer_id fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" "container1"
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get image layer snapshot name for image: 'image1'"
}

@test "vedv::container_service::create() Should fail If clonevm_link fails" {
  local -r image="image1"
  local -r container_name='container1'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" "container1"
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to link clone vm: 'image:foo-bar|crc:12345|' to: 'container:bin-baam|crc:12346|'"
}

@test "vedv::container_service::create() Should fail If get_container_name_by_vm_name fails" {
  local -r image="image1"
  local -r container_name=''

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
  }
  vedv::container_entity::get_container_name_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get container name for vm: 'container:bin-baam|crc:12346|'"
}

@test "vedv::container_service::create() Should fail If get_container_id_by_vm_name fails" {
  local -r image="image1"
  local -r container_name=''

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
  }
  vedv::container_entity::get_container_name_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo "bin-baam"
  }
  vedv::container_entity::get_id_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to get container id for vm: 'container:bin-baam|crc:12346|'"
}

@test "vedv::container_service::create() Should fail If set_parent_image_id fails" {
  local -r image="image1"
  local -r container_name=''

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
  }
  vedv::container_entity::get_container_name_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo "bin-baam"
  }
  vedv::container_entity::get_id_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo 12346
  }
  vedv::container_entity::set_parent_image_id() {
    assert_equal "$*" "12346 12345"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_failure
  assert_output "Failed to set parent image id for container: 'bin-baam'"
}

@test "vedv::container_service::create() Should succeed" {
  local -r image="image1"
  local -r container_name=''

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
  }
  vedv::container_entity::get_container_name_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo "bin-baam"
  }
  vedv::container_entity::get_id_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo 12346
  }
  vedv::container_entity::set_parent_image_id() {
    assert_equal "$*" "12346 12345"
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_success
  assert_output "bin-baam"
}
# bats test_tags=only
@test "vedv::container_service::create() Should fail if publish_ports fails" {
  local -r image="image1"
  local -r container_name=''
  # shellcheck disable=SC2034
  local -r standalone=false
  local -r publish_ports='-p 8080:80/tcp -p 8082:82 -p 8081 -p 81/udp'

  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "container container1"
    echo false
  }
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_vm_name_by_image_name() {
    assert_equal "$*" "image1"
    echo "image:foo-bar|crc:12345|"
  }
  vedv::container_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:foo-bar|crc:12345|"
    echo 12345
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "12345"
    echo 53455
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "12345 53455"
    echo "layer:RUN|id:layer_id|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:foo-bar|crc:12345| container:bin-baam|crc:12346| layer:RUN|id:layer_id|"
  }
  vedv::container_entity::get_container_name_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo "bin-baam"
  }
  vedv::container_entity::get_id_by_vm_name() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    echo 12346
  }
  vedv::container_entity::set_parent_image_id() {
    assert_equal "$*" "12346 12345"
  }
  vedv::container_service::publish_ports() {
    assert_regex "$*" "\d+ 8080:80/tcp -p 8082:82 -p 8081 -p 81/udp"
    return 1
  }

  run vedv::container_service::create "$image" "$container_name"

  assert_success
  assert_output "bin-baam"
}

# Tests for vedv::container_service::is_started()
@test "vedv::container_service::is_started() Should succeed" {
  local -r container_id=123456

  vedv::vmobj_service::is_started() {
    assert_equal "$*" 'container 123456'
    echo true
  }

  run vedv::container_service::is_started "$container_id"

  assert_success
  assert_output 'true'
}

# Tests for vedv::container_service::start()
@test "vedv::container_service::start() Should succeed" {
  local -r container_id=123456

  vedv::vmobj_service::start() {
    assert_equal "$*" 'container true 123456'
  }

  run vedv::container_service::start "$container_id"

  assert_success
  assert_output ''
}

# Tests for vedv::container_service::stop()
@test "vedv::container_service::stop() Should succeed" {
  local -r container_id=123456

  vedv::vmobj_service::stop() {
    assert_equal "$*" 'container true 123456'
  }

  run vedv::container_service::stop "$container_id"

  assert_success
  assert_output ''
}

# Tests for vedv::container_service::remove_one()
@test "vedv::container_service::remove_one() Should fail With empty container_id" {
  local -r container_id=''

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Invalid argument 'container_id': it's empty"
}

@test "vedv::container_service::remove_one() Should fail If container_entity::get_vm_name fails" {
  local -r container_id=123456

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to get vm name for container: '123456'"
}

@test "vedv::container_service::remove_one() Should fail If container_entity::get_parent_image_id fails" {
  local -r container_id=123456

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to get parent image id for container '123456'"
}

@test "vedv::container_service::remove_one() Should fail If empty parent_image_id" {
  local -r container_id=123456

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "No 'parent_image_id' for container: '123456'"
}

@test "vedv::container_service::remove_one() Should fail If __get_running_siblings_ids fails" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to get running siblings ids for container: '123456'"
}

@test "vedv::container_service::remove_one() Should fail If there are running siblings and force is false" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
    echo '123457 123458'
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Can't remove container: '123456' because it has running sibling containers
You can Use the 'force' flag to stop them automatically and remove the container
Or you can stop them manually and then remove the container
Sibling containers ids: '123457 123458'"
}

@test "vedv::container_service::remove_one() Should fail If there are running siblings and stop them fails" {
  local -r container_id=123456
  local -r force=true

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
    echo '123457 123458'
  }
  vedv::container_service::stop() {
    assert_equal "$*" '123457 123458'
    return 1
  }

  run vedv::container_service::remove_one "$container_id" "$force"

  assert_failure
  assert_output "Failed to stop some sibling container"
}

@test "vedv::container_service::remove_one() Should fail If vedv::hypervisor::rm fails" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to remove container: '123456'"
}

@test "vedv::container_service::remove_one() Should fail If image_entity::get_vm_name fails" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" 22345
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to get vm name for parent image id: '22345'"
}

@test "vedv::container_service::remove_one() Should fail If delete_snapshot fails" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" 22345
    echo "image:foo-bar|crc:22345|"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image:foo-bar|crc:22345| container:bin-baam|crc:12346|"
    return 1
  }

  run vedv::container_service::remove_one "$container_id"

  assert_failure
  assert_output "Failed to delete snapshot of container '123456' on parent image '22345'"
}

@test "vedv::container_service::remove_one() Should succeed" {
  local -r container_id=123456

  vedv::container_service::is_started() {
    assert_equal "$*" 123456
    echo false
  }
  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 123456
    echo "container:bin-baam|crc:12346|"
  }
  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::container_service::__get_running_siblings_ids() {
    assert_equal "$*" 123456
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "container:bin-baam|crc:12346|"
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" 22345
    echo "image:foo-bar|crc:22345|"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image:foo-bar|crc:22345| container:bin-baam|crc:12346|"
  }

  run vedv::container_service::remove_one "$container_id"

  assert_success
  assert_output "123456"
}

# Tests for vedv::container_service::remove()
@test "vedv::container_service::remove() Should succeed" {
  :
}

# Tests for vedv::container_service::list()
@test "vedv::container_service::list() Should succeed" {
  :
}

# Tests for vedv::container_service::__get_running_siblings_ids()

@test "vedv::container_service::__get_running_siblings_ids() Should fail If container_id is empty" {
  local -r container_id=''

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "Invalid argument 'container_id': it's empty"
}

@test "vedv::container_service::__get_running_siblings_ids() Should fail If get_parent_image_id fails" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    return 1
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "Failed to get parent image id for container '123456'"
}

@test "vedv::container_service::__get_running_siblings_ids() Should fail If parent_image_id is empty" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "No 'parent_image_id' for container: '123456'"
}

@test "vedv::container_service::__get_running_siblings_ids() Should fail If get_child_containers_ids fails" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" 22345
    return 1
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "Failed to get child containers ids for image: '22345'"
}

@test "vedv::container_service::__get_running_siblings_ids() Should fail If image_childs_ids is empty" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" 22345
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "No child containers ids for image: '22345'"
}

@test "vedv::container_service::__get_running_siblings_ids() Should fail If is_started fails" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" 22345
    echo '123456 123457 123458'
  }
  vedv::container_service::is_started() {
    assert_equal "$*" 123457
    return 1
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_failure
  assert_output "Failed to check if container is started: '123457'"
}

@test "vedv::container_service::__get_running_siblings_ids() Should succeed" {
  local -r container_id=123456

  vedv::container_entity::get_parent_image_id() {
    assert_equal "$*" 123456
    echo 22345
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" 22345
    echo '123456 123457 123458'
  }
  vedv::container_service::is_started() {
    assert_regex "$*" '^12345(7|8)$'
    echo true
  }

  run vedv::container_service::__get_running_siblings_ids "$container_id"

  assert_success
  assert_output "123457 123458"
}

# Tests for vedv::container_service::execute_cmd()
@test "vedv::container_service::execute_cmd()" {
  :
}

# Tests for vedv::container_service::connect()
@test "vedv::container_service::connect()" {
  :
}

# Tests for vedv::container_service::copy()

@test "vedv::container_service::copy() Should succeed" {
  local -r container_id_or_name="container1"
  local -r src="src1"
  local -r dest="dest1"
  local -r user="vedv"
  local -r chown="nalyd"
  local -r chmod="644"

  vedv::vmobj_service::copy() {
    assert_equal "$*" "container container1 src1 dest1 vedv  nalyd 644"
  }

  run vedv::container_service::copy "$container_id_or_name" "$src" "$dest" "$user" "$chown" "$chmod"

  assert_success
  assert_output ""
}

# Tets for vedv::container_service::publish_ports()
# bats test_tags=only
@test "vedv::container_service::publish_ports() Should fail If container_id is empty" {
  local -r container_id=''

  run vedv::container_service::publish_ports "$container_id"

  assert_failure
  assert_output "Invalid argument 'container_id': it's empty"
}
# bats test_tags=only
@test "vedv::container_service::publish_ports() Should succeed if no ports to publish" {
  local -r container_id=123456

  run vedv::container_service::publish_ports "$container_id"

  assert_success
  assert_output ""
}
# bats test_tags=only
@test "vedv::container_service::publish_ports() Should fail if publish_port fails" {
  local -r container_id=123456
  local -r publish_ports='8080:80/tcp 8082:82 8081 81/udp'

  vedv::container_service::publish_port() {
    assert_equal "$*" "123456 8080:80/tcp"
    return 1
  }

  run vedv::container_service::publish_ports "$container_id" "$publish_ports"

  assert_failure
  assert_output "Failed to publish port: '8080:80/tcp' for container: '123456'"
}
# bats test_tags=only
@test "vedv::container_service::publish_ports() Should succeed" {
  local -r container_id=123456
  local -r publish_ports='8080:80/tcp 8082:82 8081 81/udp'

  vedv::container_service::publish_port() {
    assert_regex "$*" "123456 (8080:80/tcp|8082:82|8081|81/udp)"
  }

  run vedv::container_service::publish_ports "$container_id" "$publish_ports"

  assert_success
  assert_output ""
}

# Tests for vedv::container_service::publish_port()
# bats test_tags=only
@test "vedv::container_service::publish_port() Should fail If container_id is empty" {
  local -r container_id=''
  local -r publish_port='8080:80/tcp'

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_failure
  assert_output "Invalid argument 'container_id': it's empty"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should fail If port is empty" {
  local -r container_id=12345
  local -r publish_port=''

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_failure
  assert_output "Invalid argument 'port': it's empty"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should fail If get_vm_name fails" {
  local -r container_id=12345
  local -r publish_port='8080:80/tcp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    return 1
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_failure
  assert_output "Failed to get vm name for container: '12345'"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should fail If container_vm_name is empty" {
  local -r container_id=12345
  local -r publish_port='8080:80/tcp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_failure
  assert_output "There is no container with id '12345'"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should fail If add_forwarding_port fails" {
  local -r container_id=12345
  local -r publish_port='8080:80/tcp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    assert_equal "$1" "container:bin-baam|crc:12346|"
    assert_equal "$2" "3074115300"
    assert_equal "$3" "8080"
    assert_equal "$4" "80"
    assert_equal "$5" "tcp"
    return 1
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_failure "$ERR_CONTAINER_OPERATION"
  assert_output "Failed to publish port: '8080:80/tcp' for container: '12345'"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should succeed With port '8080:80/tcp'" {
  local -r container_id=12345
  local -r publish_port='8080:80/tcp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    echo "container_vm_name: $1, port_id: $2, host_port: $3, container_port: $4, protocol: $5"
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_success
  assert_output "container_vm_name: container:bin-baam|crc:12346|, port_id: 3074115300, host_port: 8080, container_port: 80, protocol: tcp"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should succeed With port '8080:80/udp'" {
  local -r container_id=12345
  local -r publish_port='8080:80/udp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    echo "container_vm_name: $1, port_id: $2, host_port: $3, container_port: $4, protocol: $5"
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_success
  assert_output "container_vm_name: container:bin-baam|crc:12346|, port_id: 3803504386, host_port: 8080, container_port: 80, protocol: udp"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should succeed With port '8082:82'" {
  local -r container_id=12345
  local -r publish_port='8082:82'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    echo "container_vm_name: $1, port_id: $2, host_port: $3, container_port: $4, protocol: $5"
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_success
  assert_output "container_vm_name: container:bin-baam|crc:12346|, port_id: 2150172608, host_port: 8082, container_port: 82, protocol: tcp"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should succeed With port '8081'" {
  local -r container_id=12345
  local -r publish_port='8081'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    echo "container_vm_name: $1, port_id: $2, host_port: $3, container_port: $4, protocol: $5"
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_success
  assert_output "container_vm_name: container:bin-baam|crc:12346|, port_id: 2250533131, host_port: 8081, container_port: 8081, protocol: tcp"
}
# bats test_tags=only
@test "vedv::container_service::publish_port() Should succeed With port '81/udp'" {
  local -r container_id=12345
  local -r publish_port='81/udp'

  vedv::container_entity::get_vm_name() {
    assert_equal "$*" 12345
    echo "container:bin-baam|crc:12346|"
  }
  vedv::hypervisor::add_forwarding_port() {
    echo "container_vm_name: $1, port_id: $2, host_port: $3, container_port: $4, protocol: $5"
  }

  run vedv::container_service::publish_port "$container_id" "$publish_port"

  assert_success
  assert_output "container_vm_name: container:bin-baam|crc:12346|, port_id: 2227371250, host_port: 81, container_port: 81, protocol: udp"
}
