# shellcheck disable=SC2317,SC2034,SC2031,SC2030,SC2016
load test_helper

setup() {
  vedv::builder_service::constructor "$(mktemp -d)" 'false'
  export __VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR
  export __VEDV_BUILDER_SERVICE_NO_WAIT_AFTER_BUILD
  export __VEDV_BUILDER_SERVICE_ENV_VARS_FILE
}

# setup() {
#   export __VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR="$(mktemp -d)"
# }

@test 'vedv::builder_service::constructor() Should succeed' {
  :
}

vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
  echo "$TEST_BASE_VEDVFILEIGNORE"
}

vedv:builder_vedvfile_service::get_base_vedvfileignore_path() {
  echo "$TEST_BASE_VEDVFILEIGNORE"
}

vedv:builder_vedvfile_service::get_vedvfileignore_path() {
  echo "$TEST_VEDVFILEIGNORE"
}

# Tests for vedv::builder_service::__create_layer()
@test "vedv::builder_service::__create_layer(): Should fail With missing 'image_id' argument" {
  run vedv::builder_service::__create_layer "" ""

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__create_layer(): Should fail With missing 'cmd' argument" {
  local -r image_id="123"

  run vedv::builder_service::__create_layer "$image_id" ""

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__create_layer(): Should fail If it can't get 'cmd_name' from 'cmd'" {
  local -r image_id="123"
  local -r cmd="1"

  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::builder_service::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::builder_service::__create_layer(): Should fail If fail to get layer id" {
  local -r image_id="123"
  local -r cmd="1 RUN echo hello"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    return 1
  }
  run vedv::builder_service::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to calculate layer id for cmd: '$cmd'"
}

@test "vedv::builder_service::__create_layer(), Should fail If fail to create_layer" {
  local -r image_id="image_id"
  local -r cmd="1 RUN echo hello"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo "layer_id"
    return 0
  }
  vedv::image_service::create_layer() {
    assert_equal "$*" "${image_id} RUN layer_id"
    return 1
  }
  # run the tested function
  run vedv::builder_service::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to create layer 'RUN' for image 'image_id'"
}

@test "vedv::builder_service::__create_layer(), Should success" {
  local -r image_id="image_id"
  local -r cmd="1 RUN echo hello"

  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo "layer_id"
    return 0
  }
  vedv::image_service::create_layer() {
    assert_equal "$*" "${image_id} RUN layer_id"
  }

  run vedv::builder_service::__create_layer "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Test for vedv::builder_service::__calc_command_layer_id()

@test "vedv::builder_service::__calc_command_layer_id() Should fails if cmd is empty" {
  local -r cmd=""

  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__calc_command_layer_id() Should fails if get_arg_from_string fails" {
  local -r cmd="1 RUN echo hello"

  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::builder_service::__calc_command_layer_id() Should fails if cmd name is empty" {
  local -r cmd="1 RUN echo hello"

  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
  }
  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "'cmd_name' must not be empty"
}

@test "vedv::builder_service::__calc_command_layer_id() Should fails If __layer_run_calc_id fails" {
  local -r cmd="1 RUN echo hello"

  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Failed to calculate layer id for cmd: '$cmd'"
}

@test "vedv::builder_service::__calc_command_layer_id() Should fails If calc_layer_id is empty" {
  local -r cmd="1 RUN echo hello"

  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
  }

  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "'calc_layer_id' must not be empty"
}

@test "vedv::builder_service::__calc_command_layer_id() Should success" {
  local -r cmd="1 RUN echo hello"

  vedv::builder_service::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo 'layer_id'
  }

  run vedv::builder_service::__calc_command_layer_id "$cmd"

  assert_success
  assert_output 'layer_id'
}

# Tests for vedv::builder_service::__layer_execute_cmd()
@test "vedv::builder_service::__layer_execute_cmd(), Should fail With invalid 'image_id' parameter" {
  local -r image_id=""
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With invalid 'cmd' parameter" {
  local -r image_id="dummy_id"
  local -r cmd=""
  local -r caller_command='COPY'
  local -r exec_func=':'

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With invalid 'caller_command' parameter" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command=''
  local -r exec_func=':'

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'caller_command' is required"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With invalid 'exec_func' parameter" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=''

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'exec_func' is required"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail If get_cmd_name fail" {
  # Arrange
  local -r image_id="dummy_id"
  local -r cmd="1 RUN dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'
  # Stub
  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # Act
  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With command not equal to 'COPY'" {
  local -r image_id="dummy_id"
  local -r cmd="1 RUN dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid command name 'RUN', it must be 'COPY'"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With 'exec_func' failure" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=false

  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::builder_service::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    echo "layer_id"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "$image_id"
  }

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to execute command '${cmd}'
Previous layer restored"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail If restore_last_layer fail" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=false
  # Stub
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure
  assert_output "Failed to execute command '1 COPY dummy_source dummy_dest'
Failed to restore last layer for image 'dummy_id'"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should fail With __create_layer failure" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=true
  # Stub
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to create layer for image '${image_id}'
Previous layer restored"
}

@test "vedv::builder_service::__layer_execute_cmd(), Should succeed" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'

  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    echo "layer_id"
  }

  run vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_success
  assert_output "layer_id"
}

# Tests for vedv::builder_service::__layer_from()
@test "vedv::builder_service::__layer_from() Should fail With empty 'image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_from "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_from() Should fail With empty 'cmd'" {
  local -r image_id="1234567890"
  local -r cmd=""

  run vedv::builder_service::__layer_from "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test 'vedv::builder_service::__layer_from() Should fail If cmd has $' {
  local -r image_id="1234567890"
  local -r cmd="RUN ls ${UTILS_ENCODED_ESCVAR_PREFIX}name"

  run vedv::builder_service::__layer_from "$image_id" "$cmd"

  assert_failure
  assert_output 'Invalid command, it must not contain: \$ or $'
}

@test 'vedv::builder_service::__layer_from() Should fail If __create_layer fails' {
  local -r image_id="1234567890"
  local -r cmd="RUN ls"

  vedv::builder_service::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    return 1
  }

  run vedv::builder_service::__layer_from "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to create layer for image '1234567890'"
}

@test 'vedv::builder_service::__layer_from() Should success' {
  local -r image_id="1234567890"
  local -r cmd="RUN ls"

  vedv::builder_service::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
  }

  run vedv::builder_service::__layer_from "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_copy_calc_id()

@test "vedv::builder_service::__layer_copy_calc_id() should return error if cmd is empty" {
  # arrange
  local -r cmd=""
  # act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # assert
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_copy_calc_id(), Should If getting cmd_name fails" {
  # arrange
  local -r cmd="1 RUN source/ dest/"
  # mocks
  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # assert
  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::builder_service::__layer_copy_calc_id(), Should return error if cmd name is not 'COPY'" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # Assert
  assert_failure
  assert_output "Invalid command name 'RUN', it must be 'COPY'"
}

@test "vedv::builder_service::__layer_copy_calc_id(), Should fail If _source is empty" {
  # Arrange
  local -r cmd="1 COPY --root "
  # Stub
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      assert_equal "$(cat -)" "$cmd"
    else
      assert_equal "$*" "$cmd"
    fi
    echo "1234"
  }
  # Act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # Assert
  assert_failure
  assert_output "Invalid number of arguments, expected at least 4, got 3"
}

@test "vedv::builder_service::__layer_copy_calc_id() Should fail If get_joined_vedvfileignore fails" {
  # Arrange
  local -r src="$(mktemp)"
  local -r cmd="1 COPY --root ${src} dest/"
  # Stub
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      assert_equal "$(cat -)" "$cmd"
    else
      assert_equal "$*" "$cmd"
    fi
    echo "1234"
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() {
    return 1
  }
  # Act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # Assert
  assert_failure
  assert_output "Failed to get joined vedvfileignore"
}

@test "vedv::builder_service::__layer_copy_calc_id(), Should write copy layer id to stdout" {
  # Arrange
  local -r src="$(mktemp)"
  local -r cmd="1 COPY ${src} dest/"
  # Stub
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      cat -
    else
      echo "$*"
    fi
  }
  vedv:builder_vedvfile_service::get_joined_vedvfileignore() { :; }
  utils::crc_file_sum() { crc_sum "$@"; }
  # Act
  run vedv::builder_service::__layer_copy_calc_id "$cmd"
  # Assert
  assert_success
  assert_output --partial "1 COPY ${src} dest/"
}

# Test vedv::builder_service::__layer_copy() function

@test "vedv::builder_service::__layer_copy() Should fail if image_id is empty" {
  # Call the function with empty cmd
  run vedv::builder_service::__layer_copy "" "cmd"
  # Assert the output and status
  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_copy() Should fail if cmd is empty" {
  # Call the function with empty cmd
  run vedv::builder_service::__layer_copy "image_id" ""
  # Assert the output and status
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_copy(), Should fail If getting user fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="source/"
  local -r dest="dest/"
  local -r cmd="1 COPY -u"
  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Invalid number of arguments, expected at least 4, got 3"
}

@test "vedv::builder_service::__layer_copy(), Should fail If _source is empty" {
  # Arrange
  local -r image_id="image_id"
  local -r _source=""
  local -r dest="dest/"
  local -r cmd="1 COPY -u root"

  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "File '': does not exist"
}

@test "vedv::builder_service::__layer_copy(), Should fail If getting dest fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="$(mktemp)"
  local -r dest="dest/"
  local -r cmd="1 COPY -u root ${_source}"
  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'dest' must not be empty"
}

@test "vedv::builder_service::__layer_copy() Should fail if chown is missing" {
  # Arrange
  local -r image_id="image_id"
  local -r cmd="1 COPY --chown"

  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert the output and status
  assert_failure
  assert_output "Invalid number of arguments, expected at least 4, got 3"
}

@test "vedv::builder_service::__layer_copy() Should fail if chmod is missing" {
  # Arrange
  local -r image_id="image_id"
  local -r cmd="1 COPY --chown nalyd --chmod"

  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert the output and status
  assert_failure
  assert_output "Argument 'chmod' no specified"
}

@test "vedv::builder_service::__layer_copy() Should succeed With all arguments" {
  local -r src="$(mktemp)"
  # Arrange
  local -r image_id="image_id"
  local -r cmd="1 COPY --chown nalyd --chmod 644 --user root ${src} dest1"
  # Stub
  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "image_id 1 COPY --chown nalyd --chmod 644 --user root ${src} dest1 COPY vedv::image_service::copy 'image_id' '${src}' 'dest1' 'root' 'nalyd' '644'"
  }
  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert the output and status
  assert_success
  assert_output ""
}

@test "vedv::builder_service::__layer_copy() succeeds if all arguments are valid and __layer_exec_cmd succeeds" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="$(mktemp)"
  local -r dest="dest/"
  local -r cmd="1 COPY ${_source} ${dest}"

  local -r exec_func="vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${_source}' '${dest}'"
  # Stub
  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "${image_id} ${cmd} COPY ${exec_func}"
  }
  # Act
  run vedv::builder_service::__layer_copy "$image_id" "$cmd"
  # Assert the output and status
  assert_success
  assert_output ""
}

# Test the vedv::builder_service::__simple_layer_command_calc_id() function

@test "vedv::builder_service::__simple_layer_command_calc_id() Should return error if cmd is empty" {
  # Run the function with an empty argument
  run vedv::builder_service::__simple_layer_command_calc_id "" ''
  # Assert that the function failed
  assert_failure
  # Assert that the function printed an error message
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__simple_layer_command_calc_id() Should return error if cmd name is not RUN" {
  # Arrange
  local -r cmd="1 MOVE source/ dest/"
  # Stub
  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    echo 'MOVE'
  }
  # Act
  run vedv::builder_service::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_failure
  assert_output "Invalid command name 'MOVE', it must be 'RUN'"
}

@test "vedv::builder_service::__simple_layer_command_calc_id() Should fails if getting cmd_name fails" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Stub
  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # Act
  run vedv::builder_service::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_failure
  assert_output "Failed to get command name from command '$cmd'"
}

@test "vedv::builder_service::__simple_layer_command_calc_id() should succeed if cmd name is RUN" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Stub
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      cat -
    else
      echo "$*"
    fi
  }
  # Act
  run vedv::builder_service::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_success
  assert_output "$cmd"
}

# Test vedv::builder_service::__layer_run()

@test "vedv::builder_service::__layer_run() Should fails with empty image_id argument" {
  # Arrange
  local -r image_id=""
  local -r cmd="1 RUN echo hello"
  # Act
  run vedv::builder_service::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_run() Should fails with empty cmd argument" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd=""
  # Act
  run vedv::builder_service::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_run() Should fail If empty 'cmd_body'" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd="1 RUN "
  # Act
  run vedv::builder_service::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'cmd_body' must not be empty"
}

@test "vedv::builder_service::__layer_run() Should succeed With valid arguments" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd="1 RUN echo hello"
  local -r cmd_body="echo hello"
  local -r exec_func="vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" '$cmd_body' \"\$port\""
  # Stubs
  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "${image_id} ${cmd} RUN ${exec_func}"
  }
  # Act
  run vedv::builder_service::__layer_run "$image_id" "$cmd"
  # Assert
  assert_success
  assert_output ""
}

# Test for vedv::builder_service::__delete_invalid_layers() function
@test "vedv::builder_service::__delete_invalid_layers() Should fail With empty 'image_id'" {
  local -r image_id=""
  local -r cmds="1 RUN echo hello"

  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fail With empty 'cmds'" {
  local -r image_id="image_id"
  local -r cmds=""

  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'cmds' is required"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fail if fail to remove child containers" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 RUN echo hello"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to remove child containers for image 'image_id'"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fail If fail to get layers ids" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 RUN echo hello"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to get layers ids for image 'image_id'"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fail If __save_environment_vars_to_local_file fails" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 RUN echo hello"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1 2 3"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to save environment variables for image 'image_id' on the local file"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fails If get first invalid positions fails" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  local -r layer_ids="1 2 3"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1 2 3"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to get first invalid positions between two arrays"
}

@test "vedv::builder_service::__delete_invalid_layers() Should suceed If first invalid cmd pos equals to 0" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  local -r layer_ids="1 2 3"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "1 2 3"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '0|-1'
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_success
  assert_output "0"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fails If fails to delete the first layer" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  local -r layer_ids="1 2 3"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "321 322 323"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '-1|1'
  }
  vedv::image_service::delete_layer() {
    assert_equal "$*" "$image_id 322"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to delete layer '322' for image '${image_id}'"
}

@test "vedv::builder_service::__delete_invalid_layers() Should fails If fails to restore last valid layer" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  local -r layer_ids="1 2 3"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "321 322 323"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '-1|1'
  }
  vedv::image_service::delete_layer() {
    assert_regex "$*" "$image_id 32[123]"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "$image_id 321"
    return 1
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to restore last valid layer '321'"
}

@test "vedv::builder_service::__delete_invalid_layers() Should succeed" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  local -r layer_ids="1 2 3"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 0
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "321 322 323"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '-1|1'
  }
  vedv::image_service::delete_layer() {
    assert_regex "$*" "$image_id 32[123]"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "$image_id 321"
  }
  # Act
  run vedv::builder_service::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_success
  assert_output '-1'
}

# Test vedv::builder_service::__build()
@test "vedv::builder_service::__build() should fail with empty 'vedvfile' argument" {
  # Arrange
  local -r vedvfile=""
  local -r image_name=""
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vedvfile' is required"
}

@test "vedv::builder_service::__build() Should fail with non-existent 'vedvfile'" {
  # Arrange
  local -r vedvfile="123abc45fgfhzbzdf"
  local -r image_name=""
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_NOT_FOUND"
  assert_output "File '${vedvfile}' does not exist"
}

@test "vedv::builder_service::__build() Should gen image_name If empty" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name=""
  # Stub
  petname() {
    echo 'petname-called' >&2
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure 1
  assert_output "petname-called"
}

@test "vedv::builder_service::__build() Should fail With invalid  vedvfile" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    false
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_VEDV_FILE"
  assert_output "Failed to get commands from Vedvfile '${vedvfile}'"
}

@test "vedv::builder_service::__build() Should fail If str_encode_vars fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "1 RUN echo hello"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "1 RUN echo hello
2  POWEROFF"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_VEDV_FILE"
  assert_output "Failed to prepare commands from Vedvfile '${vedvfile}'"
}

@test "vedv::builder_service::__build() Should fail On error getting image id from image name" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    false
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_BUILDER_SERVICE_OPERATION"
  assert_output "Failed to get image id for image '${image_name}'"
}

@test "vedv::builder_service::__build() Should fail If __create_image_by_from_cmd fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo ""
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "${from_cmd} ${image_name}"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to create image 'my-image-name'"
}

@test "vedv::builder_service::__build() Should fail If get_layer_count fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to get layer count for image 'my-image-name'"
}

@test "vedv::builder_service::__build() Should fail If delete_layer_cache fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  local -r no_cache='true'

  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    echo 0
  }
  vedv::image_service::delete_layer_cache() {
    assert_equal "$*" "1234567890"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name" "$no_cache"
  # Assert
  assert_failure
  assert_output "Failed to delete layer cache for image: 'my-image-name'"
}

@test "vedv::builder_service::__build() Should fail If __delete_invalid_layers fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local commands_encvars="$(<"$vedvfile")"
  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    echo 0
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed deleting invalid layers for image 'image1'. Try build the image again with --no-cache."
}

@test "vedv::builder_service::__build() Should fail If first_invalid_layer_pos < -1 or > commands_length length" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local commands_encvars="$(<"$vedvfile")"
  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    echo 0
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo -2
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_VALUE"
  assert_output --partial "Invalid first invalid layer position"

  # Stub
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 2
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_VALUE"
  assert_output --partial "Invalid first invalid layer position"
}

@test "vedv::builder_service::__build() Should fail If ::remove fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local commands_encvars="$(<"$vedvfile")"
  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    echo 0
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 0
  }
  vedv::image_service::remove() {
    assert_equal "$*" "1234567890 true"
    return 1
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to remove image 'image1'"
}

@test "vedv::builder_service::__build() Should call __build first_invalid_cmd_pos equal 0" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local commands_encvars="$(<"$vedvfile")"
  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  local -r get_commands_calls_file="$(mktemp)"
  echo 0 >"$get_commands_calls_file"

  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"

    local -i get_commands_calls="$(<"$get_commands_calls_file")"
    echo "$((++get_commands_calls))" >"$get_commands_calls_file"

    if [[ "$get_commands_calls" == 2 ]]; then
      return 1
    fi
    echo "$from_cmd"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${from_cmd}
2  POWEROFF"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "1234567890"
    echo 0
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 0
  }
  vedv::image_service::remove() {
    assert_equal "$*" "1234567890 true"
  }
  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to get commands from Vedvfile 'dist/test/lib/vedv/components/builder/fixtures/Vedvfile'"
}

@test "vedv::builder_service::__build() Should fail If get_layer_count 2nd call fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"

  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      return 1
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 1
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to get layer count for image 'image1'"
}

@test "vedv::builder_service::__build() Should fail If restore_last_layer fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 4
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 1
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
    return 1
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to restore layer last layer for image '1234567890'. Try build the image again with --no-cache."
}

@test "vedv::builder_service::__build() Should fail If cache_data" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 4
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 1
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "1234567890"
    return 1
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to cache data for image 'image1'"
}

@test "vedv::builder_service::__build() Should exit If first_invalid_cmd_pos is -1" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo '-1'
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_success
  assert_output "
Build finished
1234567890 image1"
}

@test "vedv::builder_service::__build() Should exit If __load_env_vars fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo '1'
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
    return 1
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to save environment variables for image '1234567890'"
}

@test "vedv::builder_service::__build() Should exit If get_cmd_name fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo '1'
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "2 COPY homefs/ ."
    return 1
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to get command name from command '2 COPY homefs/ .'"
}

@test "vedv::builder_service::__build() Should exit If __expand_cmd_parameters fails" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo '1'
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__expand_cmd_parameters() {
    assert_equal "$*" "2 COPY homefs/ ."
    return 1
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to evaluate command '2 COPY homefs/ .'"
}

@test "vedv::builder_service::__build() Should fail to create layer for RUN command" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 3
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -l"
    return 1
  }
  vedv::builder_service::__layer_copy() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__expand_cmd_parameters() {
    echo "$*"
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"

  assert_failure
  assert_output "Failed to create layer for command '4 RUN ls -l'"
}

@test "vedv::builder_service::__build() Should fail to restore layer on RUN failure" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  local -r vedvfile_content2="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l
5  POWEROFF"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "$vedvfile_content2"
    echo "$vedvfile_content2"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 3
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -l"
    return "$ERR_BUILDER_SERVICE_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL"
  }
  vedv::builder_service::__layer_copy() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__expand_cmd_parameters() {
    echo "$*"
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"

  assert_failure
  assert_output "Failed to create layer for command '4 RUN ls -l'
The previous layer to the failure could not be restored. Try build the image again with --no-cache."
}

@test "vedv::builder_service::__build() Should succeed" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/builder/fixtures/Vedvfile"
  local -r image_name="image1"

  local -r vedvfile_content="1 FROM /tmp/vedv/test/files/alpine-x86_64.ova
2 COPY homefs/ .
3 COPY home.config /home/vedv/
4 RUN ls -l"

  # Stub
  petname() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vedvfile_content"
  }
  utils::str_encode_vars() {
    assert_equal "$*" "${vedvfile_content}
5  POWEROFF"
    echo "$vedvfile_content"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo "1234567890"
  }
  vedv::builder_service::__create_image_by_from_cmd() {
    assert_equal "$*" "INVALID_CALL"
  }

  local -r get_layer_count_calls_file="$(mktemp)"
  echo 0 >"$get_layer_count_calls_file"
  vedv::image_service::stop() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_entity::get_layer_count() {
    assert_equal "$*" "$image_id"

    local -i get_layer_count_calls="$(<"$get_layer_count_calls_file")"
    echo "$((++get_layer_count_calls))" >"$get_layer_count_calls_file"

    if [[ "$get_layer_count_calls" == 2 ]]; then
      echo 2
      return 0
    fi
    echo 2
  }
  vedv::builder_service::__delete_invalid_layers() {
    assert_equal "$*" "1234567890 ${commands_encvars}"
    echo 3
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::restore_last_layer() {
    assert_equal "$*" "1234567890"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__load_env_vars() {
    assert_equal "$*" "$image_id"
  }
  vedv::builder_service::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -l"
    echo 12346
  }
  vedv::builder_service::__layer_poweroff() {
    assert_equal "$*" "${image_id} 5  POWEROFF "
    echo 12345
  }
  vedv::builder_service::__layer_copy() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::builder_service::__expand_cmd_parameters() {
    echo "$*"
  }

  # Act
  run vedv::builder_service::__build "$vedvfile" "$image_name"

  assert_success
  assert_output "created layer '12346' for command 'RUN'

Build finished
1234567890 image1"
}

# Tests for vedv::builder_service::build()

@test 'vedv::builder_service::build() with an empty vedvfile should return an error' {
  local -r vedvfile=''

  run vedv::builder_service::build "$vedvfile"

  assert_failure
  assert_output "Argument 'vedvfile' is required"
}

@test 'vedv::builder_service::build() with non existing vedvfile should return an error' {
  local -r vedvfile='vedfile-1234454343-abc'

  vedv::image_entity::has_containers() {
    echo false
  }
  run vedv::builder_service::build "$vedvfile"

  assert_failure
  assert_output "File '${vedvfile}' does not exist"
}

@test 'vedv::builder_service::build() Should fail If fails to get image id' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name="image1"
  local -r force=""
  local -r no_cache=""

  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "image1"
    return 1
  }
  run vedv::builder_service::build "$vedvfile" "$image_name"

  assert_failure
  assert_output "Failed to get image id for image '${image_name}'"
}

@test 'vedv::builder_service::build() Should fail If has_containers fails' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name="image1"
  local -r force=false
  local -r no_cache=""

  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "image1"
    echo "22345"
  }
  vedv::image_entity::has_containers() {
    assert_equal "$*" "22345"
    return 1
  }

  run vedv::builder_service::build "$vedvfile" "$image_name" "$force" "$no_cache"

  assert_failure
  assert_output "Failed to check if image '${image_name}' has containers"
}

@test 'vedv::builder_service::build() Should fail If force is false and has containers' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name="image1"
  local -r force=false
  local -r no_cache=""

  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "image1"
    echo "22345"
  }
  vedv::image_entity::has_containers() {
    assert_equal "$*" "22345"
    echo true
  }

  run vedv::builder_service::build "$vedvfile" "$image_name" "$force" "$no_cache"

  assert_failure
  assert_output "The image '${image_name}' has containers, you need to force the build, the containers will be removed."
}

@test 'vedv::builder_service::build() Should fail If stop fails' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name="image1"
  local -r force=false
  local -r no_cache=false

  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "image1"
    echo "22345"
  }
  vedv::image_entity::has_containers() {
    assert_equal "$*" "22345"
    echo false
  }
  vedv::builder_service::__build() {
    assert_equal "$*" "${vedvfile} ${image_name} false"
    return 1
  }
  vedv::image_service::set_use_cache() {
    assert_equal "$*" "true"
  }
  vedv::image_service::cache_data() {
    assert_equal "$*" "22345"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "22345"
    return 1
  }

  run vedv::builder_service::build "$vedvfile" "$image_name" "$force" "$no_cache"

  assert_failure
  assert_output "The build proccess has failed.
Failed to stop the image 'image1'.You must stop it."
}

@test 'vedv::builder_service::build() Should succeed' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name="image1"
  local -r force=false
  local -r no_cache=false

  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "image1"
    echo "22345"
  }
  vedv::image_entity::has_containers() {
    assert_equal "$*" "22345"
    echo false
  }
  vedv::builder_service::__build() {
    assert_equal "$*" "${vedvfile} ${image_name} false"
  }
  vedv::image_service::set_use_cache() {
    assert_equal "$*" "true"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "22345"
  }

  run vedv::builder_service::build "$vedvfile" "$image_name" "$force" "$no_cache"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_run_calc_id()

@test "vedv::builder_service::__layer_run_calc_id(): Should succeed" {
  local -r cmd="1 RUN echo 'hello world'"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} RUN"
    echo "12345"
  }

  run vedv::builder_service::__layer_run_calc_id "$cmd"

  assert_success
  assert_output "12345"
}

# Tests for vedv::builder_service::__layer_user_calc_id()

@test "vedv::builder_service::__layer_user_calc_id(): Should succeed" {
  local -r cmd="1 USER nalyd"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} USER"
    echo "12345"
  }

  run vedv::builder_service::__layer_user_calc_id "$cmd"

  assert_success
  assert_output "12345"
}

# Tests for vedv::builder_service::__layer_user()

@test "vedv::builder_service::__layer_user() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_user() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=

  run vedv::builder_service::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_user() Should fail If user_name is empty" {
  local -r image_id="12345"
  local -r cmd="1 USER"

  run vedv::builder_service::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid number of arguments, expected 3, got 2"
}

@test "vedv::builder_service::__layer_user() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 USER nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 USER nalyd USER vedv::image_service::fs::set_user '12345' 'nalyd'"
    return 1
  }

  run vedv::builder_service::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output ""
}

@test "vedv::builder_service::__layer_user() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 USER nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 USER nalyd USER vedv::image_service::fs::set_user '12345' 'nalyd'"
  }

  run vedv::builder_service::__layer_user "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_workdir_calc_id()

@test "vedv::builder_service::__layer_workdir_calc_id(): Should succeed" {
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} WORKDIR"
    echo "12345"
  }

  run vedv::builder_service::__layer_workdir_calc_id "$cmd"

  assert_success
  assert_output "12345"
}

# Tests for vedv::builder_service::__layer_workdir()

@test "vedv::builder_service::__layer_workdir() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_workdir() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=

  run vedv::builder_service::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_workdir() Should fail If workdir is empty" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR"

  run vedv::builder_service::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid number of arguments, expected 3, got 2"
}

@test "vedv::builder_service::__layer_workdir() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 WORKDIR /home/nalyd WORKDIR vedv::image_service::fs::set_workdir '12345' '/home/nalyd' >/dev/null"
    return 1
  }

  run vedv::builder_service::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output ""
}

@test "vedv::builder_service::__layer_workdir() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 WORKDIR /home/nalyd WORKDIR vedv::image_service::fs::set_workdir '12345' '/home/nalyd' >/dev/null"
  }

  run vedv::builder_service::__layer_workdir "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_env_calc_id()

@test "vedv::builder_service::__layer_env_calc_id(): Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 ENV E1=v1"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} ENV"
  }

  run vedv::builder_service::__layer_env_calc_id "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_env()

@test "vedv::builder_service::__layer_env() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_env() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_env() Should fail If get_cmd_body fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    return 1
  }

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get env from command '1 ENV TEST=123'"
}

@test "vedv::builder_service::__layer_env() Should fail If env is empty" {
  local -r image_id="12345"
  local -r cmd="1 ENV"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV"
  }

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'env' must not be empty"
}

@test "vedv::builder_service::__layer_env() Should fail If str_encode fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    return 1
  }

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to encode command 'TEST=123'"
}

@test "vedv::builder_service::__layer_env() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    echo "TEST=123"
  }
  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 ENV TEST=123 ENV vedv::image_service::fs::add_environment_var '12345' 'TEST=123'"
    return 1
  }

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output ""
}

@test "vedv::builder_service::__layer_env() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    echo "TEST=123"
  }
  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 ENV TEST=123 ENV vedv::image_service::fs::add_environment_var '12345' 'TEST=123'"
  }

  run vedv::builder_service::__layer_env "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__expand_cmd_parameters()

@test "vedv::builder_service::__expand_cmd_parameters() Should fail With empty cmd" {
  local -r cmd=""

  run vedv::builder_service::__expand_cmd_parameters "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__expand_cmd_parameters() Should fail If str_escape_double_quotes fails" {
  local -r cmd="1 RUN ls -la /home/vedv"

  utils::str_escape_double_quotes() {
    assert_equal "$*" "1 RUN ls -la /home/vedv"
    return 1
  }

  run vedv::builder_service::__expand_cmd_parameters "$cmd"

  assert_failure
  assert_output "Failed to escape command '1 RUN ls -la /home/vedv'"
}

@test "vedv::builder_service::__expand_cmd_parameters() Should succeed If cmd does not have parameters" {
  local -r cmd="1 RUN ls -la /home/vedv"

  utils::str_escape_double_quotes() {
    assert_equal "$*" "1 RUN ls -la /home/vedv"
    echo "1 RUN ls -la /home/vedv"
  }

  run vedv::builder_service::__expand_cmd_parameters "$cmd"

  assert_success
  assert_output "1 RUN ls -la /home/vedv"
}

@test "vedv::builder_service::__expand_cmd_parameters() Should succeed If cmd has parameters" {
  local -r cmd="1 RUN ls -la /home/vedv"

  utils::str_escape_double_quotes() {
    assert_equal "$*" "1 RUN ls -la /home/vedv"
    echo '1 RUN ls -la /home/${VAR1}/${VAR2}/${VAR3} &&
echo \"${VAR22}:${VAR23}\"'
  }

  cat <<'EOF' >"$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
  VAR1=var1
  VAR2='var2'
  VAR3="var3"
  VAR22='var2 var2'
  VAR23="var3 var3"
EOF

  run vedv::builder_service::__expand_cmd_parameters "$cmd"

  assert_success
  assert_output '1 RUN ls -la /home/var1/var2/var3 &&
echo "var2 var2:var3 var3"'
}

# Tests for vedv::builder_service::__load_env_vars()
@test "vedv::builder_service::__load_env_vars() Should fail With empty image_id" {
  local -r image_id=""

  run vedv::builder_service::__load_env_vars "$image_id"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__load_env_vars() Should fail If get_environment_vars fails" {
  local -r image_id="12345"

  vedv::image_service::fs::list_environment_vars() {
    assert_equal "$*" "12345"
    return 1
  }

  run vedv::builder_service::__load_env_vars "$image_id"

  assert_failure
  assert_output "Failed to get environment variables for image '12345'"
}

@test "vedv::builder_service::__load_env_vars() Should succeed" {
  local -r image_id="12345"

  vedv::image_service::fs::list_environment_vars() {
    assert_equal "$*" "12345"
    cat <<'EOF'
VAR1=var1
VAR2='var2'
VAR3="var3"
VAR22='var2 var2'
VAR23="var3 var3"
EOF
  }

  run vedv::builder_service::__load_env_vars "$image_id"

  assert_success
  assert_output ""

  run cat "$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"

  assert_success
  assert_output "local -r var_9f57a558b3_VAR1=var1
local -r var_9f57a558b3_VAR2='var2'
local -r var_9f57a558b3_VAR3=\"var3\"
local -r var_9f57a558b3_VAR22='var2 var2'
local -r var_9f57a558b3_VAR23=\"var3 var3\""
}

# Tests for vedv::builder_service::__layer_shell_calc_id()
@test "vedv::builder_service::__layer_shell_calc_id(): Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 SHELL zsh"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} SHELL"
  }

  run vedv::builder_service::__layer_shell_calc_id "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_shell()

@test "vedv::builder_service::__layer_shell() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_shell "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_shell() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::builder_service::__layer_shell "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_shell() Should fail If shell is empty" {
  local -r image_id="12345"
  local -r cmd="1 SHELL"

  run vedv::builder_service::__layer_shell "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid number of arguments, expected 3, got 2"
}

@test "vedv::builder_service::__layer_shell() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 SHELL nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 SHELL nalyd SHELL vedv::image_service::fs::set_shell '12345' 'nalyd'"
    return 1
  }

  run vedv::builder_service::__layer_shell "$image_id" "$cmd"

  assert_failure
  assert_output ""
}

@test "vedv::builder_service::__layer_shell() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 SHELL nalyd"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 SHELL nalyd SHELL vedv::image_service::fs::set_shell '12345' 'nalyd'"
  }

  run vedv::builder_service::__layer_shell "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_expose_calc_id()
# bats test_tags=only
@test "vedv::builder_service::__layer_expose_calc_id(): Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 EXPOSE 8080"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} EXPOSE"
  }

  run vedv::builder_service::__layer_expose_calc_id "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_expose()
# bats test_tags=only
@test "vedv::builder_service::__layer_expose() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_expose "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}
# bats test_tags=only
@test "vedv::builder_service::__layer_expose() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::builder_service::__layer_expose "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}
# bats test_tags=only
@test "vedv::builder_service::__layer_expose() Should fail If port is empty" {
  local -r image_id="12345"
  local -r cmd="1 EXPOSE"

  run vedv::builder_service::__layer_expose "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid number of arguments, expected at least 3, got 2"
}
# bat test_tags=only
@test "vedv::builder_service::__layer_expose() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 EXPOSE 8080"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 EXPOSE 8080 EXPOSE vedv::image_service::fs::add_exposed_ports '12345' '8080'"
    return 1
  }

  run vedv::builder_service::__layer_expose "$image_id" "$cmd"

  assert_failure
  assert_output ""
}
# bats test_tags=only
@test "vedv::builder_service::__layer_expose() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 EXPOSE 8080"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 EXPOSE 8080 EXPOSE vedv::image_service::fs::add_exposed_ports '12345' '8080'"
  }

  run vedv::builder_service::__layer_expose "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_system()

@test "vedv::builder_service::__layer_system() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_system() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_system() Should fail If cpus is empty" {
  local -r image_id="12345"
  local -r cmd="1 SYSTEM --cpus"

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid number of arguments, expected at least 4, got 3"
}

@test "vedv::builder_service::__layer_system() Should fail If memory is empty" {
  local -r image_id="12345"
  local -r cmd="1 SYSTEM --cpus 2 --memory"

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'memory' no specified"
}

@test "vedv::builder_service::__layer_system() Should fail With invalid argument" {
  local -r image_id="12345"
  local -r cmd="1 SYSTEM --cpas 2"

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output "Invalid argument: --cpas"
}

@test "vedv::builder_service::__layer_system() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 SYSTEM --cpus 2 --memory 512"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 SYSTEM --cpus 2 --memory 512 SYSTEM vedv::image_service::fs::set_system '12345' '2' '512'"
    return 1
  }

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_failure
  assert_output ""
}

@test "vedv::builder_service::__layer_system() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 SYSTEM --cpus 2 --memory 512"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 SYSTEM --cpus 2 --memory 512 SYSTEM vedv::image_service::fs::set_system '12345' '2' '512'"
  }

  run vedv::builder_service::__layer_system "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__create_image_by_from_cmd()

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail With empty from_cmd" {
  local from_cmd=""
  local image_name=""

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Argument 'from_cmd' is required"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail With empty image_name" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name=""

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Argument 'image_name' is required"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail If get_cmd_body fails" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name="image1"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "FROM admin@alpine/alpine-13"
    return 1
  }

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Failed to get cmd body from Vedvfile 'FROM admin@alpine/alpine-13'"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail If import_from_any fails" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name="image1"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "FROM admin@alpine/alpine-13"
    echo "admin@alpine/alpine-13"
  }
  vedv::image_service::import_from_any() {
    assert_equal "$*" "admin@alpine/alpine-13 image1"
    return 1
  }

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Failed to pull image 'admin@alpine/alpine-13'"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail If get_layer_at fails" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name="image1"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "FROM admin@alpine/alpine-13"
    echo "admin@alpine/alpine-13"
  }
  vedv::image_service::import_from_any() {
    assert_equal "$*" "admin@alpine/alpine-13 image1"
    echo "1234567890 image1"
  }
  vedv::image_entity::get_layer_at() {
    assert_equal "$*" "1234567890 0"
    return 1
  }

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Failed to get layer '0' for image '1234567890 image1'"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should fail If delete_layer fails" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name="image1"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "FROM admin@alpine/alpine-13"
    echo "admin@alpine/alpine-13"
  }
  vedv::image_service::import_from_any() {
    assert_equal "$*" "admin@alpine/alpine-13 image1"
    echo "1234567890 image1"
  }
  vedv::image_entity::get_layer_at() {
    assert_equal "$*" "1234567890 0"
    echo "2234567890"
  }
  vedv::image_service::delete_layer() {
    assert_equal "$*" "1234567890 2234567890"
    return 1
  }

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_failure
  assert_output "Failed to delete layer '1' for image '1234567890 image1'"
}

@test "vedv::builder_service::__create_image_by_from_cmd() Should succeed" {
  local from_cmd="FROM admin@alpine/alpine-13"
  local image_name="image1"

  vedv::builder_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "FROM admin@alpine/alpine-13"
    echo "admin@alpine/alpine-13"
  }
  vedv::image_service::import_from_any() {
    assert_equal "$*" "admin@alpine/alpine-13 image1"
    echo "1234567890 image1"
  }
  vedv::image_entity::get_layer_at() {
    assert_equal "$*" "1234567890 0"
    echo "2234567890"
  }
  vedv::image_service::delete_layer() {
    assert_equal "$*" "1234567890 2234567890"
  }

  run vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name"

  assert_success
  assert_output "1234567890"
}

# Tests for vedv::builder_service::__layer_poweroff_calc_id()

@test "vedv::builder_service::__layer_poweroff_calc_id(): Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 POWEROFF"

  vedv::builder_service::__simple_layer_command_calc_id() {
    assert_equal "$*" "${cmd} POWEROFF"
  }

  run vedv::builder_service::__layer_poweroff_calc_id "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::builder_service::__layer_poweroff()

@test "vedv::builder_service::__layer_poweroff() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::builder_service::__layer_poweroff "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::builder_service::__layer_poweroff() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::builder_service::__layer_poweroff "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::builder_service::__layer_poweroff() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 POWEROFF"

  vedv::builder_service::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 POWEROFF POWEROFF vedv::image_service::poweroff '12345' >/dev/null"
  }

  run vedv::builder_service::__layer_poweroff "$image_id" "$cmd"

  assert_success
  assert_output ""
}
