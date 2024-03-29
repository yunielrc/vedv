# shellcheck disable=SC2016,SC2140,SC2317,SC2031,SC2030,SC2317,SC2154
# copilot, generate tests using the functions in: "${workspaceFolder}/dist/lib/vedv/components/image/image-service.bash"
# copilot: suggest the comment '' right before each test declaration, DO THIS FOREVER
load test_helper

setup_file() {
  vedv::vmobj_entity::constructor \
    "$(mktemp -d)" \
    'container|image' \
    '([image]="" [container]="parent_image_id")' \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD"

  export __VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR
  export __VEDV_VMOBJ_ENTITY_TYPE
  export __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR
  export __VEDV_DEFAULT_USER
  export __VEDV_DEFAULT_PASSWORD

  vedv::vmobj_service::constructor \
    "$TEST_SSH_IP" \
    "$TEST_SSH_USER"

  export __VEDV_VMOBJ_SERVICE_SSH_IP
  export __VEDV_VMOBJ_SERVICE_SSH_USER

  vedv::image_service::constructor "$TEST_IMAGE_TMP_DIR" 'false' 'true'
  export __VEDV_IMAGE_SERVICE_IMPORTED_DIR
  export __VEDV_IMAGE_SERVICE_CHANGE_PASSWORD_ON_IMPORT
  export __VEDV_IMAGE_SERVICE_NO_CHANGE_PASSWORD_ON_EXPORT
  export __VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG
}

setup() {
  mkdir -p "$TEST_IMAGE_TMP_DIR"
}

teardown() {
  if [[ -d "$TEST_IMAGE_TMP_DIR" &&
    "$TEST_IMAGE_TMP_DIR" == */tmp/* ]]; then
    rm -rf "$TEST_IMAGE_TMP_DIR"
  fi
  [[ -d "$TEST_IMAGE_TMP_DIR" ]] ||
    mkdir -p "$TEST_IMAGE_TMP_DIR"
}

# Tests for vedv::image_service::import()

@test "vedv::image_service::import() Should fails If 'image_file' doesn't exist" {
  local -r image_file="/tmp/feacd213baf31d50798a.ova"

  run vedv::image_service::import "$image_file"

  assert_failure
  assert_output "image file doesn't exist"
}

@test "vedv::image_service::import() Should fail If exists_with_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    return 1
  }

  run vedv::image_service::import "$image_file" "$image_name"

  assert_failure
  assert_output "Failed to check if image with name: '${image_name}' already exist"
}

@test "vedv::image_service::import() Should fail If exists an image with the same name" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo true
  }

  run vedv::image_service::import "$image_file" "$image_name"

  assert_failure
  assert_output "Image with name: 'image1' already exist, you can delete it or use another name"
}

@test "vedv::image_service::import() Should fail If sha256sum_check fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to check sha256sum for image file: '${image_file}'"
}

@test "vedv::image_service::import() Should fail If crc_sum fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to calculate crc sum for image file: '${image_file}'"
}

@test "vedv::image_service::import() Should fail If exists_vm_with_partial_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error getting virtual machine with name: 'image-cache|crc:123456|'"
}

@test "vedv::image_service::import() Should fail If hypervisor::import fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error creating image cache 'image-cache|crc:123456|' vm from ova file '/tmp/vedv/test/files/alpine-x86_64.ova'"
}

@test "vedv::image_service::import() Should fail If image_entity::gen_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "image1"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to generate image vm name for image: 'image1'"
}

@test "vedv::image_service::import() Should fail If clonevm_link fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name="image1"
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_service::exists_with_name() {
    assert_equal "$*" "image1"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" "image1"
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to clone vm: 'image-cache|crc:123456|' to: 'image:gen-name|crc:133456|'"
}

@test "vedv::image_service::import() Should fail If get_id_by_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error getting image_id for vm_name 'image:gen-name|crc:133456|'"
}

@test "vedv::image_service::import() Should fail If after_create fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error on after create event: '133456'"
}
# bats test_tags=only
@test "vedv::image_service::import() Should fail If set_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to set vm name for image: '133456'"
}
# bats test_tags=only
@test "vedv::image_service::import() Should fail If ____clear_child_container_ids fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Failed to clear child container ids for image: '133456'"
}

@test "vedv::image_service::import() Should fail If get_image_name_by_vm_name fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error getting image_name for vm_name 'image:gen-name|crc:133456|'"
}

@test "vedv::image_service::import() Should fail If set_image_cache fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error setting attribute image cache 'image-cache|crc:123456|' to the image 'image:gen-name|crc:133456|'"
}

@test "vedv::image_service::import() Should fail If set_ova_file_sum fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
    return 1
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error setting attribute ova file sum '123456' to the image 'image:gen-name|crc:133456|'"
}

@test "vedv::image_service::import() Should fail If __gen_change_password fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
  }
  vedv::image_service::__gen_change_password() {
    assert_equal "$*" "133456"
    return 1
  }
  vedv::image_service::get_change_password_on_import() {
    assert_equal "$*" ""
    echo "true"
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error changing password for image '133456'"
}

@test "vedv::image_service::import() Should fail If image_service::stop fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
  }
  vedv::image_service::__gen_change_password() {
    assert_equal "$*" "133456"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "133456"
    return 1
  }
  vedv::image_service::get_change_password_on_import() {
    assert_equal "$*" ""
    echo "true"
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error stopping image '133456'"
}

@test "vedv::image_service::import() Should fail If create_layer_from fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
  }
  vedv::image_service::__gen_change_password() {
    assert_equal "$*" "133456"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "133456"
  }
  vedv::image_service::create_layer_from() {
    assert_equal "$*" "133456 ${image_file}"
    return 1
  }
  vedv::image_service::get_change_password_on_import() {
    assert_equal "$*" ""
    echo "true"
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_failure
  assert_output "Error creating the first layer for image '133456'"
}

@test "vedv::image_service::import() Should succeed changing password" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "image:gen-name|crc:133456|"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
  }
  vedv::image_service::__gen_change_password() {
    assert_equal "$*" "133456"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "133456"
  }
  vedv::image_service::create_layer_from() {
    assert_equal "$*" "133456 ${image_file}"
  }
  vedv::image_service::get_change_password_on_import() {
    assert_equal "$*" ""
    echo "true"
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_success
  assert_output "133456 image:gen-name|crc:133456|"
}

@test "vedv::image_service::import() Should succeed" {
  local -r image_file="$TEST_OVA_FILE"
  local -r image_name=""
  local -r checksum_file="/tmp/f31d50798a.ova.sha256sum"

  vedv::image_service::exists_with_name() {
    assert_equal "$*" "INVALID_CALL"
    echo false
  }
  utils::sha256sum_check() {
    assert_equal "$*" "$checksum_file"
  }
  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "123456"
  }
  vedv::image_cache_entity::get_vm_name() {
    assert_equal "$*" "123456"
    echo "image-cache|crc:123456|"
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image-cache|crc:123456|"
    echo false
  }
  vedv::hypervisor::import() {
    assert_equal "$*" "$image_file image-cache|crc:123456|"
  }
  vedv::image_entity::gen_vm_name() {
    assert_equal "$*" ""
    echo "image:gen-name|crc:133456|"
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image-cache|crc:123456| image:gen-name|crc:133456|"
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo '133456'
  }
  vedv::vmobj_service::after_create() {
    assert_equal "$*" "image 133456"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "133456 image:gen-name|crc:133456|"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "133456"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:gen-name|crc:133456|"
    echo "gen-name"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "133456 image-cache|crc:123456|"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "133456 123456"
  }
  vedv::image_service::create_layer_from() {
    assert_equal "$*" "133456 ${image_file}"
  }

  run vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"

  assert_success
  assert_output "133456 gen-name"
}

# Tests for vedv::image_service::list()

@test 'vedv::image_service::list() Should succeed' {

  vedv::vmobj_service::list() {
    assert_equal "$*" "image true"
  }

  run vedv::image_service::list

  assert_success
  assert_output ""
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
  assert_output "Failed to remove image '1234567890' because it has child containers. Remove child containers first or force remove. Child containers ids: 2234567890 2334567890"
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

@test 'vedv::image_service::remove_one() Should fail If after_remove fails' {
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
  vedv::vmobj_service::after_remove() {
    assert_equal "$*" "image 1234567890"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_failure
  assert_output "Error on after remove event: '${image_id}'"
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
  vedv::vmobj_service::after_remove() {
    assert_equal "$*" "image 1234567890"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image-cache|crc:1234567890|"
    return 1
  }

  run vedv::image_service::remove_one "$image_id"

  assert_success
  assert_output "Warning, not deleted snapshot on image cache for image: '1234567890'. The snapshot will be deleted when the image cache is removed, so no need to worry.
1234567890"
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
  vedv::vmobj_service::after_remove() {
    assert_equal "$*" "image 1234567890"
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$*" "image-cache|crc:1234567890| image:image1|crc:1234567890|"
  }

  run vedv::image_service::remove_one "$image_id"

  assert_success
  assert_output "1234567890"
}

# Tests for vedv::image_service::remove()
@test 'vedv::image_service::remove() Should succeed' {
  local -r image_id='1234567890'
  local -r force='true'

  vedv::vmobj_service::exec_func_on_many_vmobj() {
    assert_equal "$*" "image vedv::image_service::remove_one_batch 'true' 1234567890"
  }

  run vedv::image_service::remove "$image_id" "$force"

  assert_success
  assert_output ""
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

@test 'vedv::image_service::remove_unused_cache(), Should fail If exists_vm_with_partial_name fails' {

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
    cat <<EOF
image:image1|crc:2234567890|
image:image2|crc:2334567890|
image:image3|crc:2434567890|
EOF
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    assert_equal "$*" "image:image1|crc:2234567890|"
    return 1
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "Error checking if vm exists: 'image:image1|crc:2234567890|'"
}

@test 'vedv::image_service::remove_unused_cache(), Should show error If delete_snapshot fails' {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image-cache|"
    cat <<EOF
image-cache|crc:1234567890|
image-cache|crc:1334567890|

EOF
  }
  vedv::hypervisor::show_snapshots() {
    if [ "$*" == "image-cache|crc:1334567890|" ]; then
      return 1
    fi

    assert_equal "$*" "image-cache|crc:1234567890|"
    cat <<EOF
image:image1|crc:2234567890|
image:image2|crc:2334567890|
image:image3|crc:2434567890|
EOF
  }
  vedv::hypervisor::exists_vm_with_partial_name() {
    case "$1" in
    "image:image1|crc:2234567890|" | "image:image2|crc:2334567890|")
      echo false
      return 0
      ;;
    "image:image3|crc:2434567890|")
      echo true
      return 0
      ;;
    *)
      return 2
      ;;
    esac
  }
  vedv::hypervisor::delete_snapshot() {
    assert_equal "$1" "image-cache|crc:1234567890|"
    case "$2" in
    "image:image1|crc:2234567890|")
      return 1
      ;;
    "image:image2|crc:2334567890|")
      return 0
      ;;
    *)
      return 2
      ;;
    esac
  }

  run vedv::image_service::remove_unused_cache

  assert_failure
  assert_output "Warning, not deleted orphaned snapshot: 'image:image1|crc:2234567890|' on image cache: 'image-cache|crc:1234567890|'
Error getting snapshots for vm: 'image-cache|crc:1334567890|'"
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
@test 'vedv::image_service::is_started() Should succeed' {
  local -r image_id='1234567890'

  vedv::vmobj_service::is_started() {
    assert_equal "$*" "image 1234567890"
  }

  run vedv::image_service::is_started "$image_id"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::start()
@test 'vedv::image_service::start() Should succeed' {
  local -r image_id='1234567890'

  vedv::vmobj_service::start_one() {
    assert_equal "$*" "image 1234567890 true"
  }

  run vedv::image_service::start "$image_id"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::stop()
@test 'vedv::image_service::stop() Should succeed' {
  local -r image_id='1234567890'

  vedv::vmobj_service::stop_one() {
    assert_equal "$*" "image 1234567890"
  }

  run vedv::image_service::stop "$image_id"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::poweroff()
@test 'vedv::image_service::poweroff() DUMMY' {
  :
}

# Tests for vedv::image_service::save_state()
@test 'vedv::image_service::save_state() Should succeed' {
  local -r image_id='1234567890'

  vedv::vmobj_service::save_state_one() {
    assert_equal "$*" "image 1234567890"
  }

  run vedv::image_service::save_state "$image_id"

  assert_success
  assert_output ""
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
@test "vedv::image_service::copy(): Should succeed" {
  local -r image_id="12345"
  local -r src="src1"
  local -r dest="dest1"
  local -r user="vedv"
  local -r chown="nalyd"
  local -r chmod="644"

  vedv::vmobj_service::copy_by_id() {
    assert_equal "$*" "image 12345 src1 dest1 vedv  nalyd 644"
  }
}

# Tests for vedv::image_service::execute_cmd()

@test "vedv::image_service::execute_cmd(): Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 RUN echo 'hello'"
  local -r user="vedv"

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 1 RUN echo 'hello' vedv"
  }

  run vedv::image_service::execute_cmd "$image_id" "$cmd" "$user"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::set_workdir()

@test "vedv::image_service::fs::set_workdir(): Should succeed" {
  local -r image_id="12345"
  local -r workdir="/home/vedv"

  vedv::vmobj_service::fs::set_workdir() {
    assert_equal "$*" "image 12345 /home/vedv"
  }

  run vedv::image_service::fs::set_workdir "$image_id" "$workdir"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::add_environment_var()

@test "vedv::image_service::fs::add_environment_var() Should succeed" {
  local -r image_id="12345"
  local -r env_var="TEST_ENV=123"

  vedv::vmobj_service::fs::add_environment_var() {
    assert_equal "$*" "image 12345 TEST_ENV=123"
  }

  run vedv::image_service::fs::add_environment_var "$image_id" "$env_var"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::list_environment_vars()

@test "vedv::image_service::fs::list_environment_vars() Should succeed" {
  local -r image_id="12345"

  vedv::vmobj_service::fs::list_environment_vars() {
    assert_equal "$*" "image 12345"
  }

  run vedv::image_service::fs::list_environment_vars "$image_id"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::restore_last_layer()

@test "vedv::image_service::restore_last_layer() Should fail With empty image_id" {
  # Arrange
  local -r image_id=""
  # Act
  run vedv::image_service::restore_last_layer "$image_id"

  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::restore_last_layer() Should fail If get_last_layer_id fails" {
  # Arrange
  local -r image_id="image_id"
  # Stub
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_service::restore_last_layer "$image_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get last layer id for image '${image_id}'"
}

@test "vedv::image_service::restore_last_layer() Should fail If empty last_layer_id" {
  # Arrange
  local -r image_id="image_id"
  # Stub
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
  }
  # Act
  run vedv::image_service::restore_last_layer "$image_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Last layer not found for image 'image_id'"
}

@test "vedv::image_service::restore_last_layer() Should fail If restore_layer fails" {
  # Arrange
  local -r image_id="image_id"
  local -r last_layer_id="last_layer_id"
  # Stub
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo "last_layer_id"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "$image_id $last_layer_id"
    return 1
  }
  # Act
  run vedv::image_service::restore_last_layer "$image_id"

  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to restore last layer '${last_layer_id}'"
}

# Tests for vedv::image_service::fs::set_shell()

@test "vedv::image_service::fs::set_shell(): Should succeed" {
  local -r image_id=23456
  local -r shell='sh'

  vedv::vmobj_service::fs::set_shell() {
    assert_equal "$*" 'image 23456 sh'
  }

  run vedv::image_service::fs::set_shell "$image_id" "$shell"

  assert_success
  assert_output ''
}

# Tests for vedv::image_service::copy()
@test "vedv::image_service::copy() Should succeed" {
  # Arrange
  local -r image_id="image_id"
  local -r src="src1"
  local -r dest="src2"
  local -r user="vedv"
  local -r chown="nalyd"
  local -r chmod="644"
  # Stub
  vedv::vmobj_service::copy_by_id() {
    assert_equal "$*" "image ${image_id} ${src} ${dest} ${user}  ${chown} ${chmod}"
  }
  # Act
  run vedv::image_service::copy "$image_id" "$src" "$dest" "$user" "$chown" "$chmod"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::delete_layer_cache()

@test "vedv::image_service::delete_layer_cache() Should fail With empty image_id" {
  # Arrange
  local -r image_id=""
  # Act
  run vedv::image_service::delete_layer_cache "$image_id"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::delete_layer_cache() Should fail If get_layers_ids fails" {
  # Arrange
  local -r image_id=2345
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer_cache "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to get layers ids for image '${image_id}'"
}

@test "vedv::image_service::delete_layer_cache() Should fail If delete_layer fails" {
  # Arrange
  local -r image_id=2345
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1234560 1234561 1234562 1234563"
  }
  vedv::image_service::delete_layer() {
    assert_equal "$*" "${image_id} 1234563"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer_cache "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to delete layer '1234563' for image '${image_id}'"
}

@test "vedv::image_service::delete_layer_cache() Should fail If restore_layer fails" {
  # Arrange
  local -r image_id=2345
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1234560 1234561 1234562 1234563"
  }
  vedv::image_service::delete_layer() {
    assert_regex "$*" "${image_id} (1234563|1234562|1234561)"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} 1234560"
    return 1
  }
  # Act
  run vedv::image_service::delete_layer_cache "$image_id"
  # Assert
  assert_failure "$ERR_IMAGE_OPERATION"
  assert_output "Failed to restore layer '1234560' for image '${image_id}'"
}

@test "vedv::image_service::delete_layer_cache() Should succeed" {
  # Arrange
  local -r image_id=2345
  # Stub
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1234560 1234561 1234562 1234563"
  }
  vedv::image_service::delete_layer() {
    assert_regex "$*" "${image_id} (1234563|1234562|1234561)"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} 1234560"
  }
  # Act
  run vedv::image_service::delete_layer_cache "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::add_exposed_ports()

@test "vedv::image_service::fs::add_exposed_ports() Should fail With empty image_id" {
  # Arrange
  local -r image_id=""
  local -r ports="1234 1235"
  # Stubs
  vedv::vmobj_service::fs::add_exposed_ports() {
    assert_equal "$*" "image ${image_id} ${ports}"
  }
  # Act
  run vedv::image_service::fs::add_exposed_ports "$image_id" "$ports"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::cache_data()
@test "vedv::image_service::cache_data() Should fail With empty image_id" {
  # Arrange
  local -r image_id=""

  # Act
  run vedv::image_service::cache_data "$image_id"
  # Assert
  assert_failure
  assert_output "Invalid argument 'image_id': it's empty"
}

@test "vedv::image_service::cache_data() Should fail If cache_data fails" {
  # Arrange
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::cache_data() {
    assert_equal "$*" "image ${image_id}"
    return 1
  }
  # Act
  run vedv::image_service::cache_data "$image_id"
  # Assert
  assert_failure
  assert_output "Failed to cache data for image '12345'"
}

@test "vedv::image_service::cache_data() Should succeed" {
  # Arrange
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::cache_data() {
    assert_equal "$*" "image ${image_id}"
  }
  # Act
  run vedv::image_service::cache_data "$image_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::set_user()
@test "vedv::image_service::fs::set_user() Should succeed" {
  # Arrange
  local -r image_id="12345"
  local -r user="user"
  # Stub
  vedv::vmobj_service::fs::set_user() {
    assert_equal "$*" "image ${image_id} ${user}"
  }
  # Act
  run vedv::image_service::fs::set_user "$image_id" "$user"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::cache::get_use_cache()
@test "vedv::image_service::cache::get_use_cache() Should succeed" {

  vedv::vmobj_service::get_use_cache() {
    assert_equal "$*" 'image'
  }

  run vedv::image_service::get_use_cache

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::cache::set_use_cache()
@test "vedv::image_service::cache::set_use_cache() Should succeed" {

  vedv::vmobj_service::set_use_cache() {
    assert_equal "$*" 'image true'
  }

  run vedv::image_service::set_use_cache 'true'

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::cache::list_exposed_ports()

@test "vedv::image_service::cache::list_exposed_ports() Should succeed" {
  local -r image_name_or_id='12345'

  vedv::vmobj_entity::get_id() {
    assert_equal "$*" "12345"
    echo 12345
  }
  vedv::image_entity::cache::get_exposed_ports() {
    assert_equal "$*" '12345'
  }

  run vedv::image_service::cache::list_exposed_ports "$image_name_or_id"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::import_from_url()
@test "vedv::image_service::import_from_url() Should fail If image_url is empty" {
  # Arrange
  local -r image_url=""
  local -r image_name=""
  local -r checksum_url=""

  # Stub
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "image_url is required"
}

@test "vedv::image_service::import_from_url() Should fail If image_url is not valid" {
  # Arrange
  local -r image_url="http:files.get/image"
  local -r image_name=""
  local -r checksum_url=""

  # Stub
  utils::is_url() {
    assert_equal "$*" "$image_url"
    return 1
  }
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "image_url is not valid"
}

@test "vedv::image_service::import_from_url() Should fail If checksum_url is not valid" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 1 ;;
    *) return 2 ;;
    esac
  }
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "checksum_url is not valid"
}

@test "vedv::image_service::import_from_url() Should fail If download dir does not exist" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }
  if [[ -d "$TEST_IMAGE_TMP_DIR" &&
    "$TEST_IMAGE_TMP_DIR" =~ ^/tmp/ ]]; then
    rm -rf "$TEST_IMAGE_TMP_DIR"
  fi
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output --partial "Download directory does not exist:"
}

@test "vedv::image_service::import_from_url() Should fail If download_file for checksum fails" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }
  mkdir() {
    assert_regex "$*" "-p ${TEST_IMAGE_TMP_DIR}.*"
  }
  file_downloader::http_download() {
    case "$*" in
    "$image_url"*) return 0 ;;
    "$checksum_url"*) return 1 ;;
    *) return 2 ;;
    esac
  }
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "Error downloading checksum from url: '${checksum_url}'"
}

@test "vedv::image_service::import_from_url() Should fail If download_file for image fails" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url=""

  # Stub
  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }
  mkdir() {
    assert_regex "$*" "-p ${TEST_IMAGE_TMP_DIR}.*"
  }
  file_downloader::http_download() {
    case "$*" in
    "$image_url"*) return 1 ;;
    "$checksum_url"*) return 0 ;;
    *) return 2 ;;
    esac
  }
  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "Error downloading image from url: '${image_url}'"
}

@test "vedv::image_service::import_from_url() Should fail If read checksum fails" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  local -r download_dir="$TEST_IMAGE_TMP_DIR"
  local -r image_file="${download_dir}/image-$(md5sum <<<"$image_url" | cut -d' ' -f1).ova"
  local -r checksum_file="${image_file}.sha256sum"

  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }
  file_downloader::http_download() {
    case "$*" in
    "$image_url"*)
      echo 'image.ova content' >"$image_file"
      return 0
      ;;
    "$checksum_url"*)
      return 0
      ;;
    *) return 1 ;;
    esac
  }

  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output --partial "Error reading checksum file: '/tmp/vedv/images/"
}

@test "vedv::image_service::import_from_url() Should fail If write checksum fails" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  local -r download_dir="$TEST_IMAGE_TMP_DIR"
  local -r image_file="${download_dir}/image-$(md5sum <<<"$image_url" | cut -d' ' -f1).ova"
  local -r checksum_file="${image_file}.sha256sum"

  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }

  echo 'image.ova content' >"$image_file"

  file_downloader::http_download() {
    case "$*" in
    "$image_url"*)
      return 0
      ;;
    "$checksum_url"*)
      echo "$(md5sum "$image_file" | cut -d' ' -f1) image_file" >"$checksum_file"
      chmod -w "$checksum_file"
      return 0
      ;;
    *) return 1 ;;
    esac
  }

  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output --partial "Error writing checksum file: '${checksum_file}'"
}

@test "vedv::image_service::import_from_url() Should fail If import fails" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  local -r download_dir="$TEST_IMAGE_TMP_DIR"
  local -r image_file="${download_dir}/image-$(md5sum <<<"$image_url" | cut -d' ' -f1).ova"
  local -r checksum_file="${image_file}.sha256sum"

  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }

  echo 'image.ova content' >"$image_file"

  file_downloader::http_download() {
    case "$*" in
    "$image_url"*)
      return 0
      ;;
    "$checksum_url"*)
      echo "$(sha256sum "$image_file" | cut -d' ' -f1) image_file" >"$checksum_file"
      return 0
      ;;
    *) return 1 ;;
    esac
  }

  vedv::image_service::import() {
    assert_equal "$*" "${image_file} ${image_name} ${checksum_file}"
    assert_equal "361e5b6aa374cda9eb949eeb1d2a8b7bb6d1c36060b519e6916ec41b4a0f1667 image-95285a18b1628d7cc8e4d8cd410fd335.ova" "$(<"$checksum_file")"
    return 1
  }

  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_failure
  assert_output "Error importing image from file: '${image_file}'"
}

@test "vedv::image_service::import_from_url() Should succeed" {
  # Arrange
  local -r image_url="http://files.get/image"
  local -r image_name=""
  local -r checksum_url="http://files.get/checksum"

  # Stub
  local -r download_dir="$TEST_IMAGE_TMP_DIR"
  local -r image_file="${download_dir}/image-$(md5sum <<<"$image_url" | cut -d' ' -f1).ova"
  local -r checksum_file="${image_file}.sha256sum"

  utils::is_url() {
    case "$*" in
    "$image_url") return 0 ;;
    "$checksum_url") return 0 ;;
    *) return 2 ;;
    esac
  }

  echo 'image.ova content' >"$image_file"

  file_downloader::http_download() {
    case "$*" in
    "$image_url"*)
      return 0
      ;;
    "$checksum_url"*)
      echo "$(sha256sum "$image_file" | cut -d' ' -f1) image_file" >"$checksum_file"
      return 0
      ;;
    *) return 1 ;;
    esac
  }

  vedv::image_service::import() {
    assert_equal "$*" "${image_file} ${image_name} ${checksum_file}"
    assert_equal "361e5b6aa374cda9eb949eeb1d2a8b7bb6d1c36060b519e6916ec41b4a0f1667 image-95285a18b1628d7cc8e4d8cd410fd335.ova" "$(<"$checksum_file")"
  }

  # Act
  run vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url"

  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::exists_with_id()
@test "vedv::image_service::exists_with_id() Should succeed" {
  # Arrange
  local -r image_id="image1"
  # Stub
  vedv::vmobj_service::exists_with_id() {
    assert_equal "$*" "image ${image_id}"
  }
  # Act
  run vedv::image_service::exists_with_id "$image_id"

  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::exists_with_name()
@test "vedv::image_service::exists_with_name() Should succeed" {
  # Arrange
  local -r image_name="image1"
  # Stub
  vedv::vmobj_service::exists_with_name() {
    assert_equal "$*" "image ${image_name}"
  }
  # Act
  run vedv::image_service::exists_with_name "$image_name"

  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_service::create_layer()
@test "vedv::image_service::create_layer() Should fail With invalid image_id" {
  local -r image_id="invalid"
  local -r layer_name="123456"
  local -r layer_id="invalid"

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_service::create_layer() Should fail With invalid layer_name" {
  local -r image_id="223456789"
  local -r layer_name="invalid"
  local -r layer_id="3234567890"

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Invalid layer name 'invalid'"
}

@test "vedv::image_service::create_layer() Should fail With invalid layer_id" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="invalid"

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_service::create_layer() Should fail If has_layer_id fails" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="3234567890"
  # Stub
  vedv::image_entity::has_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    return 1
  }

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Failed to check if layer 'FROM' exists for image '223456789'"
}

@test "vedv::image_service::create_layer() Should fail If layer id exists" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="3234567890"
  # Stub
  vedv::image_entity::has_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo true
  }

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Layer 'FROM' already exists for image '223456789'"
}

@test "vedv::image_service::create_layer() Should fail If get_vm_name fails" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="3234567890"
  # Stub
  vedv::image_entity::has_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo false
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "${image_id}"
    return 1
  }

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Failed to get vm name for image '223456789'"
}

@test "vedv::image_service::create_layer() Should fail If take_snapshot fails" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="3234567890"
  # Stub
  vedv::image_entity::has_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo false
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "${image_id}"
    echo "image:nalyd1|crc:223456789|"
  }
  local -r full_layer_name="layer:${layer_name}|id:${layer_id}|"

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "image:nalyd1|crc:223456789| ${full_layer_name}"
    return 1
  }

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_failure
  assert_output "Failed to create layer 'layer:FROM|id:3234567890|' for image '223456789'"
}

@test "vedv::image_service::create_layer() Should succeed" {
  local -r image_id="223456789"
  local -r layer_name="FROM"
  local -r layer_id="3234567890"
  # Stub
  vedv::image_entity::has_layer_id() {
    assert_equal "$*" "${image_id} ${layer_id}"
    echo false
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "${image_id}"
    echo "image:nalyd1|crc:223456789|"
  }
  local -r full_layer_name="layer:${layer_name}|id:${layer_id}|"

  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "image:nalyd1|crc:223456789| ${full_layer_name}"
  }

  run vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"

  assert_success
  assert_output "3234567890"
}

# Tests for vedv::image_service::create_layer_from()
@test "vedv::image_service::create_layer_from() Should fail With invalid image_id" {
  local -r image_id="invalid"
  local -r image_file="$TEST_OVA_FILE"

  run vedv::image_service::create_layer_from "$image_id" "$image_file"

  assert_failure
  assert_output "Invalid argument 'invalid'"
}

@test "vedv::image_service::create_layer_from() Should fail If file does not exist" {
  local -r image_id="223456789"
  local -r image_file="invalid"

  run vedv::image_service::create_layer_from "$image_id" "$image_file"

  assert_failure
  assert_output "image file doesn't exist, path: 'invalid'"
}

@test "vedv::image_service::create_layer_from() Should fail If crc_sum fails" {
  local -r image_id="223456789"
  local -r image_file="$TEST_OVA_FILE"

  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    return 1
  }

  run vedv::image_service::create_layer_from "$image_id" "$image_file"

  assert_failure
  assert_output --partial "Failed to calculate crc sum for image file "
}

@test "vedv::image_service::create_layer_from() Should succeed" {
  local -r image_id="223456789"
  local -r image_file="$TEST_OVA_FILE"

  utils::crc_sum() {
    assert_equal "$*" "$image_file"
    echo "4278381351"
  }
  vedv::image_service::create_layer() {
    assert_equal "$*" "${image_id} FROM 4278381351"
    echo "4278381351"
  }
  run vedv::image_service::create_layer_from "$image_id" "$image_file"

  assert_success
  assert_output "4278381351"
}

# Tests for vedv::image_service::export_by_id()
@test "vedv::image_service::export_by_id() Should fail With empty image_id" {
  local -r image_id=""
  local -r image_file=""
  local -r no_checksum=""
  local -r no_change_password=""

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::export_by_id() Should fail With empty image_file" {
  local -r image_id="1234567890"
  local -r image_file=""
  local -r no_checksum=""
  local -r no_change_password=""

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Argument 'image_file' is required"
}

@test "vedv::image_service::export_by_id() Should fail If rm fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  : >"$image_file"
  rm() {
    if [[ "$*" == '-f'*'/image123.ova' ]]; then
      return 1
    fi
    command rm "$@"
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to remove existing image file: '/tmp/vedv/images/image123.ova'"
}

@test "vedv::image_service::export_by_id() Should fail If get_vm_name fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to get image name by id '1234567890'"
}

@test "vedv::image_service::export_by_id() Should fail If get_image_name_by_vm_name fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to get image name for vm 'image:nalyd1|crc:223456789|'"
}

@test "vedv::image_service::export_by_id() Should fail If get_last_layer_id fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to get last image layer id for image: 'nalyd1'"
}

@test "vedv::image_service::export_by_id() Should fail If get_snapshot_name_by_layer_id fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to get image layer snapshot name for image: 'nalyd1'"
}

@test "vedv::image_service::export_by_id() Should fail If gen_vm_name fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to generate image vm name for image: 'img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If get_id_by_vm_name fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to get image id for image: 'img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If clonevm_link fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to clone vm: 'image:nalyd1|crc:223456789|' to: 'image:img09f5-b520dce8|crc:697829166|'"
}

@test "vedv::image_service::export_by_id() Should fail If hypervisor::get_state fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to get vm state for image: img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If clone_vm_state == saved fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'saved'
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed exporting image 'nalyd1' because it's last layer is in saved state"
}

@test "vedv::image_service::export_by_id() Should fail If set_vm_name fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to set vm name for image: 'img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If __prepare_image_for_export fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to prepare image for export: 'img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If export fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=""
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output --partial "Failed to export image 'img09f5-b520dce8"
}

@test "vedv::image_service::export_by_id() Should fail If hypervisor::rm fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=true
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
  }
  vedv::hypervisor::rm() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to remove image clone: 'image:img09f5-b520dce8|crc:697829166|'"
}

@test "vedv::image_service::export_by_id() Should succeed With no_checksum=true" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=true
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_success
  assert_output ""
}

@test "vedv::image_service::export_by_id() Should if cd fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=false
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
  }
  cd() {
    if [[ "$*" == "$image_file_dir" ]]; then
      return 1
    fi
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to change directory to '/tmp/vedv/images'"
}

@test "vedv::image_service::export_by_id() Should if sha256sum fails" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=false
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
  }
  sha256sum() {
    assert_equal "$*" "$image_file_basename"
    return 1
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_failure
  assert_output "Failed to create checksum file 'image123.ova.sha256sum'"
}

@test "vedv::image_service::export_by_id() Should succeed" {
  local -r image_id="1234567890"
  local -r image_file="${TEST_IMAGE_TMP_DIR}/image123.ova"
  local -r no_checksum=false
  local -r no_change_password=""

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:nalyd1|crc:223456789|"
  }
  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:nalyd1|crc:223456789|"
    echo 'nalyd1'
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo '2234567890'
  }
  vedv::image_entity::get_snapshot_name_by_layer_id() {
    assert_equal "$*" "${image_id} 2234567890"
    echo 'layer:FROM|id:2234567890|'
  }
  openssl() {
    echo 'b520dce8'
  }
  vedv::image_entity::gen_vm_name() {
    assert_regex "$*" "img09f5-b520dce8"
    echo 'image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_entity::get_id_by_vm_name() {
    assert_equal "$*" 'image:img09f5-b520dce8|crc:697829166|'
    echo '697829166'
  }
  vedv::hypervisor::clonevm_link() {
    assert_equal "$*" "image:nalyd1|crc:223456789| image:img09f5-b520dce8|crc:697829166| layer:FROM|id:2234567890| false"
  }
  vedv::hypervisor::rm() {
    :
  }
  vedv::hypervisor::get_state() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166|"
    echo 'poweroff'
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" '697829166 image:img09f5-b520dce8|crc:697829166|'
  }
  vedv::image_service::__prepare_image_for_export() {
    assert_equal "$*" "697829166 ${no_change_password}"
  }
  vedv::hypervisor::export() {
    assert_equal "$*" "image:img09f5-b520dce8|crc:697829166| ${image_file} nalyd1"
  }
  sha256sum() {
    assert_equal "$*" "$image_file_basename"
  }

  run vedv::image_service::export_by_id \
    "$image_id" "$image_file" "$no_checksum" "$no_change_password"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::fs::get_cpus()
@test "vedv::image_service::fs::get_cpus() Should fail If execute_cmd_by_id fails" {
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-getcpus root <none>"
    return 1
  }

  run vedv::image_service::fs::get_cpus "$image_id"

  assert_failure
  assert_output "Failed to get cpus for image: 12345"
}

@test "vedv::image_service::fs::get_cpus() Should succeed" {
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-getcpus root <none>"
    echo 'vedv'
  }

  run vedv::image_service::fs::get_cpus "$image_id"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::image_service::fs::get_memory()
@test "vedv::image_service::fs::get_memory() Should fail If execute_cmd_by_id fails" {
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-getmemory root <none>"
    return 1
  }

  run vedv::image_service::fs::get_memory "$image_id"

  assert_failure
  assert_output "Failed to get memory for image: 12345"
}

@test "vedv::image_service::fs::get_memory() Should succeed" {
  local -r image_id="12345"
  # Stub
  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-getmemory root <none>"
    echo 'vedv'
  }

  run vedv::image_service::fs::get_memory "$image_id"

  assert_success
  assert_output "vedv"
}

# Tests for vedv::image_service::fs::set_system()
@test "vedv::image_service::fs::set_system() Should fail With empty cpu and memory" {
  local -r image_id="12345"
  local -r cpus=""
  local -r memory=""

  run vedv::image_service::fs::set_system \
    "$image_id" "$cpus" "$memory"

  assert_failure
  assert_output "At least one of cpus or memory must be set"
}

@test "vedv::image_service::fs::set_system() Should fail If execute_cmd_by_id fails" {
  local -r image_id="12345"
  local -r cpus=4
  local -r memory=512

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-setcpus '${cpus}'; vedv-setmemory '${memory}' root <none>"
    return 1
  }

  run vedv::image_service::fs::set_system \
    "$image_id" "$cpus" "$memory"

  assert_failure
  assert_output "Failed to modify system for image: 12345"
}

@test "vedv::image_service::fs::set_system() Should succeed" {
  local -r image_id="12345"
  local -r cpus=4
  local -r memory=512

  vedv::vmobj_service::execute_cmd_by_id() {
    assert_equal "$*" "image 12345 vedv-setcpus '${cpus}'; vedv-setmemory '${memory}' root <none>"
  }
  vedv::vmobj_service::modify_system() {
    assert_equal "$*" "image 12345 ${cpus} ${memory}"
  }

  run vedv::image_service::fs::set_system \
    "$image_id" "$cpus" "$memory"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::import_from_any()
@test "vedv::image_service::import_from_any() Should succeed" {
  local -r image='alpine-14'
  local -r image_name=""

  # Stub
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo true
  }

  run vedv::image_service::import_from_any \
    "$image" \
    "$image_name"

  assert_success
  assert_output "2498337635 alpine-14"
}

@test "vedv::image_service::import_from_any() Should fail If import fails" {
  local -r image="$TEST_OVA_FILE"
  local -r image_name=""

  # Stub
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo false
  }
  vedv::image_service::import() {
    assert_equal "$*" "${image} ${image_name}"
    return 1
  }

  run vedv::image_service::import_from_any \
    "$image" \
    "$image_name"

  assert_failure
  assert_output "Error importing image from file: ${image}"
}

@test "vedv::image_service::import_from_any() Should fail If import_from_url fails" {
  local -r image='http://files.get/image'
  local -r image_name=""

  # Stub
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo false
  }
  vedv::image_service::import() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::import_from_url() {
    assert_equal "$*" "${image} ${image_name}"
    return 1
  }

  run vedv::image_service::import_from_any \
    "$image" \
    "$image_name"

  assert_failure
  assert_output "Error importing image from url: ${image}"
}

@test "vedv::image_service::import_from_any() Should fail If pull fails" {
  local -r image='admin@alpine-test/alpine-14'
  local -r image_name=""

  # Stub
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo false
  }
  vedv::image_service::import() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::import_from_url() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_service::pull() {
    assert_equal "$*" "${image} ${image_name}"
    return 1
  }

  run vedv::image_service::import_from_any \
    "$image" \
    "$image_name"

  assert_failure
  assert_output "Error importing image from registry: ${image}"
}

@test "vedv::image_service::import_from_any() Should fail If image argument has invalid format" {
  local -r image='invalid_format'
  local -r image_name=""

  # Stub
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo false
  }
  vedv::image_service::import() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::import_from_url() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_service::pull() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::vmobj_entity::is_name() {
    assert_equal "$*" "$image"
    echo false
  }

  run vedv::image_service::import_from_any \
    "$image" \
    "$image_name"

  assert_failure
  assert_output "Invalid image argument format, it must be a image name, url, file or fully qualified name"
}

# Tests for vedv::image_service::__prepare_image_for_export()
@test "vedv::image_service::__prepare_image_for_export() Should fail If image_id is empty" {
  local -r image_id=""
  local -r no_change_password=""

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If no_change_password is empty" {
  local -r image_id=1234567890
  local -r no_change_password=""

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Argument 'no_change_password' is required"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If get_password fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Failed to get password for image: '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If ____clear_child_container_ids fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one, it's recommended
to change it to avoid a password leak.
Set CHANGE_PASSWORD_ON_IMPORT=false to mitigate this risk
Failed to clear child container ids for image: '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If set_image_cache fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one, it's recommended
to change it to avoid a password leak.
Set CHANGE_PASSWORD_ON_IMPORT=false to mitigate this risk
Error setting image_cache to the image '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If set_ova_file_sum fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} "
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one, it's recommended
to change it to avoid a password leak.
Set CHANGE_PASSWORD_ON_IMPORT=false to mitigate this risk
Error setting ova_file_sum to the image '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If set_ssh_port fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "${image_id} "
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one, it's recommended
to change it to avoid a password leak.
Set CHANGE_PASSWORD_ON_IMPORT=false to mitigate this risk
Error setting ssh_port to the image '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If set_vm_name fails" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "${image_id} "
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one, it's recommended
to change it to avoid a password leak.
Set CHANGE_PASSWORD_ON_IMPORT=false to mitigate this risk
Error setting vm_name to the image '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If change_users_password fails" {
  local -r image_id=1234567890
  local -r no_change_password=false

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "INVALID_CALL"
    return 1
  }
  vedv::vmobj_service::change_users_password() {
    assert_equal "$*" "image ${image_id} default_password"
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one,
changing it to avoid a password leak.
This adds around 15 to 35 seconds to the process
Error setting password for image: '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should fail If stop fails" {
  local -r image_id=1234567890
  local -r no_change_password=false

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "INVALID_CALL"
    return 1
  }
  vedv::vmobj_service::change_users_password() {
    assert_equal "$*" "image ${image_id} default_password"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_failure
  assert_output "Image has a password different from the default one,
changing it to avoid a password leak.
This adds around 15 to 35 seconds to the process
Failed to stop image: '1234567890'"
}

@test "vedv::image_service::__prepare_image_for_export() Should succeed With no_change_password=false" {
  local -r image_id=1234567890
  local -r no_change_password=false

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "gen_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "${image_id} "
  }
  vedv::vmobj_service::change_users_password() {
    assert_equal "$*" "image ${image_id} default_password"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "$image_id"
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_success
  assert_output "Image has a password different from the default one,
changing it to avoid a password leak.
This adds around 15 to 35 seconds to the process"
}

@test "vedv::image_service::__prepare_image_for_export() Should succeed equals passwords" {
  local -r image_id=1234567890
  local -r no_change_password=true

  vedv::vmobj_entity::get_password() {
    assert_equal "$*" "image ${image_id}"
    echo "default_password"
  }
  vedv::vmobj_entity::get_default_password() {
    echo "default_password"
  }
  vedv::image_entity::____clear_child_container_ids() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_entity::set_image_cache() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ova_file_sum() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_ssh_port() {
    assert_equal "$*" "${image_id} "
  }
  vedv::image_entity::set_vm_name() {
    assert_equal "$*" "${image_id} "
  }
  vedv::vmobj_service::change_users_password() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::image_service::__prepare_image_for_export \
    "$image_id" "$no_change_password"

  assert_success
  assert_output ""
}

# Tests for vedv::image_service::__delete_all_image_clones()
@test "vedv::image_service::__delete_all_image_clones() Should fail if list_vms_by_partial_name fails" {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"
    return 1
  }

  run vedv::image_service::__delete_all_image_clones

  assert_failure
  assert_output "Failed to list image clones"
}

@test "vedv::image_service::__delete_all_image_clones() Should succeed If there is no image clones" {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"
  }

  run vedv::image_service::__delete_all_image_clones

  assert_success
  assert_output ""
}

@test "vedv::image_service::__delete_all_image_clones() Should fail If get_image_name_by_vm_name fails" {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"

    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc|crc:1234567890|"
    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def|crc:1234567891|"
  }

  vedv::image_entity::get_image_name_by_vm_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc|crc:1234567890|"
    return 1
  }

  run vedv::image_service::__delete_all_image_clones

  assert_failure
  assert_output "Failed to get image name for vm 'image:img09f5-abc|crc:1234567890|'"
}

@test "vedv::image_service::__delete_all_image_clones() Should fail If hypervisor::rm fails" {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"

    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|"
    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def-124|crc:1234567891|"
  }

  vedv::image_entity::get_image_name_by_vm_name() {
    case "$*" in
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|") ;;
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def-124|crc:1234567891|") ;;
    *)
      return 1
      ;;
    esac
  }

  ps() {
    case "$*" in
    123) ;;
    124) ;;
    *)
      return 1
      ;;
    esac
  }

  vedv:hypervisor::rm() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|"
    return 1
  }

  run vedv::image_service::__delete_all_image_clones

  assert_failure
  assert_output "Failed to remove image clone: 'image:img09f5-abc-123|crc:1234567890|'"
}

@test "vedv::image_service::__delete_all_image_clones() Should succeed" {

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"

    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc|crc:1234567890|"
    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def|crc:1234567891|"
  }

  vedv::hypervisor::list_vms_by_partial_name() {
    assert_equal "$*" "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-"

    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|"
    echo "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def-124|crc:1234567891|"
  }

  vedv::image_entity::get_image_name_by_vm_name() {
    case "$*" in
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|") ;;
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def-124|crc:1234567891|") ;;
    *)
      return 1
      ;;
    esac
  }

  ps() {
    case "$*" in
    123) ;;
    124) ;;
    *)
      return 1
      ;;
    esac
  }

  vedv::hypervisor::rm() {
    case "$*" in
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-abc-123|crc:1234567890|") ;;
    "image:${__VEDV_IMAGE_SERVICE_IMAGE_CLONE_TAG}-def-124|crc:1234567891|") ;;
    *)
      return 1
      ;;
    esac
  }

  run vedv::image_service::__delete_all_image_clones

  assert_success
  assert_output ""
}
