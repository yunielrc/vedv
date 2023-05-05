# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  vedv::container_command::constructor 'vedv'
  export __VED_CONTAINER_COMMAND_SCRIPT_NAME
}

vedv::container_service::create() { echo "container created, arguments: $*"; }
vedv::container_service::start() { echo "$@"; }
vedv::container_service::start_no_wait_ssh() { echo "$@"; }
vedv::container_service::stop() { echo "$@"; }
vedv::container_service::remove() { echo "$@"; }
vedv::container_service::list() { echo "include stopped containers: ${1:-false}"; }

@test "vedv::container_command::__create(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container create [OPTIONS] IMAGE'

  run vedv::container_command::__create -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__create --help

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
  assert_output --partial "Invalid argument 'invalid_arg'"
}

@test "vedv::container_command::__start(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container start CONTAINER [CONTAINER...]'

  run vedv::container_command::__start -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__start --help

  assert_success
  assert_output --partial "$help_output"
}

@test 'vedv::container_command::__start(), should start a container' {
  local -r container_name_or_id='container_name1 container_name2'

  run vedv::container_command::__start "$container_name_or_id"

  assert_success
  assert_output "${container_name_or_id}"
}

@test "vedv::container_command::__stop(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container stop CONTAINER [CONTAINER...]'

  run vedv::container_command::__stop -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__stop --help

  assert_success
  assert_output --partial "$help_output"
}

@test 'vedv::container_command::__stop(), should stop a container' {
  local -r container_name_or_id='container_name1 container_name2'

  run vedv::container_command::__stop "$container_name_or_id"

  assert_success
  assert_output "${container_name_or_id}"
}

@test "vedv::container_command::__rm(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container rm CONTAINER [CONTAINER...]'

  run vedv::container_command::__rm -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__rm --help

  assert_success
  assert_output --partial "$help_output"
}

@test 'vedv::container_command::__rm(), should remove a container' {
  local -r container_name_or_id='container_name1 container_name2'

  run vedv::container_command::__rm "$container_name_or_id"

  assert_success
  assert_output "false ${container_name_or_id}"
}

@test "vedv::container_command::__list(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv docker container ls [OPTIONS]'

  run vedv::container_command::__list -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__list --help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::container_command::__list(), with invalid arg throw an error" {

  run vedv::container_command::__list 'partial_name' 'invalid_arg'

  assert_failure 69
  assert_output --partial 'Invalid argument: invalid_arg'
}

@test 'vedv::container_command::__list(), should show the running containers' {
  run vedv::container_command::__list

  assert_success
  assert_output "include stopped containers: false"
}

@test 'vedv::container_command::__list(), should show all containers' {
  run vedv::container_command::__list --all

  assert_success
  assert_output "include stopped containers: true"
}

@test "vedv::container_command::run_cmd(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv container COMMAND'

  run vedv::container_command::run_cmd -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::run_cmd --help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::container_command::run_cmd(), with arg 'create' should create a container" {
  vedv::container_command::__create() { echo "container created, arguments: $*"; }

  run vedv::container_command::run_cmd create container_name

  assert_success
  assert_output 'container created, arguments: container_name'
}

@test "vedv::container_command::run_cmd(), with arg 'start' should start a container" {
  vedv::container_command::__start() { echo "container started, arguments: $*"; }

  run vedv::container_command::run_cmd start container_name

  assert_success
  assert_output 'container started, arguments: container_name'
}

@test "vedv::container_command::run_cmd(), with arg 'stop' should stop a container" {
  vedv::container_command::__stop() { echo "container stopped, arguments: $*"; }

  run vedv::container_command::run_cmd stop container_name

  assert_success
  assert_output 'container stopped, arguments: container_name'
}

@test "vedv::container_command::run_cmd(), with arg 'rm' should remove a container" {
  vedv::container_command::__rm() { echo "container removed, arguments: $*"; }

  run vedv::container_command::run_cmd rm container_name

  assert_success
  assert_output 'container removed, arguments: container_name'
}

@test "vedv::container_command::run_cmd(), with invalid parameter should throw an error" {
  run vedv::container_command::run_cmd invalid_cmd

  assert_failure 69
  assert_output --partial 'Invalid argument: invalid_cmd'
}

# Tests for vedv::container_command::__connect()
@test "vedv::container_command::__connect() Should show help with no args" {
  vedv::container_service::connect() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__connect
  # Assert
  assert_success
  assert_output "Usage:
vedv container login|connect CONTAINER

Login to a container"
}

@test "vedv::container_command::__connect() Should show help" {
  vedv::container_service::connect() {
    assert_equal "$*" 'INVALID_CALL'
  }

  for arg in '-h' '--help'; do
    # Act
    run vedv::container_command::__connect "$arg"
    # Assert
    assert_success
    assert_output "Usage:
vedv container login|connect CONTAINER

Login to a container"
  done
}

@test "vedv::container_command::__connect() Should login" {
  vedv::container_service::connect() {
    assert_equal "$*" 'container1'
  }
  # Act
  run vedv::container_command::__connect 'container1'
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::container_command::__execute_cmd()
@test "vedv::container_command::__execute_cmd() Should show help with no args" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__execute_cmd
  # Assert
  assert_success
  assert_output "Usage:
vedv container exec CONTAINER COMMAND1 [COMMAND2] ...
vedv container exec CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container"
}

@test "vedv::container_command::__execute_cmd() Should show help" {
  vedv::container_service::connect() {
    assert_equal "$*" 'INVALID_CALL'
  }

  for arg in '-h' '--help'; do
    # Act
    run vedv::container_command::__execute_cmd "$arg"
    # Assert
    assert_success
    assert_output "Usage:
vedv container exec CONTAINER COMMAND1 [COMMAND2] ...
vedv container exec CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container"
  done
}

@test "vedv::container_command::__execute_cmd() Should run command" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'container1 command1'
  }
  # Act
  run vedv::container_command::__execute_cmd 'container1' 'command1'
  # Assert
  assert_success
  assert_output ""
}
