# shellcheck disable=SC2016
load test_helper

setup_file() {
  delete_vms_directory
  export VED_HADOLINT_CONFIG="$TEST_HADOLINT_CONFIG"
  VEDV_HADOLINT_ENABLED=false
  export VEDV_HADOLINT_ENABLED
}

teardown() {
  delete_vms_by_partial_vm_name 'image123'
  delete_vms_by_partial_vm_name 'image:alpine-x86_64'
  delete_vms_by_partial_vm_name 'image-cache|'
}

# Tests for 'vedv image pull'
@test "vedv image pull, Should show help" {

  run vedv image pull

  assert_success
  assert_output "Usage:
vedv image pull IMAGE

Pull an image or a repository from a registry"
}

@test "vedv image pull -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image pull "$arg"

    assert_success
    assert_output "Usage:
vedv image pull IMAGE

Pull an image or a repository from a registry"
  done
}

@test "vedv image pull, Should pull the image" {

  run vedv image pull "$TEST_OVA_FILE"

  assert_success
  assert_output 'alpine-x86_64'
}

@test "vedv image pull, Should show error with invalid argument" {

  run vedv image pull "$TEST_OVA_FILE" 'invalid_arg'

  assert_failure "$ERR_INVAL_ARG"
  assert_output 'Invalid argument: invalid_arg

Usage:
vedv image pull IMAGE

Pull an image or a repository from a registry'
}

# Tests for 'vedv image list'
@test "vedv image list --help, Should show list help" {
  for arg in '-h' '--help'; do
    run vedv image list "$arg"

    assert_success
    assert_output "Usage:
vedv image ls

List images

Aliases:
  ls, list"
  done
}

@test "vedv image list, Should list nothing" {

  run vedv image list

  assert_success
  assert_output ''
}

@test "vedv image list, Should list images" {

  vedv image pull "$TEST_OVA_FILE"

  run vedv image list

  assert_success
  assert_output --regexp '^[[:digit:]]+ alpine-x86_64'
}

# Tests for 'vedv image rm'
@test "vedv image rm -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image rm "$arg"

    assert_success
    assert_output "Usage:
vedv image rm IMAGE [IMAGE...]

Remove one or more images"
  done
}

@test "vedv image rm, Should remove the image" {

  vedv image pull "$TEST_OVA_FILE"
  run vedv image rm 'alpine-x86_64'

  assert_success
  assert_output --regexp '^[0-9]+\s*$'
}

@test "vedv image rm, Should do nothing without passing an image" {

  vedv image pull "$TEST_OVA_FILE"
  run vedv image rm

  assert_success
  assert_output 'Usage:
vedv image rm IMAGE [IMAGE...]

Remove one or more images'
}

# Tests for 'vedv image remove-cache'
@test "vedv image remove-cache -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image remove-cache "$arg"

    assert_success
    assert_output "Usage:
vedv image remove-cache

Remove unused cache images"
  done
}

@test "vedv image remove-cache, Should remove unused caches" {

  vedv image pull "$TEST_OVA_FILE"

  run vedv image remove-cache
  assert_success
  assert_output ''

  vedv image rm 'alpine-x86_64'

  run vedv image remove-cache
  assert_success
  assert_output --regexp '^[0-9]{10,11}\s$'
}

# Tests for 'vedv image build'
@test "vedv image build -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image build "$arg"

    assert_success
    assert_output "Usage:
vedv image build [OPTIONS] [PATH]

Build an image from a Vedvfile

Flags:
  -h, --help       show the help
  --force          force the build removing the image containers

Options:
  -n, --name, -t   image name"
  done
}

@test "vedv image build -n , Should fail if -n is passed without value" {

  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv image build "$arg"
    # Assert
    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv image build, Should build the image" {
  cd "${BATS_TEST_DIRNAME}/fixtures/vedvfiles"

  run vedv image build -t 'image123'

  assert_success
  assert_output --regexp "
created layer '.*' for command 'FROM'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}

@test "vedv image build, Should build the image with USER" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./Vedvfile5

  assert_success
  assert_output --regexp "
created layer '.*' for command 'FROM'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}
