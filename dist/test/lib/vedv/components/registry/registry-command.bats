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

# Tests for vedv::registry_command::__push()
@test "vedv::registry_command::__push() Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv::registry_command::__push $flag

    assert_success
    assert_output --partial "Usage:
vedv registry push [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv::registry_command::__push() Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv::registry_command::__push $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv::registry_command::__push() Should fail With missing image_fqn" {
  run vedv::registry_command::__push --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv::registry_command::__push() Should succeed" {
  vedv::registry_service::push() {
    assert_equal "$*" "admin@alpine-test/alpine-14 "
  }

  run vedv::registry_command::__push 'admin@alpine-test/alpine-14'

  assert_success
  assert_output ""
}

@test "vedv::registry_command::__push() Should succeed With name" {
  vedv::registry_service::push() {
    assert_equal "$*" "admin@alpine-test/alpine-14-1 alp-14-1"
  }

  run vedv::registry_command::__push --name 'alp-14-1' 'admin@alpine-test/alpine-14-1'

  assert_success
  assert_output ""
}