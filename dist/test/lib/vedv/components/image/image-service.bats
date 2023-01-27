# shellcheck disable=SC2016
load test_helper

setup_file() {
  vedv::image_service::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
}

teardown() {
  delete_vms_by_partial_vm_name "$VM_TAG"
  delete_vms_by_partial_vm_name 'image:alpine-x86_64|crc:87493131'
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
  echo "image:${image_name}-${VM_TAG}|crc:${crc_sum}"
}

@test 'vedv::image_service::_get_image_name(), should print image name' {
  local -r image_vm_name='image:lala-lolo|crc:1234567'

  run vedv::image_service::_get_image_name "$image_vm_name"

  assert_output 'lala-lolo'
}

@test 'vedv::image_service::_get_image_id(), should print image id' {
  local -r image_vm_name='image:lala-lolo|crc:1234567'

  run vedv::image_service::_get_image_id "$image_vm_name"

  assert_output '1234567'
}

@test "vedv::image_service::__gen_vm_name, with 'image_file' unset should throw an error" {
  run vedv::image_service::__gen_vm_name

  assert_failure 1
  assert_output --partial '$1: unbound variable'
}

@test "vedv::image_service::__gen_vm_name, should write the generated vm name" {
  local -r image_file="$TEST_OVA_FILE"

  run vedv::image_service::__gen_vm_name "$image_file"

  assert_success
  assert_output 'image:alpine-x86_64|crc:87493131'
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

@test "vedv::image_service::__pull_from_file, should pull" {
  local -r image_file="$TEST_OVA_FILE"

  run vedv::image_service::__pull_from_file "$image_file"

  assert_success
  assert_output "alpine-x86_64"
}

@test "vedv::image_service::__pull_from_file, if already imported shouldn't import it" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::image_service::__pull_from_file "$image_file"
  run vedv::image_service::__pull_from_file "$image_file"

  assert_success
  assert_output "alpine-x86_64"
}

@test "vedv::image_service::list(), Should show anything" {

  run vedv::image_service::list

  assert_success
  assert_output ''
}

@test "vedv::image_service::list(), With 'list_all=false' Should show all images vms" {
  local -r image_name1='im1'
  local -r image_name2="im2"

  create_image_vm "$image_name1"
  create_image_vm "$image_name2"

  run vedv::image_service::list

  assert_success
  assert_output --regexp "^[0-9]+\s+${image_name1}-${VM_TAG}\$
^[0-9]+\s+${image_name2}-${VM_TAG}\$"
}

@test 'vedv::image_service::rm(), Without params Should throw an error' {
  run vedv::image_service::rm

  assert_failure 69
  assert_output 'At least one image is required'
}

@test 'vedv::image_service::rm(), With 2 non-existent images Should throw an error' {
  run vedv::image_service::rm '3582343034' '3582343035'

  assert_failure 82
  assert_output --partial 'No such images: 3582343034 3582343035 '
}

@test 'vedv::image_service::rm(), if image has containers Should throw an error' {
  local -r vm_name='3582343034'

  eval "vedv::${TEST_HYPERVISOR}::list_wms_by_partial_name() { echo 'container:dyli|crc:1234567'; }"

  eval "vedv::${TEST_HYPERVISOR}::show_snapshots() {
    cat <<EOF
container:awake-bison|crc:933558977
container:dyli-amoroso|crc:833558977
EOF
}"
  run vedv::image_service::rm "$vm_name"

  assert_failure 82
  assert_output --partial "Failed to remove image 3582343034 because it has containers, remove them first: awake-bison dyli-amoroso"
}

@test 'vedv::image_service::rm(), if hypervisor fail Should throw an error' {
  eval "vedv::${TEST_HYPERVISOR}::list_wms_by_partial_name() { echo 'container:dyli|crc:1234567'; }"
  eval "vedv::${TEST_HYPERVISOR}::show_snapshots() { return 0; }"
  eval "vedv::${TEST_HYPERVISOR}::rm() { return 1; }"

  run vedv::image_service::rm '3582343034' '3582343035'

  assert_failure 82
  assert_output --partial 'Failed to remove images: 3582343034 3582343035 '
}

# bats test_tags=only
@test 'vedv::image_service::rm(), Should remove images' {
  eval "vedv::${TEST_HYPERVISOR}::list_wms_by_partial_name() { echo 'container:dyli|crc:1234567'; }"
  eval "vedv::${TEST_HYPERVISOR}::show_snapshots() { return 0; }"
  eval "vedv::${TEST_HYPERVISOR}::rm() { return 0; }"

  run vedv::image_service::rm '3582343034' '3582343035'

  assert_success
  assert_output '3582343034 3582343035 '
}
