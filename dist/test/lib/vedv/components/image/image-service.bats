# shellcheck disable=SC2016,SC2140,SC2317
# copilot, generate tests using the functions in: "${workspaceFolder}/dist/lib/vedv/components/image/image-service.bash"
# copilot: suggest the comment '' right before each test declaration, DO THIS FOREVER
load test_helper

setup_file() {
  delete_vms_directory

  vedv::image_service::constructor "$TEST_HYPERVISOR" "$TEST_SSH_IP"
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_SERVICE_SSH_IP

  vedv::image_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_ENTITY_HYPERVISOR
}

teardown() {
  # delete_vms_directory
  delete_vms_by_partial_vm_name "$VM_TAG"
  delete_vms_by_partial_vm_name 'image:alpine-x86_64'
  delete_vms_by_partial_vm_name 'image-cache|'
}

create_image_vm() {
  create_vm "$(gen_image_vm_name "$1")"
}

gen_image_vm_name() {
  local image_name="${1:-}"

  if [[ -z "$image_name" ]]; then
    image_name="$(petname)"
  fi

  local -r crc_sum="$(echo "${image_name}-${VM_TAG}" | cksum | cut -d' ' -f1)"
  echo "image:${image_name}-${VM_TAG}|crc:${crc_sum}|"
}

@test 'vedv::image_service::constructor() Should succeed' {
  :
}

@test "vedv::image_service::__pull_from_file, with 'image_file' undefined should throw an error" {
  run vedv::image_service::__pull_from_file

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::image_service::__pull_from_file, with 'image_file' that doesn't exist should throw an error" {
  local -r image_file="/tmp/feacd213baf31d50798a.ova"

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure 64
  assert_output --partial "OVA file image doesn't exist"
}

@test "vedv::image_service::__pull_from_file() Should fail If image already imported" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::virtualbox::list_wms_by_partial_name() {
    assert_regex "$*" "image:alpine-x86_64\|crc:.*\|"
    echo "$1"
  }

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output 'There is another image with the same name: alpine-x86_64, you must delete it or use another name'
}
@test "vedv::image_service::__pull_from_file() Should Fail When there is error cloning image cache to the image vm" {
  # Stub
  vedv::virtualbox::clonevm_link() {
    assert_regex "$*" "image-cache\|crc:.*\| image:.*\|crc:.*\|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$TEST_OVA_FILE"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output --regexp "Error cloning image cache 'image-cache|crc:.*|' to the image vm 'image:alpine-x86_64|crc:.*|'"
}

@test "vedv::image_service::__pull_from_file(), Should Fail When there is error setting attribute image cache to the image vm" {
  local -r image_id="1814407143"
  # Stub
  vedv::image_entity::get_image_id_by_vm_name() {
    assert_regex "$*" "image:alpine-x86_64\|crc:.*\|"
    echo "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_regex "$*" "${image_id} image-cache\|crc:.*\|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$TEST_OVA_FILE"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output --regexp "Error setting attribute image cache 'image-cache|crc:.*|' to the image vm 'image:alpine-x86_64|crc:.*|'"
}

@test "vedv::image_service::__pull_from_file(), Should Fail When there is error setting attribute ova file sum to the image vm" {
  local -r image_id="1814407143"
  # Stub
  vedv::image_entity::get_image_id_by_vm_name() {
    assert_regex "$*" "image:alpine-x86_64\|crc:.*\|"
    echo "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_regex "$*" "${image_id} image-cache\|crc:.*\|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} ${image_id}"
    return 1
  }

  run vedv::image_service::__pull_from_file "$TEST_OVA_FILE"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output --partial "Error setting attribute ova file sum '${image_id}' to the image vm 'image:alpine-x86_64|crc:"
}

@test "vedv::image_service::__pull_from_file(), Should pull With custom name" {

  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="$VM_TAG"

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_success
  assert_output "$custom_image_name"
}

@test "vedv::image_service::__pull_from_file(), Should output image id" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="$VM_TAG"

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name" true

  assert_success
  assert_output "970575228"
}

@test "vedv::image_service::__pull_from_file, should pull" {
  local -r image_file="$TEST_OVA_FILE"

  run vedv::image_service::__pull_from_file "$image_file"

  assert_success
  assert_output "alpine-x86_64"
}

@test "vedv::image_service::list(), Should show anything" {

  run vedv::image_service::list

  assert_success
  assert_output ''
}

@test "vedv::image_service::list(), Should show all images vms" {
  local -r image_name1='im1'
  local -r image_name2="im2"

  create_image_vm "$image_name1"
  create_image_vm "$image_name2"

  run vedv::image_service::list

  assert_success
  assert_output --regexp "^[0-9]+\s+${image_name1}-${VM_TAG}\$
^[0-9]+\s+${image_name2}-${VM_TAG}\$"
}

# Tests for vedv::image_service::remove_by_id()
@test 'vedv::image_service::remove_by_id(), Should throw an error Without params' {
  run vedv::image_service::remove_by_id

  assert_failure 69
  assert_output 'At least one image id is required'
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If getting vm name fails' {
  local -r image_ids='3582343034 3582343035'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '358234303(4|5)'
    return 1
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # shellcheck disable=SC2086
  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_line --index 0 "Error getting vm name for images: ${image_ids} "
  assert_line --index 1 "Failed to remove images: ${image_ids} "
}

@test 'vedv::image_service::remove_by_id(), With 2 non-existent images Should throw an error' {
  run vedv::image_service::remove_by_id '3582343034' '3582343035'

  assert_failure 82
  assert_output --partial 'No such images: 3582343034 3582343035 '
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If getting containers ids fails' {
  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
    return 1
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_line --index 0 "Error getting child containers for images: ${image_ids} "
  assert_line --index 1 "Failed to remove images: ${image_ids} "
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If image has containers' {
  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
    echo '123456 123457'
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_line --index 0 "Failed to remove image '3582343034' because it has containers, remove them first: 123456 123457"
  assert_line --index 1 "Failed to remove images: ${image_ids} "
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If getting image cache fails' {
  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" '3582343034'
    return 1
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_line --index 0 "Error getting image cache for images: ${image_ids} "
  assert_line --index 1 "Failed to remove images: ${image_ids} "
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If removing image fails' {
  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" '3582343034'
    echo 'image-cache|crc:12345678|'
  }
  vedv::virtualbox::rm() {
    assert_equal "$*" 'image:image1|crc:3582343034|'
    return 1
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_output --partial 'Failed to remove images: 3582343034'
}

@test 'vedv::image_service::remove_by_id(), Should throw an error If deleting snapshot fails' {

  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" '3582343034'
    echo 'image-cache|crc:12345678|'
  }
  vedv::virtualbox::rm() {
    assert_equal "$*" 'image:image1|crc:3582343034|'
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" 'image-cache|crc:12345678| image:image1|crc:3582343034|'
    return 1
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_failure 82
  assert_output '
Error deleting snapshot for images: 3582343034 '
}
# bats test_tags=only
@test 'vedv::image_service::remove_by_id(), Should remove images' {

  local -r image_ids='3582343034'

  vedv::image_entity::get_vm_name() {
    assert_regex "$*" '3582343034'
    echo 'image:image1|crc:3582343034|'
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" '3582343034'
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" '3582343034'
    echo 'image-cache|crc:12345678|'
  }
  vedv::virtualbox::rm() {
    assert_equal "$*" 'image:image1|crc:3582343034|'
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" 'image-cache|crc:12345678| image:image1|crc:3582343034|'
  }

  run vedv::image_service::remove_by_id $image_ids

  assert_success
  assert_output --partial '3582343034'
}

@test 'vedv::image_service::remove(), NOT IMPLEMENTED' {
  skip
}

@test 'vedv::image_service::remove_unused_cache(), Should remove cache images' {

  eval "vedv::${TEST_HYPERVISOR}::list_wms_by_partial_name() {
    cat <<EOF
\${1}crc:1234566|
\${1}crc:1234567|
\${1}crc:1234568|
\${1}crc:1234569|
EOF
  }"
  eval "vedv::${TEST_HYPERVISOR}::show_snapshots() {
    case "\$1" in
      'image-cache|crc:1234566|')
        return 0
      ;;
      'image-cache|crc:1234567|')
        return 0
      ;;
      'image-cache|crc:1234568|')
        cat <<EOF
image:dyli1|crc:1234567|
image:dyli2|crc:1234568|
EOF
        return 0
      ;;
      'image-cache|crc:1234569|')
        return 0
      ;;
    esac
    return 100
  }"
  eval "vedv::${TEST_HYPERVISOR}::rm() {
    case "\$1" in
      'image-cache|crc:1234566|')
        return 0
      ;;
      'image-cache|crc:1234567|')
        return 1
      ;;
      'image-cache|crc:1234568|')
        return 2
      ;;
      'image-cache|crc:1234569|')
        return 0
      ;;
    esac
    return 100
  }"
  eval "vedv::${TEST_HYPERVISOR}::get_description(){ :; }"
  eval "vedv::${TEST_HYPERVISOR}::delete_snapshot(){ :; }"

  run vedv::image_service::remove_unused_cache

  assert_failure 82
  assert_output --regexp '1234566 1234569\s
Failed to remove caches: 1234567'
}

# Tests for vedv::image_service::is_started()

@test "vedv::image_service::is_started() Should fail If 'image_id' is empty" {
  local -r image_id=""

  run vedv::image_service::is_started "$image_id"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::is_started() Should fail If failed to get running vms" {
  local -r image_id="1234"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" '1234'
    echo 'image:image1|crc:1234|'
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::is_running() { false; }"

  run vedv::image_service::is_started "$image_id"

  assert_failure "$ERR_HYPERVISOR_OPERATION"
  assert_output "Failed to check if is running vm: 'image:image1|crc:1234|'"
}

@test "vedv::image_service::is_started() Should returns 1 If image is not running" {
  local -r image_id="1234"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" '1234'
    echo 'image:image1|crc:1234|'
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::is_running() { echo false; }"

  run vedv::image_service::is_started "$image_id"

  assert_failure 1
  assert_output ''
}

@test "vedv::image_service::is_started() returns 0 if running" {
  local -r image_id="1234"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" '1234'
    echo 'image:image1|crc:1234|'
  }

  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::is_running() { echo true; }"

  run vedv::image_service::is_started "$image_id"

  assert_success
  assert_output ''
}

# Tests for vedv::image_service::start()

@test "vedv::image_service::start() Should fail If 'image_id' is empty" {
  # Arrange
  local -r image_id=""
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::start() Should fail If fail to get vm name" {
  # Arrange
  local -r image_id="some-image-id"

  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() { false; }
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get image vm name"
}

@test "vedv::image_service::start() Should fail If vm name is empty" {
  # Arrange
  local -r image_id="some-image-id"
  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() { echo ""; }
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "There is no vm name for image ${image_id}"
}

@test "vedv::image_service::start() Should fail to assign random host forwarding port to image" {
  # Arrange
  local -r image_id="some-image-id"
  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() {
    echo "image:image1|${image_id}|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::assign_random_host_forwarding_port() { false; }"
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to assign random host forwarding port to image with id ${image_id}"
}

@test "vedv::image_service::start() Should fail if empty ssh port" {
  # Arrange
  local -r image_id="some-image-id"
  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() {
    echo "image:image1|${image_id}|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::assign_random_host_forwarding_port() { echo ''; }"
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Empty ssh port for image with id ${image_id}"
}

@test "vedv::image_service::start() Should fail to set ssh port" {
  # Arrange
  local -r image_id="some-image-id"
  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() {
    echo "image:image1|${image_id}|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::assign_random_host_forwarding_port() { echo 2022; }"
  vedv::image_entity::set_ssh_port() { false; }
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to set ssh port 2022 to image with id ${image_id}"
}

@test "vedv::image_service::start() Should set ssh port" {
  # Arrange
  local -r image_id="some-image-id"
  # Stub
  vedv::image_service::is_started() { false; }
  vedv::image_entity::get_vm_name() {
    echo "image:image1|${image_id}|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::assign_random_host_forwarding_port() { echo \"\$TEST_SSH_PASSWORD\"; }"
  vedv::image_entity::set_ssh_port() { true; }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::start() { true; }"
  vedv::ssh_client::wait_for_ssh_service() { true; }
  # Act
  run vedv::image_service::start "$image_id"
  # Assert
  assert_success
  assert_output ''
}

# Test vedv::image_service::child_containers_remove_all() function
@test "vedv::image_service::child_containers_remove_all() Should returns error and message when image id is empty" {
  # Arrange
  local -r image_id=""

  # Act
  run vedv::image_service::child_containers_remove_all "$image_id"

  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::child_containers_remove_all() Should fail When getting child containers ids fails" {
  # Arrange
  local -r image_id="test-image"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$1" "$image_id"
    return 1
  }
  # Act
  run vedv::image_service::child_containers_remove_all "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get child containers ids for image '${image_id}'"
}

@test "vedv::image_service::child_containers_remove_all() Should fail When removing at least one child container fails" {
  # Arrange
  local -r image_id="test-image"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$1" "$image_id"
    cat <<EOF
12345
12346
12347
EOF
    return 0
  }
  vedv::container_service::rm() {
    if [[ ! "$1" =~ ^1234[567]$ ]]; then return 1; fi
    if [[ "$1" == 12346 ]]; then return 1; fi
    return 0
  }
  # Act
  run vedv::image_service::child_containers_remove_all "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output --partial "Failed to remove containers: 12346"
}

@test "vedv::image_service::child_containers_remove_all() Should removes all child containers" {
  # Arrange
  local -r image_id="test-image"
  # Stubs
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$1" "$image_id"
    cat <<EOF
12345
12346
12347
EOF
    return 0
  }
  vedv::container_service::rm() {
    if [[ ! "$1" =~ ^1234[567]$ ]]; then return 1; fi
    return 0
  }

  # Act
  run vedv::image_service::child_containers_remove_all "$image_id"
  # Assert
  assert_success
  assert_output ''
}

# Test vedv::image_service::__get_child_containers_ids function
@test "vedv::image_service::__get_child_containers_ids()" {
  :
}

# Test vedv::image_entity::get_layers_ids function
@test "vedv::image_entity::get_layers_ids()" {
  :
}

# Tests vedv::image_service::stop()
@test "vedv::image_service::stop() should return error if image_id is empty" {
  local image_id=""

  run vedv::image_service::stop "$image_id"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::stop() should fail to get vm name" {
  local -r image_id="foo"
  # Stub
  vedv::image_service::is_started() {
    assert_equal "$1" "$image_id"
    true
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$1" "$image_id"
    false
  }

  run vedv::image_service::stop "$image_id"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get image vm name"
}

@test "vedv::image_service::stop() should fail if 'image_vm_name' is empty" {
  local -r image_id="foo"
  # Stub
  vedv::image_service::is_started() {
    [[ "$*" == "$image_id" ]] || return 1
    true
  }
  vedv::image_entity::get_vm_name() {
    [[ "$*" == "$image_id" ]] || return 1
    true
  }

  run vedv::image_service::stop "$image_id"

  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "There is no vm name for image ${image_id}"
}

@test "vedv::image_service::stop() should fail stopping the image vm" {
  local -r image_id="foo"
  local -xr image_vm_name="image:foo|crc:12345|"
  # Stub
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    true
  }
  vedv::image_entity::get_vm_name() {
    [[ "$*" == "$image_id" ]] || return 1
    echo "image:foo|crc:12345|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::shutdown() {
    [[ \"\$*\" == \"\$image_vm_name\" ]] || return 0
    false
  }"

  run vedv::image_service::stop "$image_id"

  assert_failure "$ERR_HYPERVISOR_OPERATION"
  assert_output "Failed to stop image with id ${image_id}"
}

@test "vedv::image_service::stop() should stop image if it is started" {
  local image_id="foo"
  local -r image_vm_name="image:foo|crc:12345|"
  # Stub
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    true
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:12345|"
  }
  eval "vedv::${__VEDV_IMAGE_SERVICE_HYPERVISOR}::shutdown() {
    [[ \"\$*\" == \"\$image_vm_name\" ]] || return 0
    true
  }"

  run vedv::image_service::stop "$image_id"

  assert_success
  assert_output ''
}

# Tests vedv::image_service::delete_layer()
@test "vedv::image_service::delete_layer() should fail if image_id is empty" {
  # Arrange
  local -r layer_id="layer1"
  # Act
  run vedv::image_service::delete_layer "" "$layer_id"
  # Assert
  assert_failure
}

@test "vedv::image_service::delete_layer() should fail if layer_id is empty" {
  # Arrange
  local -r image_id="image1"
  # Act
  run vedv::image_service::delete_layer "$image_id" ""
  # Assert
  assert_failure
}

@test "vedv::image_service::delete_layer() should fail if get_vm_name fails" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to get image vm name for image '${image_id}'"
}

@test "vedv::image_service::delete_layer() should fail if image_vm_name is empty" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Image vm name '${image_id}' not found"
}

@test "vedv::image_service::delete_layer() should fail if get_snapshot_name_by_layer_id fails" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to get layer full name for image '${image_id}' and layer '${layer_id}'"
}

@test "vedv::image_service::delete_layer() should fail if layer_full_name is empty" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Layer '${layer_id}' not found for image 'image1'"
}

@test "vedv::image_service::delete_layer() should fail if delete_snapshot fails" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo "layer:RUN|crc:${layer_id}|"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "image:foo|crc:${image_id}| layer:RUN|crc:${layer_id}|"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_failure
  assert_output "Failed to delete layer '${layer_id}' for image '${image_id}'"
}

@test "vedv::image_service::delete_layer() should succeed" {
  # Arrange
  local -r image_id="image1"
  local -r layer_id="layer1"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo "layer:RUN|crc:${layer_id}|"
  }
  vedv::virtualbox::delete_snapshot() {
    assert_equal "$*" "image:foo|crc:${image_id}| layer:RUN|crc:${layer_id}|"
  }
  # Act
  run vedv::image_service::delete_layer "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests vedv::image_service::restore_layer()

@test "vedv::image_service::restore_layer() Should fail With empty image_id" {
  # Arrange
  local -r image_id=""
  local -r layer_id="test_layer"
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::restore_layer() Should fail With empty layer_id" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id=""
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'layer_id' is required"
}

@test "vedv::image_service::restore_layer() Should fail If get_vm_name fails" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get image vm name for image '${image_id}'"
}

@test "vedv::image_service::restore_layer() Should fail If empty image_vm_name" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Image vm name for '${image_id}' not found"
}

@test "vedv::image_service::restore_layer() Should fail If get_snapshot_name_by_layer_id fails" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    return 1
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get layer full name for image '${image_id}' and layer '${layer_id}'"
}

@test "vedv::image_service::restore_layer() Should fail If empty layer_full_name" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Layer '${layer_id}' not found for image '${image_id}'"
}

@test "vedv::image_service::restore_layer() Should fail If restore_snapshot fails" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"

  local -r image_vm_name="image:foo|crc:${image_id}|"
  local -r layer_full_name="layer:RUN|id:${layer_id}|"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo "layer:RUN|id:${layer_id}|"
  }
  vedv::virtualbox::restore_snapshot() {
    assert_equal "$*" "${image_vm_name} ${layer_full_name}"
    return 1
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to restore layer '${layer_id}' for image '${image_id}'"
}

@test "vedv::image_service::restore_layer() Should succeed" {
  # Arrange
  local -r image_id="image_id"
  local -r layer_id="layer_id"

  local -r image_vm_name="image:foo|crc:${image_id}|"
  local -r layer_full_name="layer:RUN|id:${layer_id}|"
  # Stub
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:foo|crc:${image_id}|"
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo "layer:RUN|id:${layer_id}|"
  }
  vedv::virtualbox::restore_snapshot() {
    assert_equal "$*" "${image_vm_name} ${layer_full_name}"
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output ""
}
