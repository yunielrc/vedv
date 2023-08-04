# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  vedv::builder_command::constructor 'vedv'
  export __VED_BUILDER_COMMAND_SCRIPT_NAME
}

@test "vedv::builder_command::constructor() should succeed" {
  :
}

# Tests for vedv::builder_command::run_cmd()
@test "vedv::builder_command::run_cmd, with invalid arg throw an error" {
  run vedv::builder_command::run_cmd invalid_cmd

  assert_failure 69
  assert_output --partial 'Invalid parameter: invalid_cmd'
}

@test "vedv::builder_command::run_cmd, with arg '-h|--help|help' should show help" {
  local -r help_output='vedv builder COMMAND'

  run vedv::builder_command::run_cmd -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::builder_command::run_cmd --help

  assert_success
  assert_output --partial "$help_output"

  run vedv::builder_command::run_cmd help

  assert_success
  assert_output --partial "$help_output"
}

@test "vedv::builder_command::run_cmd, with arg 'build' should build an image" {
  vedv::builder_command::__build() { echo "build image: ${1}"; }

  run vedv::builder_command::run_cmd build image_file

  assert_success
  assert_output 'build image: image_file'
}

# Tests for vedv::builder_command::__build()

@test "vedv::builder_command::__build() shows help" {
  # Arrange
  local expected_output="Usage:
vedv builder build [FLAGS] [OPTIONS] VEDVFILE

Build an image from a Vedvfile"
  # Act
  run vedv::builder_command::__build -h
  # Assert
  assert_success
  assert_output --partial "$expected_output"
  # Act
  run vedv::builder_command::__build --help
  # Assert
  assert_success
  assert_output --partial "$expected_output"
}

@test "vedv::builder_command::__build() builds an image from custom Vedvfile" {
  # Arrange
  local custom_vedvfile="MyVedvfile"
  # Stub
  vedv::builder_service::build() {
    assert_regex "$*" '^MyVedvfile  false false\s*$'
    echo "${FUNCNAME[0]} $*"
  }
  # Act
  run vedv::builder_command::__build "$custom_vedvfile"
  # Assert
  assert_success
  assert_output --regexp '^vedv::builder_service::build MyVedvfile  false false\s*$'
}

@test "vedv::builder_command::__build() builds an image from default Vedvfile" {
  # Stub
  vedv::builder_service::build() {
    assert_regex "$*" 'Vedvfile  false\s*'
    echo "${FUNCNAME[0]} $*"
  }
  # Act
  run vedv::builder_command::__build
  # Assert
  assert_success
  assert_output --regexp '^vedv::builder_service::build Vedvfile  false false\s*$'
}

@test "vedv::builder_command::__build() Should fails if -n argument is provided without image name" {
  # Arrange
  # Use variables for custom image name and Vedvfile name
  local custom_image_name="my-image"
  # Stub
  vedv::builder_service::build() {
    assert_equal "$*" 'INVALID_CALL'
  }
  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv::builder_command::__build "$arg"
    # Assert
    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv::builder_command::__build() builds an image with custom name" {
  # Arrange
  # Use variables for custom image name and Vedvfile name
  local custom_image_name="my-image"
  local custom_vedvfile="MyVedvfile"
  # Stub
  vedv::builder_service::build() {
    assert_equal "$*" 'MyVedvfile my-image false false '
  }
  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv::builder_command::__build "$arg" "$custom_image_name" "$custom_vedvfile"
    # Assert
    assert_success
    assert_output ''
  done
}

@test "vedv::builder_command::__build() Should succeed" {
  # Arrange
  # Use variables for custom image name and Vedvfile name
  local vedvfile="MyVedvfile"
  local image_name="my-image"
  # Stub
  vedv::builder_service::build() {
    assert_equal "$*" 'MyVedvfile my-image true true true'
  }
  # Act
  run vedv::builder_command::__build \
    --no-wait \
    --force \
    --no-cache \
    --name "$image_name" \
    "$vedvfile"
  # Assert
  assert_success
  assert_output ''
}

@test "vedv::builder_command::__build_help()" {
  :
}
