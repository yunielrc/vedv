# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  vedv::registry_command::constructor 'vedv'
  export __VED_REGISTRY_COMMAND_SCRIPT_NAME
}

# Tests for vedv::registry_command::constructor()
@test "vedv::registry_command::constructor() DUMMY" {
  :
}

# Tests for vedv::registry_command::__help()
@test "vedv::registry_command::__help() DUMMY" {
  :
}

# Tests for vedv::registry_command::run_cmd()
@test "vedv::registry_command::run_cmd() DUMMY" {
  :
}

# Tests for vedv::registry_command::__pull_help()
@test "vedv::registry_command::__pull_help() DUMMY" {
  :
}

# Tests for vedv::registry_command::__pull()
@test "vedv::registry_command::__pull() Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv::registry_command::__pull $flag

    assert_success
    assert_output --partial "Usage:
vedv registry pull [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv::registry_command::__pull() Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv::registry_command::__pull $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv::registry_command::__pull() Should fail With missing image_fqn" {

  run vedv::registry_command::__pull --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv::registry_command::__pull() Should succeed" {

  vedv::registry_service::pull() {
    assert_equal "$*" "nextcloud2.loc/admin@alpine/alpine-14 my-alpine-14 false"
  }

  run vedv::registry_command::__pull --name 'my-alpine-14' 'nextcloud2.loc/admin@alpine/alpine-14'

  assert_success
  assert_output ''
}

@test "vedv::registry_command::__pull() Should succeed With no-cache" {

  vedv::registry_service::pull() {
    assert_equal "$*" "nextcloud2.loc/admin@alpine/alpine-14 my-alpine-14 true"
  }

  run vedv::registry_command::__pull --no-cache --name 'my-alpine-14' 'nextcloud2.loc/admin@alpine/alpine-14'

  assert_success
  assert_output ''
}
