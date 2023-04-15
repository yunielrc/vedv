# shellcheck disable=SC2317
load test_helper

setup_file() {
  delete_vms_directory
  VM_NAME_SSH="$(create_vm)"
  readonly VM_NAME_SSH
  export VM_NAME_SSH
  start_vm_wait_ssh "$VM_NAME_SSH"
}

teardown_file() {
  delete_vms_by_partial_vm_name "$VM_NAME_SSH"
}

@test "vedv::ssh_client::run_cmd() Should fail With empty 'user'" {
  local user=""
  local ip="127.0.0.1"
  local password="test_password"
  local cmd="echo 'test_output'"
  local port=22

  run vedv::ssh_client::run_cmd "$user" "$ip" "$password" "$cmd" "$port"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'user' must not be empty"
}

@test "vedv::ssh_client::run_cmd() Should fail With invalid 'ip'" {
  local user="test_user"
  local ip="invalid_ip"
  local password="test_password"
  local cmd="echo 'test_output'"
  local port=22

  run vedv::ssh_client::run_cmd "$user" "$ip" "$password" "$cmd" "$port"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid Argument 'ip': 'invalid_ip'"
}

@test "vedv::ssh_client::run_cmd() Should fail With empty password" {
  local user="test_user"
  local ip="127.0.0.1"
  local password=""
  local cmd="echo 'test_output'"
  local port=22

  run vedv::ssh_client::run_cmd "$user" "$ip" "$password" "$cmd" "$port"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'password' must not be empty"
}

@test "vedv::ssh_client::run_cmd() Should fail With 'port' out of range 0-65535" {
  local user="test_user"
  local ip="127.0.0.1"
  local password="test_password"
  local cmd="echo 'test_output'"
  local port=65536

  run vedv::ssh_client::run_cmd "$user" "$ip" "$password" "$cmd" "$port"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'port' must be a value between 0-65535"
}

@test "vedv::ssh_client::run_cmd() Should success With valid arguments" {
  local user="$TEST_SSH_USER"
  local ip="$TEST_SSH_IP"
  local password="$TEST_SSH_USER"
  local cmd="echo 'test_output'"
  local port="$TEST_SSH_PORT"

  run vedv::ssh_client::run_cmd "$user" "$ip" "$password" "$cmd" "$port"

  assert_success
  # assert_output ''
}

@test "vedv::ssh_client::wait_for_ssh_service() Should fail With invalid IP argument" {
  utils::valid_ip() { false; }
  run vedv::ssh_client::wait_for_ssh_service "not_an_ip" 22

  assert_failure
  assert_output "Invalid Argument 'ip': 'not_an_ip'"
}

@test "vedv::ssh_client::wait_for_ssh_service() Should fail With invalid port argument" {
  utils::valid_ip() { :; }
  utils::validate_port() { false; }

  run vedv::ssh_client::wait_for_ssh_service "127.0.0.1" 70000

  assert_failure
  assert_output "Argument 'port' must be a value between 0-65535"
}

@test "vedv::ssh_client::wait_for_ssh_service() Should fail With invalid timeout argument" {
  utils::valid_ip() { :; }
  utils::validate_port() { :; }

  run vedv::ssh_client::wait_for_ssh_service "127.0.0.1" 22 0

  assert_failure
  assert_output "Argument 'timeout' must be a value between 1-60"
}

@test "vedv::ssh_client::wait_for_ssh_service() Should fail When timeout is reached" {
  run vedv::ssh_client::wait_for_ssh_service "$TEST_SSH_IP" 23 1

  assert_failure
  assert_output "Timeout waiting for ssh service on '127.0.0.1'"
}

@test "vedv::ssh_client::wait_for_ssh_service() Should success When ssh service is available" {
  run vedv::ssh_client::wait_for_ssh_service "$TEST_SSH_IP" "$TEST_SSH_PORT" "$TEST_SSH_WAIT_TIMEOUT"

  assert_success
  assert_output ""
}
@test "vedv::ssh_client::copy(), Should fail With invalid 'user' argument" {
  run vedv::ssh_client::copy "" "192.168.0.1" "password" "22" "source/file" "dest/file"
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'user' must not be empty"
}

@test "vedv::ssh_client::copy(), Should fail With invalid 'ip' argument" {
  run vedv::ssh_client::copy "user" "invalid_ip" "password" "22" "source/file" "dest/file"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid Argument 'ip': 'invalid_ip'"
}

@test "vedv::ssh_client::copy(), Should fail With invalid 'password' argument" {
  run vedv::ssh_client::copy "user" "192.168.0.1" "" "22" "source/file" "dest/file"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'password' must not be empty"
}

@test "vedv::ssh_client::copy(), Should fail With invalid 'port' argument" {
  run vedv::ssh_client::copy "user" "192.168.0.1" "password" "65536" "source/file" "dest/file"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'port' must be a value between 0-65535"
}

@test "vedv::ssh_client::copy(), Should fail With invalid 'source' argument" {
  run vedv::ssh_client::copy "user" "192.168.0.1" "password" "22" "" "dest/file"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'source' must not be empty"
}

@test "vedv::ssh_client::copy(), Should fail With invalid 'dest' argument" {
  run vedv::ssh_client::copy "user" "192.168.0.1" "password" "22" "source/file" ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'dest' must not be empty"
}

@test "vedv::ssh_client::copy(), Should fail With failed 'scp' command" {
  run vedv::ssh_client::copy "user" "192.168.0.1" "password" "22" "source/file" "dest/file"

  assert_failure "$ERR_SSH_OPERATION"
  assert_output --partial "Error on 'user@192.168.0.1', rsync exit code:"
}

# bats test_tags=only
@test "vedv::ssh_client::copy(), Should success With valid arguments" {
  local -r user="$TEST_SSH_USER"
  local -r ip="$TEST_SSH_IP"
  local -r password="$TEST_SSH_USER"
  local -r port="$TEST_SSH_PORT"
  local -r source="$(mktemp)"
  # shellcheck disable=SC2088
  local -r dest="~/file_with_content"

  echo "line1" >"$source"

  run vedv::ssh_client::copy "$user" "$ip" "$password" "$port" "$source" "$dest"

  assert_success
  assert_output ""

  run ssh_run_cmd grep "line1" "$dest"

  assert_success
  assert_output "line1"
}
