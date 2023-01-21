# shellcheck disable=SC2016
load test_helper

setup_file() {
  vedv::container_command::constructor 'vedv'
  export __VED_CONTAINER_COMMAND_SCRIPT_NAME
}

vedv::container_service::create() { echo "container created, arguments: $*"; }

@test "vedv::container_command::__create(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container create [OPTIONS] IMAGE'

  run vedv::container_command::__create -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__create --help

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__create help

  assert_success
  assert_output --partial "$help_output"

}

@test 'vedv::container_command::__create(), should create a container' {
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create "$image_file"

  assert_success
  assert_output 'container created, arguments: /tmp/vedv/test/files/alpine-x86_64.ova '
}

@test 'vedv::container_command::__create(), with --name should create a container' {
  local container_name='super-llama-testunit-container-command'
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create --name "$container_name" "$image_file"

  assert_success
  assert_output 'container created, arguments: /tmp/vedv/test/files/alpine-x86_64.ova super-llama-testunit-container-command'
}

@test "vedv::container_command::__create(), with invalid arg throw an error" {

  run vedv::container_command::__create 'image_file' 'invalid_arg'

  assert_failure 69
  assert_output --partial 'Invalid parameter: invalid_arg'
}