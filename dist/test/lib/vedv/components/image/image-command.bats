# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  vedv::image_command::constructor 'vedv'
  export __VED_IMAGE_COMMAND_SCRIPT_NAME
}

# teardown(){
#   delete_vms_by_id_tag 'image:alpine-x86_64|sha1:38ddd2a7ecc6cde46fcaca611f054c518150383f'
# }

vedv::image_service::list() {
  echo "vedv::image_service::list $*"
}
vedv::image_service::remove() {
  echo "vedv::image_service::__rm $*"
}

@test "vedv::image_command::constructor() should succeed" {
  :
}

# Tests for vedv::image_command::__pull()
@test "vedv::image_command::__pull(), should pull an image" {

  vedv::registry_command::__pull() {
    assert_equal "$*" 'image_file'
  }

  run vedv::image_command::__pull 'image_file'

  assert_success
  assert_output ''
}

# Tests for vedv::image_command::__list()
@test "vedv::image_command::__list(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image ls'

  run vedv::image_command::__list -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::__list --help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::image_command::__list(), with invalid arg throw an error" {

  run vedv::image_command::__list 'invalid_arg'

  assert_failure 69
  assert_output --partial 'Invalid parameter: invalid_arg'
}

@test 'vedv::image_command::__list(), should show the images' {
  run vedv::image_command::__list

  assert_success
  assert_output --partial "vedv::image_service::list"
}

# Tests for vedv::image_command::__rm()
@test "vedv::image_command::__rm(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image rm [FLAGS] IMAGE [IMAGE...]'

  run vedv::image_command::__rm -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::__rm --help

  assert_success
  assert_output --partial "$help_output"
}

@test 'vedv::image_command::__rm(), should remove the images' {
  local -r image_name_or_id='container_name1 container_name2'

  run vedv::image_command::__rm "$image_name_or_id"

  assert_success
  assert_output "vedv::image_service::__rm ${image_name_or_id} false"
}

# Tests for vedv::image_command::run_cmd()
@test "vedv::image_command::run_cmd, with invalid arg throw an error" {
  run vedv::image_command::run_cmd invalid_cmd

  assert_failure 69
  assert_output --partial 'Invalid parameter: invalid_cmd'
}

@test "vedv::image_command::run_cmd, with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image COMMAND'

  run vedv::image_command::run_cmd -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::run_cmd --help

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::run_cmd help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::image_command::run_cmd, with arg 'pull' should pull an image" {
  vedv::image_command::__pull() { echo "pull image: ${1}"; }

  run vedv::image_command::run_cmd pull image_file

  assert_success
  assert_output 'pull image: image_file'
}

@test "vedv::image_command::run_cmd, with arg 'build' should build an image" {
  vedv::image_command::__build() { echo "build image: ${1}"; }

  run vedv::image_command::run_cmd build image_file

  assert_success
  assert_output 'build image: image_file'
}

# Tests for vedv::image_command::__build()

@test "vedv::image_command::__build_help()" {
  :
}

# Tests for vedv::image_command::__list_exposed_ports()

@test "vedv::image_command::__list_exposed_ports() Should show help with no args" {

  # Act
  run vedv::image_command::__list_exposed_ports
  # Assert
  assert_success
  assert_output --partial "Usage:
vedv image list-exposed-ports IMAGE"
}

@test "vedv::image_command::__list_exposed_ports() Should show help" {

  for arg in '-h' '--help'; do
    # Act
    run vedv::image_command::__list_exposed_ports "$arg"
    # Assert
    assert_success
    assert_output --partial "Usage:
vedv image list-exposed-ports IMAGE"
  done
}

@test "vedv::image_command::__list_exposed_ports() Should suceed" {
  # Arrange
  local image_name_or_id='image1'

  vedv::image_service::cache::list_exposed_ports() {
    assert_equal "$*" 'image1'
  }
  # Act
  run vedv::image_command::__list_exposed_ports "$image_name_or_id"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::image_command::__import()

@test "vedv::image_command::__import() Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv::image_command::__import $flag

    assert_success
    assert_output --partial "Usage:
vedv image import [FLAGS] [OPTIONS] IMAGE_FILE.ova"
  done
}

@test "vedv::image_command::__import() Should fail if missing image name" {

  run vedv::image_command::__import --name

  assert_failure
  assert_output --partial 'No image name specified'
}

@test "vedv::image_command::__import() Should check the image file without argument value" {
  vedv::image_service::import() {
    assert_equal "$*" "${TEST_OVA_FILE} image123 ${TEST_OVA_FILE}.sha256sum"
    echo 'image123'
  }

  run vedv::image_command::__import --check --name image123 "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}

@test "vedv::image_command::__import() Should fail if check file argument is missing" {
  vedv::image_service::import() {
    assert_equal "$*" "${TEST_OVA_FILE} image123 ${TEST_OVA_FILE}.sha256sum"
    echo 'image123'
  }

  run vedv::image_command::__import --check-file

  assert_failure
  assert_output --partial 'No checksum file specified'
}

@test "vedv::image_command::__import() Should check the image file" {
  vedv::image_service::import() {
    assert_equal "$*" "${TEST_OVA_FILE} image123 ${TEST_OVA_FILE}.sha256sum"
    echo 'image123'
  }

  run vedv::image_command::__import --check-file "${TEST_OVA_FILE}.sha256sum" --name image123 "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}

@test "vedv::image_command::__import() Should succeed" {

  vedv::image_service::import() {
    assert_equal "$*" "${TEST_OVA_FILE} image123 "
    echo 'image123'
  }

  run vedv::image_command::__import -n 'image123' "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}

# Tests for vedv::image_command::__import_from_url()
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv::image_command::__import_from_url $flag

    assert_success
    assert_output --partial "Usage:
vedv image from-url [FLAGS] [OPTIONS] URL"
  done
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should fail if missing image name" {

  run vedv::image_command::__import_from_url --name

  assert_failure
  assert_output --partial 'No image name specified'
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should fail if missing sum url" {

  run vedv::image_command::__import_from_url \
    --check \
    --checksum-url

  assert_failure
  assert_output --partial 'No checksum url specified'
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should fail if missing image url" {

  run vedv::image_command::__import_from_url \
    --check \
    --checksum-url 'http://example.com'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_URL'"
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should succeed with all args" {
  vedv::image_service::import_from_url() {
    assert_equal "$*" "http://files.get/image image123 http://files.get/sum"
  }

  run vedv::image_command::__import_from_url \
    --name image123 \
    --checksum-url 'http://files.get/sum' \
    'http://files.get/image'

  assert_success
  assert_output ""
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should succeed with check" {
  vedv::image_service::import_from_url() {
    assert_equal "$*" "http://files.get/image image123 http://files.get/image.sha256sum"
  }

  run vedv::image_command::__import_from_url \
    --name image123 \
    --check \
    'http://files.get/image'

  assert_success
  assert_output ""
}
# bats test_tags=only
@test "vedv::image_command::__import_from_url() Should succeed with name" {
  vedv::image_service::import_from_url() {
    assert_equal "$*" "http://files.get/image image123 "
  }

  run vedv::image_command::__import_from_url \
    --name image123 \
    'http://files.get/image'

  assert_success
  assert_output ""
}

# Tests for vedv::image_command::__export()
@test "vedv::image_command::__export() Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv::image_command::__export $flag

    assert_success
    assert_output --partial "Usage:
vedv image export [FLAGS] [OPTIONS] IMAGE FILE.ova"
  done
}

@test "vedv::image_command::__export() Should fail if missing image name or id" {

  run vedv::image_command::__export --no-checksum

  assert_failure
  assert_output --partial "Missing argument 'IMAGE'"
}

@test "vedv::image_command::__export() Should fail if missing FILE" {

  run vedv::image_command::__export --no-checksum image123

  assert_failure
  assert_output --partial "Missing argument 'FILE'"
}

@test "vedv::image_command::__export() Should succeed With no-checksum" {

  vedv::image_service::export() {
    assert_equal "$*" "image123 ${TEST_IMAGE_TMP_DIR}/image123.ova true "
  }

  run vedv::image_command::__export --no-checksum image123 "${TEST_IMAGE_TMP_DIR}/image123.ova"

  assert_success
  assert_output ""
}

@test "vedv::image_command::__export() Should succeed With checksum" {

  vedv::image_service::export() {
    assert_equal "$*" "image123 ${TEST_IMAGE_TMP_DIR}/image123.ova false "
  }

  run vedv::image_command::__export image123 \
    "${TEST_IMAGE_TMP_DIR}/image123.ova"

  assert_success
  assert_output ""
}

@test "vedv::image_command::__export() Should succeed With no_change_password" {

  vedv::image_service::export() {
    assert_equal "$*" "image123 ${TEST_IMAGE_TMP_DIR}/image123.ova false true"
  }

  run vedv::image_command::__export --no-change-password image123 \
    "${TEST_IMAGE_TMP_DIR}/image123.ova"

  assert_success
  assert_output ""
}

# Tests for vedv::image_command::__push()
@test "vedv::image_command::__push() Should succeed" {

  vedv::registry_command::__push() { :; }

  run vedv::image_command::__push

  assert_success
  assert_output ''
}

# Tests for vedv::image_command::__push_link()
@test "vedv::image_command::__push_link() Should succeed" {

  vedv::registry_command::__push_link() { :; }

  run vedv::image_command::__push_link

  assert_success
  assert_output ''
}
