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
    --request DELETE &>/dev/null || :

  # remove registry cache files
  if [[ -d "$REGISTRY_CACHE_DIR" ]]; then
    find "$REGISTRY_CACHE_DIR" -type f \
      \( -name '*.ova' -o -name '*.ova.sha256sum' \) -delete
  fi
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
  assert_output --partial "Error downloading image from link file:"
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

@test "vedv registry pull ,Should succeed from link" {
  run vedv registry pull --name 'my-alpine-15' 'admin@alpine/alpine-15'

  assert_success
  assert_output '3955640179 my-alpine-15'
}

# Tests for vedv registry push
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
  assert_output --partial "Invalid argument 'admin/alpine-test/alpine-14'"
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
Failed to get registry user
Error pushing image to registry"
}

@test "vedv registry push, Should fail With invalid user on fqn" {
  run vedv registry push 'jane@alpine-test/alpine-14'

  assert_failure
  assert_output "Image can not be uploaded, user on fqn must be 'admin'
Error pushing image to registry"
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

  run vedv registry pull --name 'alp-14-2' 'admin@alpine-test/alpine-14-1'

  assert_success
  assert_output "4258011170 alp-14-2"
}

# Tests for vedv registry push-link

@test "vedv registry push-link,  Should show help" {
  for flag in '' '-h' '--help'; do
    run vedv registry push-link $flag

    assert_success
    assert_output --partial "Usage:
vedv registry push-link [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv registry push-link,  Should fail With missing image_url arg" {
  run vedv registry push-link --image-url

  assert_failure
  assert_output --partial "No image_url argument"
}

@test "vedv registry push-link,  Should fail Without checksum_url" {
  run vedv registry push-link --image-url "$TEST_OVA_URL"

  assert_failure
  assert_output --partial "No checksum_url specified"
}

@test "vedv registry push-link,  Should fail With missing checksum_url arg" {
  run vedv registry push-link \
    --image-url "$TEST_OVA_URL" --checksum-url

  assert_failure
  assert_output --partial "No checksum_url argument"
}

@test "vedv registry push-link,  Should fail With missing image_fqn" {

  run vedv registry push-link \
    --image-url "$TEST_OVA_URL" --checksum-url "$TEST_OVA_CHECKSUM_URL"

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv registry push-link --image-url, Should push an image link" {

  run vedv registry push-link \
    --image-url "$TEST_OVA_URL" \
    --checksum-url "$TEST_OVA_CHECKSUM_URL" \
    'admin@alpine-test/alpine-14-link'

  assert_success
  assert_output ""

  run vedv registry pull --name 'alp-14-1' 'admin@alpine-test/alpine-14-link'

  assert_success
  assert_output "4289064363 alp-14-1"
}

# Tests for vedv registry cache-clean
@test "vedv registry cache-clean, Should show help" {

  for flag in '-h' '--help'; do
    run vedv registry cache-clean "$flag"

    assert_success
    assert_output --partial "Usage:
vedv registry cache-clean"
  done
}

@test "vedv registry cache-clean, Should succeed" {
  vedv registry pull --name 'my-alpine-13' 'admin@alpine/alpine-13' &>/dev/null

  run vedv registry cache-clean

  assert_success
  assert_output --regexp '^space_freed: [[:digit:]]+M$'

  run_wrapper() {
    du -sh "$REGISTRY_CACHE_DIR" | awk '{print $1}'
  }

  run run_wrapper

  assert_success
  assert_output --regexp '^([[:digit:]]|\.)+K$'
}
