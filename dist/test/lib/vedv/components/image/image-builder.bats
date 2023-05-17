# shellcheck disable=SC2317,SC2034,SC2031,SC2030
load test_helper

@test 'vedv::image_builder::constructor() Should succeed' {
  :
}

vedv:image_vedvfile_service::get_joined_vedvfileignore() {
  echo "$TEST_BASE_VEDVFILEIGNORE"
}

vedv:image_vedvfile_service::get_base_vedvfileignore_path() {
  echo "$TEST_BASE_VEDVFILEIGNORE"
}

vedv:image_vedvfile_service::get_vedvfileignore_path() {
  echo "$TEST_VEDVFILEIGNORE"
}

# Tests for vedv::image_builder::__create_layer()
@test "vedv::image_builder::__create_layer(): Should fail With missing 'image_id' argument" {
  run vedv::image_builder::__create_layer "" ""

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__create_layer(): Should fail With missing 'cmd' argument" {
  local -r image_id="123"

  run vedv::image_builder::__create_layer "$image_id" ""

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__create_layer(): Should fail If it can't get 'cmd_name' from 'cmd'" {
  local -r image_id="123"
  local -r cmd="1"

  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::image_builder::__create_layer(): Should fail If fail to get image vm name" {
  local -r image_id="123"
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
    return 0
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get vm name for image with id '123'"
}

@test "vedv::image_builder::__create_layer(): Should fail If vm name is empty" {
  local -r image_id="123"
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
    return 0
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo ''
    return 0
  }

  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "There is not vm for image with id '123'"
}

@test "vedv::image_builder::__create_layer(): Should fail If fail to get layer id" {
  local -r image_id="123"
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
    return 0
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    return 1
  }
  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to calculate layer id for cmd: '$cmd'"
}

@test "vedv::image_builder::__create_layer(), Should fail If fail to take snapshot" {
  local -r image_id="image_id"
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
    return 0
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo "layer_id"
    return 0
  }
  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "image:image1|crc:image_id| layer:RUN|id:layer_id|"
    return 1
  }
  # run the tested function
  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to create layer 'layer:RUN|id:layer_id|' for image 'image_id', code: 1"
}

@test "vedv::image_builder::__create_layer(), Should success" {
  local -r image_id="image_id"
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
    return 0
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo "image:image1|crc:${1}|"
    return 0
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo "layer_id"
    return 0
  }
  vedv::hypervisor::take_snapshot() {
    assert_equal "$*" "image:image1|crc:image_id| layer:RUN|id:layer_id|"
    return 0
  }

  run vedv::image_builder::__create_layer "$image_id" "$cmd"

  assert_success
  assert_output "layer_id"
}

# Test for vedv::image_builder::__calc_command_layer_id()

@test "vedv::image_builder::__calc_command_layer_id() Should fails if cmd is empty" {
  local -r cmd=""

  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__calc_command_layer_id() Should fails if get_arg_from_string fails" {
  local -r cmd="1 RUN echo hello"

  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::image_builder::__calc_command_layer_id() Should fails if cmd name is empty" {
  local -r cmd="1 RUN echo hello"

  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
  }
  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "'cmd_name' must not be empty"
}

@test "vedv::image_builder::__calc_command_layer_id() Should fails If __layer_run_calc_id fails" {
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    return 1
  }

  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "Failed to calculate layer id for cmd: '$cmd'"
}

@test "vedv::image_builder::__calc_command_layer_id() Should fails If calc_layer_id is empty" {
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
  }

  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_failure
  assert_output "'calc_layer_id' must not be empty"
}

@test "vedv::image_builder::__calc_command_layer_id() Should success" {
  local -r cmd="1 RUN echo hello"

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
  }
  vedv::image_builder::__layer_run_calc_id() {
    assert_equal "$*" "$cmd"
    echo 'layer_id'
  }

  run vedv::image_builder::__calc_command_layer_id "$cmd"

  assert_success
  assert_output 'layer_id'
}

# Tests for vedv::image_builder::__layer_execute_cmd()
@test "vedv::image_builder::__layer_execute_cmd(), Should fail With invalid 'image_id' parameter" {
  local -r image_id=""
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With invalid 'cmd' parameter" {
  local -r image_id="dummy_id"
  local -r cmd=""
  local -r caller_command='COPY'
  local -r exec_func=':'

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With invalid 'caller_command' parameter" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command=''
  local -r exec_func=':'

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'caller_command' is required"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With invalid 'exec_func' parameter" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=''

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'exec_func' is required"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail If get_arg_from_string fail" {
  # Arrange
  local -r image_id="dummy_id"
  local -r cmd="1 RUN dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'
  # Stub
  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # Act
  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With command not equal to 'COPY'" {
  local -r image_id="dummy_id"
  local -r cmd="1 RUN dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "RUN"
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid command name 'RUN', it must be 'COPY'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail If get_last_layer_id fail" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "COPY"
  }
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to get last layer id for image '${image_id}'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With 'exec_func' failure" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=false

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "COPY"
  }
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    echo "layer_id"
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo "last_layer_id"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} last_layer_id"
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_LAYER_OPERATION"
  assert_output "Failed to execute command '$cmd'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail If restore_layer fail" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=false
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "COPY"
  }
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo "last_layer_id"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} last_layer_id"
    return 1
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure
  assert_output "Failed to restore layer 'last_layer_id'
Failed to execute command '1 COPY dummy_source dummy_dest'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should fail With __create_layer failure" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=true
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "COPY"
  }
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo "last_layer_id"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} last_layer_id"
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to create layer for image '${image_id}'"
}

@test "vedv::image_builder::__layer_execute_cmd(), Should succeed" {
  local -r image_id="dummy_id"
  local -r cmd="1 COPY dummy_source dummy_dest"
  local -r caller_command='COPY'
  local -r exec_func=':'

  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo "COPY"
  }
  vedv::image_service::is_started() {
    assert_equal "$*" "$image_id"
    echo true
  }
  vedv::image_entity::get_last_layer_id() {
    assert_equal "$*" "$image_id"
    echo "last_layer_id"
  }
  vedv::image_service::restore_layer() {
    assert_equal "$*" "${image_id} last_layer_id"
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "${image_id} ${cmd}"
    echo "layer_id"
  }

  run vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "$caller_command" "$exec_func"

  assert_success
  assert_output "layer_id"
}

# Tests for vedv::image_builder::__layer_from() function

@test "vedv::image_builder::__layer_from(), Should fail With empty 'image' argument" {
  # Run program with invalid arguments
  run vedv::image_builder::__layer_from "" "image_name"

  assert_failure
  assert_output "Argument 'image' is required"
}

@test "vedv::image_builder::__layer_from(), Should fail With empty 'image_name' argument" {
  # Run program with invalid arguments
  run vedv::image_builder::__layer_from 'image' ''

  assert_failure
  assert_output "Argument 'image_name' is required"
}

@test "vedv::image_builder::__layer_from(), Should fail if pull fails" {
  local -r image='image'
  local -r image_name='image_name'
  # Stub
  vedv::image_service::pull() {
    assert_equal "$*" "${image} ${image_name} true"
    return 1
  }

  run vedv::image_builder::__layer_from 'image' 'image_name'

  assert_failure
  assert_output "Failed to pull image '${image}'"
}

@test "vedv::image_builder::__layer_from(), Should fail if create layer fails" {
  local -r image='image'
  local -r image_name='image_name'

  local -r cmd="1 FROM ${image}"
  # Stub
  vedv::image_service::pull() {
    assert_equal "$*" "${image} ${image_name} true"
    echo 'image_id'
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "image_id ${cmd}"
    return 1
  }
  run vedv::image_builder::__layer_from 'image' 'image_name'

  assert_failure
  assert_output "Failed to create layer for image 'image_id'"
}

@test "vedv::image_builder::__layer_from(), Should fail if layer_id is empty" {
  local -r image='image'
  local -r image_name='image_name'

  local -r cmd="1 FROM ${image}"
  # Stub
  vedv::image_service::pull() {
    assert_equal "$*" "${image} ${image_name} true"
    echo 'image_id'
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "image_id ${cmd}"
  }
  run vedv::image_builder::__layer_from 'image' 'image_name'

  assert_failure
  assert_output "'layer_id' must not be empty"
}

@test "vedv::image_builder::__layer_from(), Should success" {
  local -r image='image'
  local -r image_name='image_name'
  # Stub
  vedv::image_service::pull() {
    assert_equal "$*" "${image} ${image_name} true"
    echo 'image_id'
  }
  vedv::image_builder::__create_layer() {
    assert_equal "$*" "image_id ${cmd}"
    echo 'layer_id'
  }

  run vedv::image_builder::__layer_from 'image' 'image_name'

  assert_success
  assert_output 'image_id'
}

# Tests for vedv::image_builder::__validate_layer_from() function

@test "vedv::image_builder::__validate_layer_from(), Should fail With empty 'image_id' argument" {

  run vedv::image_builder::__validate_layer_from "" "from_cmd"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__validate_layer_from(), Should fail With empty 'from_cmd' argument" {
  run vedv::image_builder::__validate_layer_from "image1" ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'from_cmd' is required"
}

@test "vedv::image_builder::__validate_layer_from(), Should fail on error getting from_file_sum" {
  local -r image_id="image_id"
  local -r from_cmd="1 FROM ${TEST_OVA_FILE}"

  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
    return 1
  }

  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_failure
  assert_output "Failed to cal id for: '${from_cmd}'"
}

@test "vedv::image_builder::__validate_layer_from(), Should fail If from_file_sum is empty" {
  local -r image_id="image_id"
  local -r from_cmd="FROM ${TEST_OVA_FILE}"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$TEST_OVA_FILE"
  }
  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
  }

  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_failure
  assert_output "from_file_sum' must not be empty"
}

@test "vedv::image_builder::__validate_layer_from(), Should fail on error getting image_file_sum" {
  local -r image_id="image_id"
  local -r from_cmd="FROM ${TEST_OVA_FILE}"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$TEST_OVA_FILE"
  }
  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
    echo "1234"
  }
  vedv::image_entity::get_ova_file_sum() {
    assert_equal "$*" "$image_id"
    return 1
  }

  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_failure
  assert_output "Failed to get ova file sum for image with id 'image_id'"
}

@test "vedv::image_builder::__validate_layer_from(), Should fail If image_file_sum is empty" {
  local -r image_id="image_id"
  local -r from_cmd="FROM ${TEST_OVA_FILE}"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$TEST_OVA_FILE"
  }
  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
    echo "1234"
  }
  vedv::image_entity::get_ova_file_sum() {
    assert_equal "$*" "$image_id"
  }

  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_failure
  assert_output "image_file_sum' must not be empty"
}

@test "vedv::image_builder::__validate_layer_from(), Should be 'invalid' When OVA file sum is different from the original one" {
  local -r image_id="image_id"
  local -r from_cmd="FROM ${TEST_OVA_FILE}"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$TEST_OVA_FILE"
  }
  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
    echo "1234"
  }
  vedv::image_entity::get_ova_file_sum() {
    assert_equal "$*" "$image_id"
    echo "4567"
  }
  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_success
  assert_output "invalid"
}

@test "vedv::image_builder::__validate_layer_from(), Should success When OVA file sum is the same as the original one" {
  local -r image_id="image_id"
  local -r from_cmd="FROM ${TEST_OVA_FILE}"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$TEST_OVA_FILE"
  }
  vedv::image_builder::__layer_from_calc_id() {
    assert_equal "$*" "$from_cmd"
    echo "1234"
  }
  vedv::image_entity::get_ova_file_sum() {
    assert_equal "$*" "$image_id"
    echo "1234"
  }
  run vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd"

  assert_success
  assert_output 'valid'
}

# Tests for vedv::image_builder::__layer_copy_calc_id()

@test "vedv::image_builder::__layer_copy_calc_id() should return error if cmd is empty" {
  # arrange
  local -r cmd=""
  # act
  run vedv::image_builder::__layer_copy_calc_id "$cmd"
  # assert
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_copy_calc_id(), Should If getting cmd_name fails" {
  # arrange
  local -r cmd="1 RUN source/ dest/"
  # mocks
  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # act
  run vedv::image_builder::__layer_copy_calc_id "$cmd"
  # assert
  assert_failure
  assert_output "Failed to get cmd name from cmd: '$cmd'"
}

@test "vedv::image_builder::__layer_copy_calc_id(), Should return error if cmd name is not 'COPY'" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
  }
  # Act
  run vedv::image_builder::__layer_copy_calc_id "$cmd"
  # Assert
  assert_failure
  assert_output "Invalid command name 'RUN', it must be 'COPY'"
}

@test "vedv::image_builder::__layer_copy_calc_id(), Should fail If _source is empty" {
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
  utils::get_arg_from_string() {
    if [[ "$*" == "${cmd} 2" ]]; then
      echo "COPY"
      return 0
    fi
  }
  # Act
  run vedv::image_builder::__layer_copy_calc_id "$cmd"
  # Assert
  assert_failure
  assert_output "'src' must not be empty"
}

@test "vedv::image_builder::__layer_copy_calc_id(), Should write copy layer id to stdout" {
  # Arrange
  local -r cmd="1 COPY source/ dest/"
  # Stub
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      cat -
    else
      echo "$*"
    fi
  }
  utils::crc_file_sum() { crc_sum "$@"; }
  utils::get_arg_from_string() {
    if [[ "$*" == "${cmd} 2" ]]; then
      echo "COPY"
      return 0
    fi
    if [[ "$*" == "${cmd} 3" ]]; then
      echo "source/"
      return 0
    fi
  }
  # act
  run vedv::image_builder::__layer_copy_calc_id "$cmd"
  # assert
  assert_success
  assert_output --partial "1 COPY source/ dest/source/"
}

# Test vedv::image_builder::__layer_copy() function

@test "vedv::image_builder::__layer_copy() Should fail if image_id is empty" {
  # Call the function with empty cmd
  run vedv::image_builder::__layer_copy "" "cmd"
  # Assert the output and status
  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__layer_copy() Should fail if cmd is empty" {
  # Call the function with empty cmd
  run vedv::image_builder::__layer_copy "image_id" ""
  # Assert the output and status
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_copy(), Should fail If getting user fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="source/"
  local -r dest="dest/"
  local -r cmd="1 COPY -u"
  # Act
  run vedv::image_builder::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'user' no specified"
}

@test "vedv::image_builder::__layer_copy(), Should fail If _source is empty" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="source/"
  local -r dest="dest/"
  local -r cmd="1 COPY -u root"

  # Act
  run vedv::image_builder::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'src' must not be empty"
}

@test "vedv::image_builder::__layer_copy(), Should fail If getting dest fails" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="source/"
  local -r dest="dest/"
  local -r cmd="1 COPY -u root ${_source}"
  # Act
  run vedv::image_builder::__layer_copy "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'dest' must not be empty"
}

@test "vedv::image_builder::__layer_copy() succeeds if all arguments are valid and __layer_exec_cmd succeeds" {
  # Arrange
  local -r image_id="image_id"
  local -r _source="source/"
  local -r dest="dest/"
  local -r cmd="1 COPY ${_source} ${dest}"

  local -r exec_func="vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${_source}' '${dest}'"
  # Stub
  utils::get_arg_from_string() {
    if [[ "$*" == "${cmd} 3" ]]; then
      echo "source/"
      return 0
    fi
    if [[ "$*" == "${cmd} 4" ]]; then
      echo "dest/"
      return 0
    fi
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "${image_id} ${cmd} COPY ${exec_func}"
  }
  # Act
  run vedv::image_builder::__layer_copy "$image_id" "$cmd"
  # Assert the output and status
  assert_success
  assert_output ""
}

# Test the vedv::image_builder::__simple_layer_command_calc_id() function

@test "vedv::image_builder::__simple_layer_command_calc_id() Should return error if cmd is empty" {
  # Run the function with an empty argument
  run vedv::image_builder::__simple_layer_command_calc_id "" ''
  # Assert that the function failed
  assert_failure
  # Assert that the function printed an error message
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__simple_layer_command_calc_id() Should return error if cmd name is not RUN" {
  # Arrange
  local -r cmd="1 MOVE source/ dest/"
  # Stub
  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    echo 'MOVE'
  }
  # Act
  run vedv::image_builder::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_failure
  assert_output "Invalid command name 'MOVE', it must be 'RUN'"
}

@test "vedv::image_builder::__simple_layer_command_calc_id() Should fails if getting cmd_name fails" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Stub
  vedv::image_vedvfile_service::get_cmd_name() {
    assert_equal "$*" "$cmd"
    return 1
  }
  # Act
  run vedv::image_builder::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_failure
  assert_output "Failed to get command name from command '$cmd'"
}

@test "vedv::image_builder::__simple_layer_command_calc_id() should succeed if cmd name is RUN" {
  # Arrange
  local -r cmd="1 RUN source/ dest/"
  # Stub
  utils::get_arg_from_string() {
    assert_equal "$*" "${cmd} 2"
    echo 'RUN'
  }
  utils::crc_sum() {
    if [[ ! -t 0 ]]; then
      cat -
    else
      echo "$*"
    fi
  }
  # Act
  run vedv::image_builder::__simple_layer_command_calc_id "$cmd" 'RUN'
  # Assert
  assert_success
  assert_output "$cmd"
}

# Test vedv::image_builder::__layer_run()

@test "vedv::image_builder::__layer_run() Should fails with empty image_id argument" {
  # Arrange
  local -r image_id=""
  local -r cmd="1 RUN echo hello"
  # Act
  run vedv::image_builder::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__layer_run() Should fails with empty cmd argument" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd=""
  # Act
  run vedv::image_builder::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_run() Should fail If empty 'cmd_body'" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd="1 RUN "
  # Act
  run vedv::image_builder::__layer_run "$image_id" "$cmd"
  # Assert
  assert_failure
  assert_output "Argument 'cmd_body' must not be empty"
}

@test "vedv::image_builder::__layer_run() Should succeed With valid arguments" {
  # Arrange
  local -r image_id="test-image"
  local -r cmd="1 RUN echo hello"
  local -r cmd_body="echo hello"
  local -r exec_func="vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" '$cmd_body' \"\$port\""
  # Stubs
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "${image_id} ${cmd} RUN ${exec_func}"
  }
  # Act
  run vedv::image_builder::__layer_run "$image_id" "$cmd"
  # Assert
  assert_success
  assert_output ""
}

# Test for vedv::image_builder::__delete_invalid_layers() function
@test "vedv::image_builder::__delete_invalid_layers() Should fail With empty 'image_id'" {
  local -r image_id=""
  local -r cmds="1 RUN echo hello"

  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fail With empty 'cmds'" {
  local -r image_id="image_id"
  local -r cmds=""

  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'cmds' is required"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fail if fail to remove child containers" {
  # Arrange
  local -r image_id="image_id"
  local -r cmds="1 RUN echo hello"
  # Stubs
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
    return 1
  }
  # Act
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to remove child containers for image 'image_id'"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fail If fail to get layers ids" {
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
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to get layers ids for image 'image_id'"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fails If get first invalid positions fails" {
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
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    return 1
  }
  # Act
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to get first invalid positions between two arrays"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fails If first invalid cmd pos equals to 0" {
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
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '0|-1'
  }
  # Act
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "The first command must be valid because it's the command 'FROM'"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fails If fails to delete the first layer" {
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
  utils::get_first_invalid_positions_between_two_arrays() {
    assert_equal "$*" "arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids"
    echo '-1|1'
  }
  vedv::image_service::delete_layer() {
    assert_equal "$*" "$image_id 322"
    return 1
  }
  # Act
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to delete layer '322' for image '${image_id}'"
}

@test "vedv::image_builder::__delete_invalid_layers() Should fails If fails to restore last valid layer" {
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
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to restore last valid layer '321'"
}

@test "vedv::image_builder::__delete_invalid_layers() Should succeed" {
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
  run vedv::image_builder::__delete_invalid_layers "$image_id" "$cmds"
  # Assert
  assert_success
  assert_output '-1'
}

# Test vedv::image_builder::__build()

@test "vedv::image_builder::__build() should fail with empty 'vedvfile' argument" {
  # Arrange
  local -r vedvfile=""
  local -r image_name=""
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'vedvfile' is required"
}

@test "vedv::image_builder::__build() should fail with not existent 'vedvfile' argument" {
  # Arrange
  local -r vedvfile="123abc45fgfhzbzdf"
  local -r image_name=""
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_NOT_FOUND"
  assert_output "File '${vedvfile}' does not exist"
}

@test "vedv::image_builder::__build() Should fail to generate a random name" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name=""
  # Stub
  petname() { false; }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output 'Failed to generate a random name for the image'
}

@test "vedv::image_builder::__build() Should fail With invalid vedvfile" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_VEDV_FILE"
  assert_output "Failed to get commands from Vedvfile '${vedvfile}'"
}

@test "vedv::image_builder::__build() Should fail With missing FROM command" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "1 RUN echo hello"
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output 'There is no FROM command'
}

@test "vedv::image_builder::__build() Should fail On error getting image id from image name" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to get image id for image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail On error validating layer from" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    false
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to validate layer from for image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail to remove the image" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'invalid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "$image_id"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to remove image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail to get cmd body" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'invalid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    return 1
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "Failed to get from body from Vedvfile '${vedvfile}'"
}

@test "vedv::image_builder::__build() Should fail creating layer from" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'invalid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$vedvfile"
  }
  vedv::image_builder::__layer_from() {
    # shellcheck disable=SC2154
    assert_equal "$*" "${from_body} ${image_name}"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to create image '${image_name}'"
}

@test "vedv::image_builder::__build() Should call __layer_from with if image_id is empty" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$from_cmd"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$vedvfile"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "${from_body} ${image_name}"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to create image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail to delete invalid layers" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$vedvfile"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "${from_body} ${image_name}"
    echo "$image_id"
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "12345 123456"
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output --partial "Failed deleting invalid layers for image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail If first_invalid_layer_pos < -1 or > commands_length length" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  local -r from_cmd="1 FROM my_image"
  local -r vfile_cmds="${from_cmd}
2 RUN echo 'hello world'"
  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$vfile_cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo 'my_image'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'valid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "12345 123456"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${vfile_cmds}"
    echo -2
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_VALUE"
  assert_output --partial "Invalid first invalid layer position"

  # Stub
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${vfile_cmds}"
    echo 2
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure "$ERR_INVAL_VALUE"
  assert_output --partial "Invalid first invalid layer position"
}

@test "vedv::image_builder::__build() Should fail if first_invalid_cmd_pos = 0" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$vedvfile"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "${from_body} ${image_name}"
    echo "image-id"
  }
  vedv::image_entity::get_layers_ids() {
    assert_equal "$*" "$image_id"
    echo "12345 123456"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 0
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output --partial "The first command must be valid because it's the command 'FROM'"
}

@test "vedv::image_builder::__build() Should fails if There is no command to run" {
  skip
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"

  local -r from_cmd="1 FROM my_image"
  local -r image_id="image-id"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "$from_cmd"
    echo "$vedvfile"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "${from_body} ${image_name}"
    echo "image-id"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 4
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output ""
}

@test "vedv::image_builder::__build() Should fail starting image" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # commands without 'FROM' command
  local -r from_cmd="1 FROM my_image"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"

  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'valid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 2
  }
  vedv::image_service::start() {
    assert_equal "$*" "$image_id"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"

  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to start image '${image_name}'"
}

@test "vedv::image_builder::__build() Should fail to create layer for a command" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # commands without 'FROM' command
  local -r from_cmd="1 FROM my_image"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"

  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'valid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 3
  }
  vedv::image_service::start() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_builder::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -la /home/vedv/"
    false
  }
  vedv::image_builder::__layer_copy() {
    assert_equal "$*" "INVALID_CALL"
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"

  assert_failure "$ERR_IMAGE_BUILDER_OPERATION"
  assert_output "Failed to create layer for command '4 RUN ls -la /home/vedv/'"
}

@test "vedv::image_builder::__build() Should create layers 4 and 5 for a command" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # commands without 'FROM' command
  local -r from_cmd="1 FROM my_image"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"

  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'valid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 2
  }
  vedv::image_service::start() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_service::stop() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_builder::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -la /home/vedv/"
    echo 'layer_id_4'
  }
  vedv::image_builder::__layer_copy() {
    assert_equal "$*" "${image_id} 3 COPY home.config /home/vedv/"
    echo 'layer_id_5'
  }
  vedv::image_entity::get_vm_name() {
    assert_equal "$*" "$image_id"
    echo 'my-vm-name'
  }
  vedv::hypervisor::snapshot_restore_current() {
    assert_equal "$*" "my-vm-name"
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_success
  assert_output <<EOF
created 'layer_id_4' for command 'RUN'
created 'layer_id_5' for command 'COPY'

Build finished
image-id my-image-name
EOF
}

@test "vedv::image_builder::__build() Should fail stopping image" {
  # Arrange
  local -r vedvfile="dist/test/lib/vedv/components/image/fixtures/Vedvfile"
  local -r image_name="my-image-name"
  # commands without 'FROM' command
  local -r from_cmd="1 FROM my_image"
  local -r cmds="1 FROM /tmp/alpine-x86_64.ova
2 COPY homefs/* /home/vedv/
3 COPY home.config /home/vedv/
4 RUN ls -la /home/vedv/"

  local -r image_id="image-id"
  # Stub
  petname() { :; }
  vedv::image_vedvfile_service::get_commands() {
    assert_equal "$*" "$vedvfile"
    echo "$cmds"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "$image_name"
    echo 'image-id'
  }
  vedv::image_builder::__validate_layer_from() {
    assert_equal "$*" "${image_id} ${from_cmd}"
    echo 'valid'
  }
  vedv::image_service::child_containers_remove_all() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__layer_from() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_builder::__delete_invalid_layers() {
    assert_equal "$*" "${image_id} ${cmds}"
    echo 2
  }
  vedv::image_service::start() {
    assert_equal "$*" "$image_id"
  }
  vedv::image_builder::__layer_run() {
    assert_equal "$*" "${image_id} 4 RUN ls -la /home/vedv/"
    echo 'layer_id_4'
  }
  vedv::image_builder::__layer_copy() {
    assert_equal "$*" "${image_id} 3 COPY home.config /home/vedv/"
    echo 'layer_id_5'
  }
  vedv::image_service::stop() {
    assert_equal "$*" "$image_id"
    false
  }
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_failure
  assert_output "created layer 'layer_id_5' for command 'COPY'
created layer 'layer_id_4' for command 'RUN'
Failed to stop image 'my-image-name'"
}

@test '__restore_last_layer()' { :; }
@test '__calc_item_id_from_arr_cmds()' { :; }
@test '__calc_item_id_from_arr_layer_ids()' { :; }
@test '__call__layer_from()' { :; }
@test '__print_build_success_msg()' { :; }
@test '__stop_vm()' { :; }

# Test vedv::image_builder::build()

@test 'vedv::image_builder::build() with an empty vedvfile should return an error' {
  local -r vedvfile=''

  run vedv::image_builder::build "$vedvfile"

  assert_failure
  assert_output "Argument 'vedvfile' is required"
}

@test 'vedv::image_builder::build() with non existing vedvfile should return an error' {
  local -r vedvfile='vedfile-1234454343-abc'

  run vedv::image_builder::build "$vedvfile"

  assert_failure
  assert_output "File '${vedvfile}' does not exist"
}

@test 'vedv::image_builder::build() Should fail if image_name generation fails' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'

  petname() { false; }

  run vedv::image_builder::build "$vedvfile"

  assert_failure
  assert_output "Failed to generate a random name for the image"
}

@test 'vedv::image_builder::build() Should fail if fails to get image id' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name=''

  petname() {
    echo 'my-image-name'
  }
  vedv::image_builder::__build() {
    assert_equal "$*" "${vedvfile} ${image_name}"
    return 1
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "my-image-name"
    return 1
  }
  run vedv::image_builder::build "$vedvfile" "$image_name"

  assert_failure
  assert_output "The build proccess has failed.
Failed to get image id for image 'my-image-name'"
}

@test 'vedv::image_builder::build() Should fail if fails to stop the image vm' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name=''

  petname() {
    echo 'my-image-name'
  }
  vedv::image_builder::__build() {
    assert_equal "$*" "${vedvfile} my-image-name"
    return 1
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "my-image-name"
    echo '12345678'
  }
  vedv::image_service::stop() {
    assert_equal "$*" "12345678"
    return 1
  }
  run vedv::image_builder::build "$vedvfile" "$image_name"

  assert_failure
  assert_output "The build proccess has failed.
The image 'my-image-name' is corrupted.
Failed to stop the image 'my-image-name'.
You must stop and remove it."
}

@test 'vedv::image_builder::build() Should fail if fails to delete the image vm' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name=''

  petname() {
    echo 'my-image-name'
  }
  vedv::image_builder::__build() {
    assert_equal "$*" "${vedvfile} my-image-name"
    return 1
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "my-image-name"
    echo '12345678'
  }
  vedv::image_service::stop() {
    assert_equal "$*" "12345678"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "12345678"
    return 1
  }
  run vedv::image_builder::build "$vedvfile" "$image_name"

  assert_failure
  assert_output "The build proccess has failed.
The image 'my-image-name' is corrupted.
Failed to remove the image 'my-image-name'.
You must remove it."
}

@test 'vedv::image_builder::build() Should remove the image vm' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name=''

  petname() {
    echo 'my-image-name'
  }
  vedv::image_builder::__build() {
    assert_equal "$*" "${vedvfile} my-image-name"
    return 1
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "my-image-name"
    echo '12345678'
  }
  vedv::image_service::stop() {
    assert_equal "$*" "12345678"
  }
  vedv::image_service::remove() {
    assert_equal "$*" "12345678"
  }
  run vedv::image_builder::build "$vedvfile" "$image_name"

  assert_failure
  assert_output "The build proccess has failed.
The image 'my-image-name' is corrupted.
The image 'my-image-name' was removed."
}

@test 'vedv::image_builder::build() Should build the image' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'
  local -r image_name='my-image-name'

  petname() {
    assert_equal "" "INVALID_CALL"
  }
  vedv::image_entity::get_id_by_image_name() {
    assert_equal "$*" "my-image-name"
    echo '12345678'
  }
  vedv::image_service::stop() {
    assert_equal "$*" "12345678"
  }

  vedv::image_builder::__build() {
    return 0
    assert_equal "$*" "${vedvfile} ${image_name}"
  }
  run vedv::image_builder::build "$vedvfile" "$image_name"

  assert_success
  assert_output ""
}

# Tests for vedv::image_builder::__layer_run_calc_id()
@test "vedv::image_builder::__layer_run_calc_id(): DUMMY" {
  :
}

# Tests for vedv::image_builder::__layer_user_calc_id()
@test "vedv::image_builder::__layer_user_calc_id(): DUMMY" {
  :
}

# Tests for vedv::image_builder::__layer_user()

@test "vedv::image_builder::__layer_user() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__layer_user() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_user() Should fail If get_cmd_body fails" {
  local -r image_id="12345"
  local -r cmd="1 USER nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 USER nalyd"
    return 1
  }

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get user name from command '1 USER nalyd'"
}

@test "vedv::image_builder::__layer_user() Should fail If user_name is empty" {
  local -r image_id="12345"
  local -r cmd="1 USER"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 USER"
  }

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'user_name' must not be empty"
}

@test "vedv::image_builder::__layer_user() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 USER nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 USER nalyd"
    echo "nalyd"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 USER nalyd USER vedv::image_service::set_user '12345' 'nalyd'"
    return 1
  }

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to execute command '1 USER nalyd'"
}

@test "vedv::image_builder::__layer_user() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 USER nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 USER nalyd"
    echo "nalyd"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 USER nalyd USER vedv::image_service::set_user '12345' 'nalyd'"
  }

  run vedv::image_builder::__layer_user "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::image_builder::__layer_workdir_calc_id()
@test "vedv::image_builder::__layer_workdir_calc_id(): DUMMY" {
  :
}

# Tests for vedv::image_builder::__layer_workdir()

@test "vedv::image_builder::__layer_workdir() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}

@test "vedv::image_builder::__layer_workdir() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}

@test "vedv::image_builder::__layer_workdir() Should fail If get_cmd_body fails" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 WORKDIR /home/nalyd"
    return 1
  }

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get workdir from command '1 WORKDIR /home/nalyd'"
}

@test "vedv::image_builder::__layer_workdir() Should fail If workdir is empty" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 WORKDIR"
  }

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'workdir' must not be empty"
}

@test "vedv::image_builder::__layer_workdir() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 WORKDIR /home/nalyd"
    echo "/home/nalyd"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 WORKDIR /home/nalyd WORKDIR vedv::image_service::set_workdir '12345' '/home/nalyd' >/dev/null"
    return 1
  }

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to execute command '1 WORKDIR /home/nalyd'"
}

@test "vedv::image_builder::__layer_workdir() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 WORKDIR /home/nalyd"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 WORKDIR /home/nalyd"
    echo "/home/nalyd"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 WORKDIR /home/nalyd WORKDIR vedv::image_service::set_workdir '12345' '/home/nalyd' >/dev/null"
  }

  run vedv::image_builder::__layer_workdir "$image_id" "$cmd"

  assert_success
  assert_output ""
}

# Tests for vedv::image_builder::__layer_env_calc_id()
@test "vedv::image_builder::__layer_env_calc_id(): DUMMY" {
  :
}

# Tests for vedv::image_builder::__layer_env()
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail With empty image_id" {
  local -r image_id=""
  local -r cmd=""

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'image_id' is required"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail With empty cmd" {
  local -r image_id="12345"
  local -r cmd=""

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'cmd' is required"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail If get_cmd_body fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    return 1
  }

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to get env from command '1 ENV TEST=123'"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail If env is empty" {
  local -r image_id="12345"
  local -r cmd="1 ENV"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV"
  }

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Argument 'env' must not be empty"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail If str_encode fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    return 1
  }

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to encode command 'TEST=123'"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should fail If __layer_execute_cmd fails" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    echo "TEST=123"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 ENV TEST=123 ENV vedv::image_service::add_environment_var '12345' 'TEST=123' >/dev/null"
    return 1
  }

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_failure
  assert_output "Failed to execute command '1 ENV TEST=123'"
}
# bats test_tags=only
@test "vedv::image_builder::__layer_env() Should succeed" {
  local -r image_id="12345"
  local -r cmd="1 ENV TEST=123"

  vedv::image_vedvfile_service::get_cmd_body() {
    assert_equal "$*" "1 ENV TEST=123"
    echo "TEST=123"
  }
  utils::str_encode() {
    assert_equal "$*" "TEST=123"
    echo "TEST=123"
  }
  vedv::image_builder::__layer_execute_cmd() {
    assert_equal "$*" "12345 1 ENV TEST=123 ENV vedv::image_service::add_environment_var '12345' 'TEST=123' >/dev/null"
  }

  run vedv::image_builder::__layer_env "$image_id" "$cmd"

  assert_success
  assert_output ""
}
