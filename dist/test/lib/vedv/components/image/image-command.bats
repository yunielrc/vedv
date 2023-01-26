# shellcheck disable=SC2016
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

@test "vedv::image_command::__pull, with invalid arg throw an error" {
  run vedv::image_command::__pull 'image_file' 'invalid_arg'

  assert_failure 69
  assert_output --partial 'Invalid parameter: invalid_arg'
}

@test "vedv::image_command::__pull, with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image pull IMAGE'

  run vedv::image_command::__pull -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::__pull --help

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::__pull help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::image_command::__pull, should pull an image" {

  vedv::image_service::pull() { echo "image pulled ${1}"; }

  run vedv::image_command::__pull 'image_file'

  assert_success
  assert_output 'image pulled image_file'
}

@test "vedv::image_command::__list(), with arg '-h|--help|help' should show help" {
  local -r help_output='docker image ls [OPTIONS] [IMAGE PARTIAL NAME]'

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
