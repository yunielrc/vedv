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

@test "vedv::image_command::__pull, with invalid arg throw an error" {
  run vedv::image_command::__pull 'image_file' 'invalid_arg'

  assert_failure 69
  assert_output --partial 'Invalid argument: invalid_arg'
}

@test "vedv::image_command::__pull, with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image pull IMAGE'

  run vedv::image_command::__pull -h

  assert_success
  assert_output --partial "$help_output"

  run vedv::image_command::__pull --help

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

@test "vedv::image_command::__rm(), with arg '-h|--help|help' should show help" {
  local -r help_output='vedv image rm IMAGE [IMAGE...]'

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
  assert_output "vedv::image_service::__rm ${image_name_or_id}"
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

# Tests for vedv::image_command::__build()

@test "vedv::image_command::__build() shows help" {
  # Arrange
  local expected_output="Usage:
vedv image build [FLAGS] [OPTIONS] PATH

Build an image from a Vedvfile"
  # Act
  run vedv::image_command::__build -h
  # Assert
  assert_success
  assert_output --partial "$expected_output"
  # Act
  run vedv::image_command::__build --help
  # Assert
  assert_success
  assert_output --partial "$expected_output"
}

@test "vedv::image_command::__build() builds an image from custom Vedvfile" {
  # Arrange
  local custom_vedvfile="MyVedvfile"
  # Stub
  vedv::image_service::build() {
    assert_regex "$*" '^MyVedvfile  false false\s*$'
    echo "${FUNCNAME[0]} $*"
  }
  # Act
  run vedv::image_command::__build "$custom_vedvfile"
  # Assert
  assert_success
  assert_output --regexp '^vedv::image_service::build MyVedvfile  false false\s*$'
}

@test "vedv::image_command::__build() builds an image from default Vedvfile" {
  # Stub
  vedv::image_service::build() {
    assert_regex "$*" 'Vedvfile  false\s*'
    echo "${FUNCNAME[0]} $*"
  }
  # Act
  run vedv::image_command::__build
  # Assert
  assert_success
  assert_output --regexp '^vedv::image_service::build Vedvfile  false false\s*$'
}

@test "vedv::image_command::__build() Should fails if -n argument is provided without image name" {
  # Arrange
  # Use variables for custom image name and Vedvfile name
  local custom_image_name="my-image"
  # Stub
  vedv::image_service::build() {
    assert_equal "$*" 'INVALID_CALL'
  }
  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv::image_command::__build "$arg"
    # Assert
    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv::image_command::__build() builds an image with custom name" {
  # Arrange
  # Use variables for custom image name and Vedvfile name
  local custom_image_name="my-image"
  local custom_vedvfile="MyVedvfile"
  # Stub
  vedv::image_service::build() {
    assert_regex "$*" '^MyVedvfile my-image\s* false false$'
    echo "${FUNCNAME[0]} $*"
  }
  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv::image_command::__build "$arg" "$custom_image_name" "$custom_vedvfile"
    # Assert
    assert_success
    assert_output 'vedv::image_service::build MyVedvfile my-image false false'
  done
}

@test "vedv::image_command::__build_help()" {
  :
}
