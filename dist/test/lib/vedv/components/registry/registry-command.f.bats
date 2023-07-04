# shellcheck disable=SC2016,SC2317
load test_helper

teardown() {
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'
  # it doesn't use $REGISTRY_CACHE_DIR for avoiding
  # catastrophic deletion of files
  if [[ -d /var/tmp/vedv/registry ]]; then
    rm -rf /var/tmp/vedv/registry
  fi
}

setup_file() {
  teardown
  delete_vms_directory
  nextcloud_start
}

# Tests for vedv registry help
@test "vedv registry help ,Should show help" {
  for flag in '' '-h' '--help'; do
    run vedv registry $flag

    assert_success
    assert_output --partial "Usage:
vedv registry COMMAND"
  done
}

# Tests for vedv registry pull()
@test "vedv registry pull ,Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv registry pull $flag

    assert_success
    assert_output --partial "Usage:
vedv registry pull [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv registry pull ,Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv registry pull $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv registry pull ,Should fail With missing image_fqn" {

  run vedv registry pull --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv registry pull ,Should fail with invalid image fqn" {

  run vedv registry pull --name 'my-alpine-14' 'admin_alpine/alpine-14'

  assert_failure
  assert_output "Invalid argument 'admin_alpine/alpine-14'"
}

@test "vedv registry pull ,Should fail with no existent registry domain" {

  run vedv registry pull --name 'my-alpine-14' 'nextcloud5.loc/admin@alpine/alpine-14'

  assert_failure
  assert_output "Registry 'https://nextcloud5.loc' not found in credentials dict
Failed to get registry user"
}

@test "vedv registry pull ,Should fail with down registry domain" {

  run vedv registry pull --name 'my-alpine-14' 'http://nextcloud2.loc/admin@alpine/alpine-14'

  assert_failure
  assert_output --partial "Error downloading image checksum '/00-user-images/admin@alpine/alpine-14.ova.sha256sum'"
}

@test "vedv registry pull ,Should fail with invalid image file" {

  run vedv registry pull --name 'my-alpine-14' 'admin@alpine/alpine-14'

  assert_failure
  assert_output --regexp "Error importing image from file: '.*admin@alpine__alpine-14.ova'"
}

@test "vedv registry pull ,Should fail with invalid image owner" {

  run vedv registry pull --name 'my-alpine-14' 'jane@macos/macos-monterey'

  assert_failure
  assert_output "Image 'jane@macos/macos-monterey' belongs to user 'admin' and not to 'jane'
For security reasons, the image can not be downloaded"
}

@test "vedv registry pull ,Should succeed" {
  run vedv registry pull --name 'my-alpine-13' 'admin@alpine/alpine-13'

  assert_success
  assert_output '4011175009 my-alpine-13'

  run vedv registry pull --name 'my-alpine-14' 'http://nextcloud.loc/admin@alpine/alpine-13'

  assert_success
  assert_output "Image 'http://nextcloud.loc/admin@alpine/alpine-13' already exists in the cache, skipping download
3927895028 my-alpine-14"

  run vedv registry pull --no-cache --name 'my-alpine-15' 'http://nextcloud.loc/admin@alpine/alpine-13'

  assert_success
  assert_output "3955640179 my-alpine-15"
}
