# shellcheck disable=SC2317,SC2034,SC2031,SC2030,SC2016
load ./../test_helper

setup_file() {
  vedv::registry_nextcloud_api_client::constructor \
    "([${TEST_NC_URL}]=\"${TEST_NC_USER}:${TEST_NC_PASSWORD}\"\
  [http://nextcloud2.loc]=\"jane:jane\"\
  [http://nextcloud4.loc]=\"\")" \
    'http://nextcloud.loc'

  export __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_DICT_STR
  export __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL
  export __VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT
}

teardown() {
  # remove test directory on nextcloud-dev instance
  curl "${TEST_NC_URL}/remote.php/dav/files/admin/00-user-images/${TEST_NC_USER}@alpine-test/" \
    --fail --silent --show-error \
    --user "${TEST_NC_USER}:${TEST_NC_PASSWORD}" \
    --request DELETE || :
}

# Tests for vedv::registry_nextcloud_api_client::get_domain()
@test 'vedv::registry_nextcloud_api_client::get_domain() Should show default registry url' {

  run vedv::registry_nextcloud_api_client::get_domain

  assert_success
  assert_output 'nextcloud.loc'
}

@test 'vedv::registry_nextcloud_api_client::get_domain() Should show domain for registry url' {
  local -r registry_url='http://nextcloud2.loc'

  run vedv::registry_nextcloud_api_client::get_domain "$registry_url"

  assert_success
  assert_output 'nextcloud2.loc'
}

# Tests for vedv::registry_nextcloud_api_client::__get_credentials()
@test 'vedv::registry_nextcloud_api_client::__get_credentials() Should fail With invalid registry url' {
  local -r registry_url='http://nextcloud3.loc'

  run vedv::registry_nextcloud_api_client::__get_credentials "$registry_url"

  assert_failure
  assert_output "Registry 'http://nextcloud3.loc' not found in credentials dict"
}

@test 'vedv::registry_nextcloud_api_client::__get_credentials() Should fail With empty user' {
  local -r registry_url='http://nextcloud4.loc'

  run vedv::registry_nextcloud_api_client::__get_credentials "$registry_url"

  assert_failure
  assert_output "Empty user pass for registry 'http://nextcloud4.loc'"
}

@test 'vedv::registry_nextcloud_api_client::__get_credentials() Should show credentials for default registry url' {

  run vedv::registry_nextcloud_api_client::__get_credentials

  assert_success
  assert_output "admin:admin"
}

@test 'vedv::registry_nextcloud_api_client::__get_credentials() Should show credentials for registry url' {
  local -r registry_url='http://nextcloud2.loc'

  run vedv::registry_nextcloud_api_client::__get_credentials "$registry_url"

  assert_success
  assert_output "jane:jane"
}

# Tests for vedv::registry_nextcloud_api_client::get_user()
@test 'vedv::registry_nextcloud_api_client::get_user() Should show user for default registry url' {

  run vedv::registry_nextcloud_api_client::get_user

  assert_success
  assert_output "admin"
}

@test 'vedv::registry_nextcloud_api_client::get_user() Should show user for registry url' {
  local -r registry_url='http://nextcloud2.loc'

  run vedv::registry_nextcloud_api_client::get_user "$registry_url"

  assert_success
  assert_output "jane"
}

# Tests for vedv::registry_nextcloud_api_client::__base_url()
@test 'vedv::registry_nextcloud_api_client::__base_url() Should show base url for default registry url' {

  run vedv::registry_nextcloud_api_client::__base_url

  assert_success
  assert_output 'http://nextcloud.loc/remote.php/dav/files/admin'
}

@test 'vedv::registry_nextcloud_api_client::__base_url() Should show base url for registry url' {
  local -r registry_url='http://nextcloud2.loc'

  run vedv::registry_nextcloud_api_client::__base_url "$registry_url"

  assert_success
  assert_output 'http://nextcloud2.loc/remote.php/dav/files/jane'
}

# Tests for vedv::registry_nextcloud_api_client::get_file_owner()
@test 'vedv::registry_nextcloud_api_client::get_file_owner() Should fail With empty file path' {
  local -r file_path=''

  run vedv::registry_nextcloud_api_client::get_file_owner "$file_path"

  assert_failure
  assert_output 'File path is not specified'
}

@test 'vedv::registry_nextcloud_api_client::get_file_owner() Should fail With invalid file path' {
  local -r file_path='invalid/path'

  run vedv::registry_nextcloud_api_client::get_file_owner "$file_path"

  assert_failure
  assert_output --partial "Failed to get owner for file 'invalid/path'"
}

@test 'vedv::registry_nextcloud_api_client::get_file_owner() Should show owner admin for file' {
  local -r file_path='/00-user-images/admin@alpine/alpine-14.ova'
  local -r registry_url='http://nextcloud.loc'

  run vedv::registry_nextcloud_api_client::get_file_owner \
    "$file_path" "$registry_url"

  assert_success
  assert_output 'admin'
}

# Tests for vedv::registry_nextcloud_api_client::download_file()
@test 'vedv::registry_nextcloud_api_client::download_file() Should fail With empty file path' {
  local -r file_path=''
  local -r output_file=''

  run vedv::registry_nextcloud_api_client::download_file \
    "$file_path" "$output_file"

  assert_failure
  assert_output 'File is not specified'
}

@test 'vedv::registry_nextcloud_api_client::download_file() Should fail With empty output_file file' {
  local -r file_path='invalid/path'
  local -r output_file=''

  run vedv::registry_nextcloud_api_client::download_file \
    "$file_path" "$output_file"

  assert_failure
  assert_output 'Local file is not specified'
}

@test 'vedv::registry_nextcloud_api_client::download_file() Should fail With invalid file path' {
  local -r file_path='invalid/path'
  local -r output_file='/dev/null'

  run vedv::registry_nextcloud_api_client::download_file \
    "$file_path" "$output_file"

  assert_failure
  assert_output --partial "Failed to download file 'invalid/path'"
}

@test 'vedv::registry_nextcloud_api_client::download_file() Should fail With invalid registry url' {
  local -r file_path='invalid/path'
  local -r output_file='/dev/null'
  local -r registry_url='http://nextcloud2.loc'

  run vedv::registry_nextcloud_api_client::download_file \
    "$file_path" "$output_file" "$registry_url"

  assert_failure
  assert_output --partial "Failed to download file 'invalid/path'"
}

@test 'vedv::registry_nextcloud_api_client::download_file() Should download file' {
  local -r file_path='/00-user-images/admin@alpine/alpine-14.ova'
  local -r output_file="$(mktemp)"

  run vedv::registry_nextcloud_api_client::download_file \
    "$file_path" "$output_file"

  assert_success
  assert_output ''

  run cat "$output_file"

  assert_success
  assert_output 'alpine-14.ova'
}

# Tests for vedv::registry_nextcloud_api_client::create_directory()
@test 'vedv::registry_nextcloud_api_client::create_directory() Should fail With empty directory path' {
  local -r directory=''
  local -r registry_url=''

  run vedv::registry_nextcloud_api_client::create_directory \
    "$directory" "$registry_url"

  assert_failure
  assert_output 'Directory is not specified'
}

@test 'vedv::registry_nextcloud_api_client::create_directory() Should fail If __base_url fails' {
  local -r directory='/00-user-images/admin@alpine-test'
  local -r registry_url='http123://nextcloud.loc'

  run vedv::registry_nextcloud_api_client::create_directory \
    "$directory" "$registry_url"

  assert_failure
  assert_output "Failed to get user for registry 'http123://nextcloud.loc', on base url"
}

@test 'vedv::registry_nextcloud_api_client::create_directory() Should fail If __get_credentials fails' {
  local -r directory='/00-user-images/admin@alpine-test'
  local -r registry_url='http123://nextcloud.loc'

  vedv::registry_nextcloud_api_client::__base_url() {
    assert_equal "$*" 'http123://nextcloud.loc'
  }

  run vedv::registry_nextcloud_api_client::create_directory \
    "$directory" "$registry_url"

  assert_failure
  assert_output "Registry 'http123://nextcloud.loc' not found in credentials dict"
}

@test 'vedv::registry_nextcloud_api_client::create_directory() Should fail If request fails' {
  local -r directory='/invalid_dir/admin@alpine-test'
  local -r registry_url='http://nextcloud.loc'

  run vedv::registry_nextcloud_api_client::create_directory \
    "$directory" "$registry_url"

  assert_failure
  assert_output --partial "Failed to create directory '/invalid_dir/admin@alpine-test'"
}

@test 'vedv::registry_nextcloud_api_client::create_directory() Should succeed' {
  local -r directory='/00-user-images/admin@alpine-test'
  local -r registry_url=''

  run vedv::registry_nextcloud_api_client::create_directory \
    "$directory" "$registry_url"

  assert_success
  assert_output ''
}

# Tests for vedv::registry_nextcloud_api_client::upload_file()
@test "vedv::registry_nextcloud_api_client::upload_file() Should fail With empty file" {
  local -r file=''
  local -r remote_file=''
  local -r registry_url=''

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_failure
  assert_output 'File is not specified'
}

@test "vedv::registry_nextcloud_api_client::upload_file() Should fail With empty remote_file" {
  local -r file="$TEST_OVA_FILE"
  local -r remote_file=''
  local -r registry_url=''

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_failure
  assert_output 'Remote file is not specified'
}

@test "vedv::registry_nextcloud_api_client::upload_file() Should fail If __base_url fails" {
  local -r file="$TEST_OVA_FILE"
  local -r remote_file='/00-user-images/admin@alpine-test/alpine-14.ova'
  local -r registry_url='http123://nextcloud.loc'

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_failure
  assert_output "Failed to get user for registry 'http123://nextcloud.loc', on base url"
}

@test "vedv::registry_nextcloud_api_client::upload_file() Should fail If __get_credentials fails" {
  local -r file="$TEST_OVA_FILE"
  local -r remote_file='/00-user-images/admin@alpine-test/alpine-14.ova'
  local -r registry_url='http123://nextcloud.loc'

  vedv::registry_nextcloud_api_client::__base_url() {
    assert_equal "$*" 'http123://nextcloud.loc'
  }

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_failure
  assert_output "Registry 'http123://nextcloud.loc' not found in credentials dict"
}

@test "vedv::registry_nextcloud_api_client::upload_file() Should fail If request fails" {
  local -r file="$TEST_OVA_FILE"
  local -r remote_file='/invalid_dir/admin@alpine-test/alpine-14.ova'
  local -r registry_url=''

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_failure
  assert_output --partial "Failed to upload file to '/invalid_dir/admin@alpine-test/alpine-14.ova'"
}

@test "vedv::registry_nextcloud_api_client::upload_file() Should succeed" {
  local -r file="$TEST_OVA_FILE"
  local -r remote_file='/00-user-images/admin@alpine-test/alpine-14.ova'
  local -r registry_url=''

  vedv::registry_nextcloud_api_client::create_directory \
    '/00-user-images/admin@alpine-test'

  run vedv::registry_nextcloud_api_client::upload_file \
    "$file" "$remote_file" "$registry_url"

  assert_success
  assert_output ""
}
