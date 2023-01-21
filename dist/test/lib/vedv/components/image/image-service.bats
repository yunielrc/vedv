# shellcheck disable=SC2016
load test_helper

setup_file() {
  readonly __VEDV_IMAGE_SERVICE_HYPERVISOR='virtualbox'
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
}

teardown() {
  delete_vms_by_id_tag 'image:alpine-x86_64|sha1:38ddd2a7ecc6cde46fcaca611f054c518150383f'
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
  assert_output "image:alpine-x86_64|crc:87493131"
}

@test "vedv::image_service::__pull_from_file, if already imported shouldn't import it" {
  local -r image_file="$TEST_OVA_FILE"

  vedv::image_service::__pull_from_file "$image_file"
  run vedv::image_service::__pull_from_file "$image_file"

  assert_success
  assert_output "image:alpine-x86_64|crc:87493131"
}
