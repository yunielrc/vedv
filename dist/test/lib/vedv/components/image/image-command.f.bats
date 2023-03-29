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

@test "vedv image build -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image build "$arg"

    assert_success
    assert_output <<-EOF
Usage:
vedv image build [OPTIONS] [PATH]

Build an image from a Vedvfile

Options:
  -n, --name, -t   image name
EOF
  done
}

@test "vedv image build -n , Should fail if -n is passed without value" {

  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv image build "$arg"
    # Assert
    assert_failure
    assert_output --partial "Missing argument for option '${arg}'"
  done
}
# bats test_tags=only
@test "vedv image build, Should build the image" {
  cd "${BATS_TEST_DIRNAME}/fixtures/vedvfiles"

  run vedv image build -t 'image123'

  assert_success
  assert_output --regexp "
created layer '.*' for command 'FROM'
Waiting for VM \"image:image123\|crc:.*\|\" to power on...
VM \"image:image123\|crc:.*\|\" has been successfully started.
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}
