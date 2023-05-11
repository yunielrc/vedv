load test_helper

setup_file() {
  vedv::image_vedvfile_service::constructor \
    "$TEST_HADOLINT_CONFIG" \
    true \
    "$TEST_BASE_VEDVFILEIGNORE" \
    "$TEST_VEDVFILEIGNORE"

  export __VEDV_IMAGE_VEDVFILE_HADOLINT_CONFIG
  export __VEDV_IMAGE_VEDVFILE_HADOLINT_ENABLED
  export __VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH
  export __VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH
}

@test "vedv::image_vedvfile_service::__are_supported_commands() Should succeed With empty 'command'" {
  local -r commands=""

  run vedv::image_vedvfile_service::__are_supported_commands "$commands"

  assert_success
  assert_output 'There are no commands for validation'
}

@test "vedv::image_vedvfile_service::__are_supported_commands() Should fail With invalid command" {
  local commands=" INVALID command
   RUN echo Hello "

  run vedv::image_vedvfile_service::__are_supported_commands "$commands"

  assert_failure 1
  assert_output "Command 'INVALID command' isn't supported, valid commands are: FROM|RUN|COPY|USER"
}

@test "vedv::image_vedvfile_service::__are_supported_commands() Should succeed With valid command" {
  local commands=" FROM alpine:latest

  RUN echo Hello "

  run vedv::image_vedvfile_service::__are_supported_commands "$commands"

  assert_success
  assert_output ''
}

@test "vedv::image_vedvfile_service::__validate_file() Should fail With nonexistent vedvfile" {

  run vedv::image_vedvfile_service::__validate_file '/a/b/c/Vedvfile'

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Invalid argument 'vedvfile', file /a/b/c/Vedvfile doesn't exist"
}

@test "vedv::image_vedvfile_service::__validate_file() Should fail With unsupported commands" {

  local -r vedvfile_invalid='dist/test/lib/vedv/components/image/fixtures/Vedvfile-invalid'

  run vedv::image_vedvfile_service::__validate_file "$vedvfile_invalid"

  assert_failure 1
  assert_output <<-'EOF'
Command 'CMD [ "/bin/ls", "-l" ]' isn't supported, valid commands are: FROM|RUN|ENV|COPY|USER|WORKDIR
EOF
}

@test "vedv::image_vedvfile_service::__validate_file() Should fail with file that does not meet hadolint validation" {
  vedv::image_vedvfile_service::__are_supported_commands() { :; }
  local -r vedvfile_invalid='dist/test/lib/vedv/components/image/fixtures/Vedvfile-invalid'

  run vedv::image_vedvfile_service::__validate_file "$vedvfile_invalid"

  assert_failure 1
  assert_output "Hadolint validation fail"
}

@test "vedv::image_vedvfile_service::__validate_file() Should succeed" {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'

  run vedv::image_vedvfile_service::__validate_file "$vedvfile"

  assert_success
  assert_output ''
}

@test 'vedv::image_vedvfile_service::get_commands(), Should throw an error With an invalid vedvfile' {
  vedv::image_vedvfile_service::__validate_file() {
    echo 'ERROR'
    false
  }
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile-invalid'

  run vedv::image_vedvfile_service::get_commands "$vedvfile"

  assert_failure "$ERR_INVAL_ARG"
  assert_output 'ERROR'
}

@test 'vedv::image_vedvfile_service::get_commands(), Should succeed With a valid Vedvfile' {
  local -r vedvfile='dist/test/lib/vedv/components/image/fixtures/Vedvfile'

  run vedv::image_vedvfile_service::get_commands "$vedvfile"

  assert_success
  assert_output <<-'EOF'
1  FROM /tmp/vedv/test/files/alpine-x86_64.ova
3  COPY homefs/* .
4  COPY home.config /home/user/
5  COPY rootfs/* /
6  RUN ls -l
EOF
}

@test "vedv::image_vedvfile_service::get_cmd_name() Should fail With empty 'cmd'" {
  run vedv::image_vedvfile_service::get_cmd_name ""

  assert_failure
  assert_output "Argument 'cmd' must not be empty"
}

@test "vedv::image_vedvfile_service::get_cmd_name() Should fail If there isn't 'cmd_name' in 'cmd'" {
  run vedv::image_vedvfile_service::get_cmd_name "echo Hello"

  assert_failure
  assert_output "Command 'echo Hello' isn't supported, valid commands are: FROM|RUN|COPY|USER"
}
# bats test_tags=only
@test "vedv::image_vedvfile_service::get_cmd_name() Should succeed With valid input" {
  run vedv::image_vedvfile_service::get_cmd_name " 1 FROM         ubuntu:latest "

  assert_success
  assert_output "FROM"
}

@test "vedv::image_vedvfile_service::get_cmd_body() Should fail With empty 'cmd'" {
  run vedv::image_vedvfile_service::get_cmd_body ""

  assert_failure "$ERR_INVAL_ARG"
  assert_output "Argument 'cmd' must not be empty"
}

@test "vedv::image_vedvfile_service::get_cmd_body() Should succeed With valid input" {
  run vedv::image_vedvfile_service::get_cmd_body "1 FROM ubuntu:latest "
  assert_success
  assert_output "ubuntu:latest"

  run vedv::image_vedvfile_service::get_cmd_body " RUN apt-get update "
  assert_success
  assert_output "apt-get update"
}

# Test for vedv:image_builder::get_joined_vedvfileignore()
# bats test_tags=only
@test 'vedv:image_builder::get_joined_vedvfileignore() should return success and write the file path to stdout' {
  local __VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH="dist/test/lib/vedv/components/image/fixtures/.vedvfileignore"

  local -r vevfileignore=$(vedv:image_vedvfile_service::get_joined_vedvfileignore)
  run cat "$vevfileignore"

  assert_success
  assert_output ".git/
.vscode/"
}
