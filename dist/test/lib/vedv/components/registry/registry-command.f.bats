# shellcheck disable=SC2016,SC2317
load test_helper

teardown() {
  delete_vms_by_partial_vm_name 'alpine-14'
  delete_vms_by_partial_vm_name 'alp-14-1'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'
  # it doesn't use $REGISTRY_CACHE_DIR for avoiding
  # catastrophic deletion of files
  if [[ -d /var/tmp/vedv-dev ]]; then
    rm -rf /var/tmp/vedv-dev
  fi
  # remove test directory on nextcloud-dev instance
  curl "${TEST_NC_URL}/remote.php/dav/files/admin/00-user-images/${TEST_NC_USER}@alpine-test/" \
    --fail --silent --show-error \
    --user "${TEST_NC_USER}:${TEST_NC_PASSWORD}" \
    --request DELETE || :
}

setup_file() {
  teardown
  delete_vms_directory
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

# Tests for vedv registry push()
@test "vedv registry push ,Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv registry push $flag

    assert_success
    assert_output --partial "Usage:
vedv registry push [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv registry push, Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv registry push $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv registry push, Should fail With missing image_fqn" {
  run vedv registry push --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv registry push, Should fail With invalid image_fqn" {
  run vedv registry push 'admin/alpine-test/alpine-14'

  assert_failure
  assert_output "Invalid argument 'admin/alpine-test/alpine-14'"
}

@test "vedv registry push, Should fail With invalid image_name" {
  run vedv registry push --name '_invalid/name' 'admin@alpine-test/alpine-14'

  assert_failure
  assert_output "Invalid argument '_invalid/name'"
}

@test "vedv registry push, Should fail With invalid registry domain" {
  run vedv registry push 'nextcloud123.loc/admin@alpine-test/alpine-14'

  assert_failure
  assert_output "Registry 'https://nextcloud123.loc' not found in credentials dict
Failed to get registry user"
}

@test "vedv registry push, Should fail With invalid user on fqn" {
  run vedv registry push 'jane@alpine-test/alpine-14'

  assert_failure
  assert_output "Image can not be uploaded, user on fqn must be 'admin'"
}

@test "vedv registry push --name alpine-14, Should fail if image not exists" {
  run vedv registry push 'admin@alpine-test/alpine-14'

  assert_failure
  assert_output --partial "Error exporting image to file:"
}

@test "vedv registry push --name alpine-14, Should succeed" {
  vedv image import -n 'alpine-14' "$TEST_OVA_FILE"

  run vedv registry push 'admin@alpine-test/alpine-14'

  assert_success
  assert_output ""
}

@test "vedv registry push --name alp-14-1, Should succeed" {
  vedv image import -n 'alp-14-1' "$TEST_OVA_FILE"

  run vedv registry push --name 'alp-14-1' 'admin@alpine-test/alpine-14-1'

  assert_success
  assert_output ""
}
