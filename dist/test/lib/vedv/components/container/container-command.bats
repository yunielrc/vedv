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

# Tests for vedv::container_command::__create()
@test "vedv::container_command::__create(), with arg '-h|--help|help' should show help" {
  for flag in '-h' '--help'; do
    run vedv::container_command::__create "$flag"

    assert_success
    assert_output --partial "Usage:
vedv container create [FLAGS] [OPTIONS] IMAGE_NAME|URL|FILE|FQN

Create a new container"

  done
}

@test 'vedv::container_command::__create(), should create a container' {
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create "$image_file"

  assert_success
  assert_output --regexp 'container created, arguments: .*/alpine-x86_64.ova  false  false '
}

@test 'vedv::container_command::__create(), Should fail With empty name value' {
  local container_name='super-llama-testunit-container-command'
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create --name

  assert_failure
  assert_output --partial 'No container name specified'
}

@test 'vedv::container_command::__create(), with --name should create a container' {
  local container_name='super-llama-testunit-container-command'
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create --name "$container_name" "$image_file"

  assert_success
  assert_output --regexp 'container created, arguments: .*/alpine-x86_64.ova super-llama-testunit-container-command false  false '
}

@test 'vedv::container_command::__create(), Should fail With empty publish value' {
  local container_name='super-llama-testunit-container-command'
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create --name "$container_name" --publish

  assert_failure
  assert_output --partial 'No publish port specified'
}
# bats test_tags=only
@test 'vedv::container_command::__create(), Should succeed' {
  local container_name='super-llama-testunit-container-command'
  local image_file="$TEST_OVA_FILE"

  run vedv::container_command::__create --name "$container_name" -p 8080:80/tcp -p 8082:82 -p 8081 -p 81/udp --standalone --publish-all "$image_file"

  assert_success
  assert_output --regexp 'container created, arguments: .*/alpine-x86_64.ova super-llama-testunit-container-command true 8080:80/tcp 8082:82 8081 81/udp true '
}

@test "vedv::container_command::__create(), Should fail Without cpu value" {
  local -r container_id='container123'

  run vedv::container_command::__create --name "$container_id" --cpus

  assert_failure
  assert_output --partial "No cpus specified"
}

@test "vedv::container_command::__create(), Should fail Without memory value" {
  local -r container_id='container123'

  run vedv::container_command::__create \
    --name "$container_id" --cpus 4 --memory

  assert_failure
  assert_output --partial "No memory specified"
}

@test "vedv::container_command::__create(), Should succeed With cpu and memory values" {
  local -r container_id='container123'

  vedv::container_service::create() {
    assert_regex "$*" ".*/alpine-x86_64.ova container123 false  false 4 1024"
  }

  run vedv::container_command::__create \
    --name "$container_id" --cpus 4 --memory 1024 "$TEST_OVA_FILE"

  assert_success
  assert_output ""
}

# Tets for vedv::container_command::__start()
@test "vedv::container_command::__start(), with arg '-h|--help|help' should show help" {
  local -r help_output="Usage:
vedv container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help    show help
  -w, --wait    wait for SSH"

  run vedv::container_command::__start -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__start --help

  assert_success
  assert_output --partial "$help_output"
}

@test 'vedv::container_command::__start(), should start a container' {
  local -r container_name_or_id='container_name1 container_name2'

  run vedv::container_command::__start \
    --wait \
    --show \
    "$container_name_or_id"

  assert_success
  assert_output "${container_name_or_id} true true"
}

# Tests for vedv::container_command::__stop()
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

# Tests for vedv::container_command::__rm()
@test "vedv::container_command::__rm(), with arg '-h|--help|help' should show help" {
  local -r help_output="Usage:
vedv container rm [FLAGS] CONTAINER [CONTAINER...]

Remove one or more running containers

Aliases:
  rm, remove

Flags:
  -h, --help    show help
  --force       force remove"

  run vedv::container_command::__rm -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__rm --help

  assert_success
  assert_output "$help_output"
}

@test 'vedv::container_command::__rm(), should remove a container' {
  local -r container_name_or_id='container_name1 container_name2'

  run vedv::container_command::__rm "$container_name_or_id"

  assert_success
  assert_output "${container_name_or_id} false"
}

# Tests for vedv::container_command::__list()
@test "vedv::container_command::__list(), with arg '-h|--help|help' should show help" {
  local -r help_output="Usage:
vedv container ls [FLAGS] [CONTAINER PARTIAL NAME]

List containers

Aliases:
  ls, ps, list

Flags:
  -h, --help    show help
  -a, --all     show all containers (default shows just running)"

  run vedv::container_command::__list -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::container_command::__list --help

  assert_success
  assert_output --partial "$help_output"
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

# Tests for vedv::container_command::run_cmd()
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
vedv container login [FLAGS] [OPTIONS] CONTAINER

Login to a container

Aliases:
  login, connect

Flags:
  -h, --help          show help
  -r, --root          login as root

Options:
  -u, --user  <user>  login as user"
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
vedv container login [FLAGS] [OPTIONS] CONTAINER

Login to a container

Aliases:
  login, connect

Flags:
  -h, --help          show help
  -r, --root          login as root

Options:
  -u, --user  <user>  login as user"
  done
}

@test "vedv::container_command::__connect() Should login" {
  vedv::container_service::connect() {
    assert_equal "$*" 'container1 '
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
vedv container exec [FLAGS] [OPTIONS] CONTAINER COMMAND1 [COMMAND2] ...
vedv container exec [FLAGS] [OPTIONS] CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container

Flags:
  -h, --help            show help
  -r, --root            execute command as root user

Options:
  -u, --user    <user>  execute command as specific user
  -w, --workdir <dir>   working directory for command
  -e, --env     <env>   environment variable for command
  -s, --shell   <shell> shell to use for command"
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
vedv container exec [FLAGS] [OPTIONS] CONTAINER COMMAND1 [COMMAND2] ...
vedv container exec [FLAGS] [OPTIONS] CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container

Flags:
  -h, --help            show help
  -r, --root            execute command as root user

Options:
  -u, --user    <user>  execute command as specific user
  -w, --workdir <dir>   working directory for command
  -e, --env     <env>   environment variable for command
  -s, --shell   <shell> shell to use for command"
  done
}

@test "vedv::container_command::__execute_cmd() Should fail With empty user" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__execute_cmd --user
  # Assert
  assert_failure
  assert_output --partial "No user specified"
}

@test "vedv::container_command::__execute_cmd() Should fail With empty workdir" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__execute_cmd --user 'user1' --workdir
  # Assert
  assert_failure
  assert_output --partial "No workdir specified"
}

@test "vedv::container_command::__execute_cmd() Should fail With empty env" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__execute_cmd --user 'user1' --workdir 'workdir1' --env
  # Assert
  assert_failure
  assert_output --partial "No environment specified"
}

@test "vedv::container_command::__execute_cmd() Should succeed With root" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'container1 command1 root   '
  }
  # Act
  run vedv::container_command::__execute_cmd --root container1 'command1'
  # Assert
  assert_success
  assert_output ""
}

@test "vedv::container_command::__execute_cmd() Should fail with empty shell" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__execute_cmd --user 'user1' --workdir 'workdir1' --env E1=val1 --env E2=val2 --shell
  # Assert
  assert_failure
  assert_output --partial "No shell specified"
}

@test "vedv::container_command::__execute_cmd() Should succeed" {
  vedv::container_service::execute_cmd() {
    assert_equal "$*" 'container1 command1 user1 workdir1 E1=val1 E2=val2  bash'
  }
  # Act
  run vedv::container_command::__execute_cmd --user 'user1' --workdir 'workdir1' --shell 'bash' --env E1=val1 --env E2=val2 container1 'command1'
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::container_command::__copy()

@test "vedv::container_command::__copy() Should show help with no args" {
  vedv::container_service::copy() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__copy
  # Assert
  assert_success
  assert_output --partial "Usage:
vedv container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container"
}

@test "vedv::container_command::__copy() Should show help" {
  vedv::container_service::copy() {
    assert_equal "$*" 'INVALID_CALL'
  }

  for arg in '-h' '--help'; do
    # Act
    run vedv::container_command::__copy "$arg"
    # Assert
    assert_success
    assert_output --partial "Usage:
vedv container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container"
  done
}

@test "vedv::container_command::__copy() Should show error when user is missing" {
  vedv::container_service::copy() {
    assert_equal "$*" 'container1 local_src container_dest'
  }
  # Act
  run vedv::container_command::__copy --user
  # Assert
  assert_failure
  assert_output --partial "No user specified

Usage:
vedv container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container"
}

@test "vedv::container_command::__copy() Should show error when src is missing" {
  vedv::container_service::copy() {
    assert_equal "$*" 'container1 local_src container_dest'
  }
  # Act
  run vedv::container_command::__copy 'container1'
  # Assert
  assert_failure
  assert_output --partial "No source file specified

Usage:
vedv container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container"
}

@test "vedv::container_command::__copy() Should show error when dest is missing" {
  vedv::container_service::copy() {
    assert_equal "$*" 'container1 local_src container_dest'
  }
  # Act
  run vedv::container_command::__copy 'container1' 'local_src'
  # Assert
  assert_failure
  assert_output --partial "No dest file specified

Usage:
vedv container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container"
}

@test "vedv::container_command::__copy() Should show error when chown is missing" {
  # Arrange
  local container_name_or_id='container1'
  local user='vedv'
  local chown='nalyd'
  local chmod='644'
  local src='src1'
  local dest='dest1'

  vedv::container_service::copy() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__copy --user "$user" --chown
  # Assert
  assert_failure
  assert_output --partial "No chown value specified"
}

@test "vedv::container_command::__copy() Should show error when chmod is missing" {
  # Arrange
  local container_name_or_id='container1'
  local user='vedv'
  local chown='nalyd'
  local chmod='644'
  local src='src1'
  local dest='dest1'

  vedv::container_service::copy() {
    assert_equal "$*" 'INVALID_CALL'
  }
  # Act
  run vedv::container_command::__copy --user "$user" --chown "$chown" --chmod
  # Assert
  assert_failure
  assert_output --partial "No chmod value specified"
}

@test "vedv::container_command::__copy() Should show suceed" {
  # Arrange
  local container_name_or_id='container1'
  local user='vedv'
  local chown='nalyd'
  local chmod='644'
  local src='src1'
  local dest='dest1'

  vedv::container_service::copy() {
    assert_equal "$*" 'container1 src1 dest1 vedv nalyd 644'
  }
  # Act
  run vedv::container_command::__copy --user "$user" --chown "$chown" --chmod "$chmod" "$container_name_or_id" "$src" "$dest"
  # Assert
  assert_success
  assert_output ""
}

# Tests for vedv::container_command::__list_ports()

@test "vedv::container_command::__list_ports() Should show help with no args" {

  # Act
  run vedv::container_command::__list_ports
  # Assert
  assert_success
  assert_output --partial "Usage:
vedv container ports CONTAINER"
}

@test "vedv::container_command::__list_ports() Should show help" {

  for arg in '-h' '--help'; do
    # Act
    run vedv::container_command::__list_ports "$arg"
    # Assert
    assert_success
    assert_output --partial "Usage:
vedv container ports CONTAINER"
  done
}

@test "vedv::container_command::__list_ports() Should suceed" {
  # Arrange
  local container_name_or_id='container1'

  vedv::container_service::list_ports() {
    echo "$*"
  }
  # Act
  run vedv::container_command::__list_ports "$container_name_or_id"
  # Assert
  assert_success
  assert_output "container1"
}

# Tests for vedv::container_command::__list_exposed_ports()

@test "vedv::container_command::__list_exposed_ports() Should show help with no args" {

  # Act
  run vedv::container_command::__list_exposed_ports
  # Assert
  assert_success
  assert_output --partial "Usage:
vedv container list-exposed-ports CONTAINER"
}

@test "vedv::container_command::__list_exposed_ports() Should show help" {

  for arg in '-h' '--help'; do
    # Act
    run vedv::container_command::__list_exposed_ports "$arg"
    # Assert
    assert_success
    assert_output --partial "Usage:
vedv container list-exposed-ports CONTAINER"
  done
}

@test "vedv::container_command::__list_exposed_ports() Should suceed" {
  # Arrange
  local container_name_or_id='container1'

  vedv::container_service::cache::list_exposed_ports() {
    assert_equal "$*" 'container1'
  }
  # Act
  run vedv::container_command::__list_exposed_ports "$container_name_or_id"
  # Assert
  assert_success
  assert_output ""
}
