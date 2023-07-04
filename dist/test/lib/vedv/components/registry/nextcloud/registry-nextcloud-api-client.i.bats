# shellcheck disable=SC2317,SC2034,SC2031,SC2030,SC2016
load ./../test_helper

setup_file() {
  nextcloud_start

  vedv::registry_nextcloud_api_client::constructor \
    "([http://nextcloud.loc]=\"admin:admin\"\
  [http://nextcloud2.loc]=\"jane:jane\"\
  [http://nextcloud4.loc]=\"\")" \
    'http://nextcloud.loc'

  export __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_DICT_STR
  export __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL
  export __VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT
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
  assert_output 'Output file is not specified'
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
