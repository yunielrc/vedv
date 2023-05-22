# shellcheck disable=SC2016,SC2140,SC2317
# copilot, generate tests using the functions in: "${workspaceFolder}/dist/lib/vedv/components/image/image-service.bash"
# copilot: suggest the comment '' right before each test declaration, DO THIS FOREVER
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

# Tests for vedv::image_service::__pull_from_file()
@test "vedv::image_service::__pull_from_file() Should throw an error If 'image_file' doesn't exist" {
  local -r image_file="/tmp/feacd213baf31d50798a.ova"

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure
  assert_output "OVA file image doesn't exist"
}

@test "vedv::image_service::__pull_from_file() Should fail If gen_vm_name_from_ova_file fails" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure
  assert_output "Error generating vm_name from ova_file '${TEST_OVA_FILE}'"
}

@test "vedv::image_service::__pull_from_file() Should fail If get_id_by_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure
  assert_output "Error getting image_id by vm_name 'image:image1|crc:1234567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If get_image_name_by_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo '1234567890'
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file"

  assert_failure
  assert_output "Error getting image_name by vm_name 'image:image1|crc:1234567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If gen_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo '1234567890'
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error generating vm_name from image_name: 'custom_image1'"
}

@test "vedv::image_service::__pull_from_file() Should fail If get_id_by_vm_name with custom_image_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      return 1
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error getting image_id by vm_name 'image:custom_image1|crc:1334567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If list_vms_by_partial_name with vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error getting virtual machine with name: 'image:custom_image1|crc:1334567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If there is another vm with the same name" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
    echo "image:image2|crc:1434567890|"
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "There is another image with the same name: custom_image1, you must delete it or use another name"
}

@test "vedv::image_service::__pull_from_file() Should fail If list_vms_by_partial_name for image_cache fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    # shellcheck disable=SC2154
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 1
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error getting virtual machine with name: 'image-cache|crc:12345678900|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If hypervisor::import fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error creating image cache 'image-cache|crc:12345678900|' vm from ova file '${TEST_OVA_FILE}'"
}

@test "vedv::image_service::__pull_from_file() Should fail If hypervisor::clonevm_link fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:12345678900| image:custom_image1|crc:1334567890|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error cloning image cache 'image-cache|crc:12345678900|' to the image vm 'image:custom_image1|crc:1334567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If set_image_cache fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:12345678900| image:custom_image1|crc:1334567890|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "1334567890 image-cache|crc:12345678900|"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error setting attribute image cache 'image-cache|crc:12345678900|' to the image vm 'image:custom_image1|crc:1334567890|'"
}

@test "vedv::image_service::__pull_from_file() Should fail If set_ova_file_sum fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:12345678900| image:custom_image1|crc:1334567890|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "1334567890 image-cache|crc:12345678900|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "1334567890 1234567890"
    return 1
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_failure
  assert_output "Error setting attribute ova file sum '1234567890' to the image vm 'image:custom_image1|crc:1334567890|'"
}

@test "vedv::image_service::__pull_from_file() Should succeed" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:12345678900| image:custom_image1|crc:1334567890|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "1334567890 image-cache|crc:12345678900|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "1334567890 1234567890"
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name"

  assert_success
  assert_output "custom_image1"
}

@test "vedv::image_service::__pull_from_file() Should succeed and echo image_id" {
  local -r image_file="$TEST_OVA_FILE"
  local -r custom_image_name="custom_image1"

  vedv::image_entity::gen_vm_name_from_ova_file() {
    assert_equal "$*" "$TEST_OVA_FILE"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    if [ "$1" == "image:${custom_image_name}|crc:1334567890|" ]; then
      echo '1334567890'
    else
      assert_equal "$*" "image:image1|crc:1234567890|"
      echo '1234567890'
    fi
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    echo 'image1'
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "$custom_image_name"
    echo "image:${custom_image_name}|crc:1334567890|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    if [[ "$1" == "$image_cache_vm_name" ]]; then
      return 0
    fi
    assert_equal "$*" "image:${custom_image_name}|crc:1334567890|"
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "${TEST_OVA_FILE} ${image_cache_vm_name}"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:12345678900| image:custom_image1|crc:1334567890|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "1334567890 image-cache|crc:12345678900|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "1334567890 1234567890"
  }

  run vedv::image_service::__pull_from_file "$image_file" "$custom_image_name" true

  assert_success
  assert_output "1334567890"
}

# Tests for vedv::image_service::list()
@test 'vedv::image_service::list()' {
  :
}
# Tests for vedv::image_service::remove_one()

@test 'vedv::image_service::remove_one() Should fail With empty image_id' {
  local -r image_id=''

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test 'vedv::image_service::remove_one() Should fail If get_vm_name fails' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Error getting vm name for image: '1234567890'
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If vm_name is empty' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "No such image: '1234567890'
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If get_child_containers_ids fails' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Error getting child containers for image: '1234567890'
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If image has child containers' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
    echo "2234567890 2334567890"
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Failed to remove image '1234567890' because it has containers, remove them first: 2234567890 2334567890
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If get_image_cache fails' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" "1234567890"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Error getting image cache for images 1234567890
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If empty image_cache' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" "1234567890"
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Failed to remove image '1234567890' because it has no image cache
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If hypervisor::rm fails' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" "1234567890"
    echo "image-cache|crc:1234567890|"
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "image:image1|crc:1234567890|"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should fail If hypervisor::delete_snapshot fails' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" "1234567890"
    echo "image-cache|crc:1234567890|"
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "image:image1|crc:1234567890|"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image-cache|crc:1234567890|"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Error deleting snapshot for image: '1234567890'
Failed to remove image: '1234567890'"
}

@test 'vedv::image_service::remove_one() Should succeed' {
  local -r image_id='1234567890'

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "1234567890"
    echo "image:image1|crc:1234567890|"
  }
  vedv::image_entity::get_child_containers_ids() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_image_cache() {
    assert_equal "$*" "1234567890"
    echo "image-cache|crc:1234567890|"
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "image:image1|crc:1234567890|"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image-cache|crc:1234567890| image:image1|crc:1234567890|"
  }

  run vedv::image_service::remove_one "$image_id"

  assert_success
  assert_output "1234567890"
}

# Tests for vedv::image_service::list()
@test 'vedv::image_service::remove()' {
  :
}

# Tests for vedv::image_service::remove_unused_cache()

@test 'vedv::image_service::remove_unused_cache(), Should fail If list_vms_by_partial_name fails' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    return 1
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "Error getting image cache vm_names"
}

@test 'vedv::image_service::remove_unused_cache(), Should succeed if there are no image-cache vms' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
  }

  run vedv::image_service::remove_unused_cache

  assert_success
  assert_output ""
}

@test 'vedv::image_service::remove_unused_cache(), Should fail If show_snapshots fails' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    cat <<EOF
image-cache|crc:1234567890|
image-cache|crc:1334567890|
image-cache|crc:1434567890|
EOF
  }
  vedv::hypervisor::show_snapshots() {
    assert_equal "$*" "image-cache|crc:1234567890|"
    return 1
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "Error getting snapshots for vm: 'image-cache|crc:1234567890|'"
}

@test 'vedv::image_service::remove_unused_cache(), Should fail If get_image_id_by_vm_name fails' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    cat <<EOF
image-cache|crc:1234567890|
image-cache|crc:1334567890|
image-cache|crc:1434567890|
EOF
  }
  vedv::hypervisor::show_snapshots() {
    assert_equal "$*" "image-cache|crc:1234567890|"
  }
  vedv::image_cache_entity::get_image_id_by_vm_name() {
    assert_equal "$*" "image-cache|crc:1234567890|"
    return 1
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "Error getting image id by vm name: 'image-cache|crc:1234567890|'"
}

@test 'vedv::image_service::remove_unused_cache(), Should fail If hypervisor::rm fails' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    cat <<EOF
image-cache|crc:1234567890|
image-cache|crc:1334567890|
image-cache|crc:1434567890|
EOF
  }
  vedv::hypervisor::show_snapshots() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
  }
  vedv::image_cache_entity::get_image_id_by_vm_name() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
    echo "${1#*crc:}" | tr -d '|'
  }
  vedv::hypervisor::rm() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
    return 1
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "
Failed to remove caches: 1234567890 1334567890 1434567890 "
}

@test 'vedv::image_service::remove_unused_cache(), Should succeed' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    cat <<EOF
image-cache|crc:1234567890|
image-cache|crc:1334567890|
image-cache|crc:1434567890|
EOF
  }
  vedv::hypervisor::show_snapshots() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
  }
  vedv::image_cache_entity::get_image_id_by_vm_name() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
    echo "${1#*crc:}" | tr -d '|'
  }
  vedv::hypervisor::rm() {
    assert_regex "$*" "(image-cache\|crc:1234567890\||image-cache\|crc:1334567890\||image-cache\|crc:1434567890)"
  }

  run vedv::image_service::remove_unused_cache

  assert_success
  assert_output "1234567890 1334567890 1434567890 "
}

# Tests for vedv::image_service::is_started()
@test 'vedv::image_service::is_started()' {
  :
}

# Tests for vedv::image_service::start()
@test 'vedv::image_service::start()' {
  :
}

# Tests for vedv::image_service::stop()
@test 'vedv::image_service::stop()' {
  :
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
    echo '12345 12346 12347'
  }
  vedv::container_service::remove_one() {
    if [[ "$1" == 12346 ]]; then return 1; fi
  }
  # Act
  run vedv::image_service::child_containers_remove_all "$image_id"
  # Assert
  assert_failure
  assert_output "Failed to remove container: 12346"
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
  vedv::container_service::remove_one() {
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
  vedv::hypervisor::delete_snapshot() {
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
  vedv::hypervisor::delete_snapshot() {
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
  vedv::hypervisor::restore_snapshot() {
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
  vedv::hypervisor::restore_snapshot() {
    assert_equal "$*" "${image_vm_name} ${layer_full_name}"
  }
  # Act
  run vedv::image_service::restore_layer "$image_id" "$layer_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::copy()
@test "vedv::image_service::copy(): DUMMY" {
  :
}

# Tests for vedv::image_service::execute_cmd()
@test "vedv::image_service::execute_cmd(): DUMMY" {
  :
}

# Tests for vedv::image_service::set_workdir()
@test "vedv::image_service::set_workdir(): DUMMY" {
  :
}

# Tests for vedv::image_service::add_environment_var()
@test "vedv::image_service::add_environment_var(): DUMMY" {
  :
}

# Tests for vedv::image_service::get_environment_vars()

@test "vedv::image_service::get_environment_vars() DUMMY" {
  :
}
