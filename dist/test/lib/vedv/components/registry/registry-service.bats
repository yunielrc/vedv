# shellcheck disable=SC2317,SC2031,SC2030
load test_helper

setup() {
  # vedv::registry_service::constructor "$(mktemp -d)"
  export __VEDV_REGISTRY_SERVICE_CACHE_DIR="$(mktemp -d)"
  export __VEDV_REGISTRY_SERVICE_IMAGE_EXPORTED_DIR="$(mktemp -d)"
}
# teardown() {
#   rm -rf "${__VEDV_REGISTRY_SERVICE_CACHE_DIR}"
# }

# Tests for vedv::registry_service::__get_registry_cache_dir()
@test "vedv::registry_service::__get_registry_cache_dir() Should output image cache dir" {
  local -r __VEDV_REGISTRY_SERVICE_CACHE_DIR='/tmp/cache-dir'

  run vedv::registry_service::__get_registry_cache_dir

  assert_success
  assert_output "$__VEDV_REGISTRY_SERVICE_CACHE_DIR"
}

# Tests for vedv::registry_service::__get_public_image_real_owner()
@test "vedv::registry_service::__get_public_image_real_owner() Should fail if get_file_owner fails" {
  local -r image_fqn='admin@alpine/alpine-13'
  local -r registry_url=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-13.ova'
  }
  vedv::registry_api_client::get_file_owner() {
    assert_equal "$*" "/01-public-images/admin@alpine/alpine-13.ova ${registry_url}"
    return 1
  }

  run vedv::registry_service::__get_public_image_real_owner \
    "${image_fqn}" "${registry_url}"

  assert_failure
  assert_output "Failed to get image owner for image 'admin@alpine/alpine-13'"
}

@test "vedv::registry_service::__get_public_image_real_owner() Should succeed if get_file_owner succeeds" {
  local -r image_fqn='admin@alpine/alpine-13'
  local -r registry_url='http://nextcloud.loc'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-13.ova'
  }
  vedv::registry_api_client::get_file_owner() {
    assert_equal "$*" "/01-public-images/admin@alpine/alpine-13.ova ${registry_url}"
    echo admin
  }

  run vedv::registry_service::__get_public_image_real_owner \
    "${image_fqn}" "${registry_url}"

  assert_success
  assert_output 'admin'
}

# Tests for vedv::registry_service::pull()
@test "vedv::registry_service::pull() Should fail If validate_image_fqn fails" {
  local -r image_fqn='invalid'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::pull() Should fail If validate_name fails" {
  local -r image_fqn='admin@alpine/alpine-13'
  local -r image_name='invalid'
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
    return 1
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::pull() Should fail If registry_api_client::get_user fails" {
  local -r image_fqn='nextcloud2.loc/admin@alpine/alpine-13'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_domain_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    return 1
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Failed to get registry user"
}

@test "vedv::registry_service::pull() Should fail If __get_public_image_real_owner fails" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_domain_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane'
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane@macos/macos-monterey.ova'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    return 1
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Failed to get image owner from the registry for image 'nextcloud2.loc/jane@macos/macos-monterey'"
}

@test "vedv::registry_service::pull() Should fail If real_image_owner != image_owner" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_domain_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane'
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane@macos/macos-monterey.ova'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jone'
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Image 'nextcloud2.loc/jane@macos/macos-monterey' belongs to user 'jone' and not to 'jane'
For security reasons, the image can not be downloaded"
}

@test "vedv::registry_service::pull() Should fail If mkdir for image cache fails" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::image_entity::get_domain_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane'
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane@macos/macos-monterey.ova'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jane'
  }
  vedv::registry_api_client::get_domain() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'nextcloud2.loc'
  }
  vedv::registry_service::__get_registry_cache_dir() {
    echo '/tmp/image-cache'
  }

  __run_wrapper() (
    mkdir() {
      assert_equal "$*" "-p /tmp/image-cache/nextcloud2.loc"
      return 1
    }
    vedv::registry_service::pull "$@"
  )

  run __run_wrapper \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Failed to create image cache dir: '/tmp/image-cache/nextcloud2.loc'"
}

@test "vedv::registry_service::pull() Should succeed If file is cached" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jane'
  }
  vedv::registry_api_client::get_domain() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'nextcloud2.loc'
  }
  local -r cache_dir="$__VEDV_REGISTRY_SERVICE_CACHE_DIR"
  local -r _image_file="${cache_dir}/nextcloud2.loc/jane@macos__macos-monterey.ova"
  local -r _checksum_file="${_image_file}.sha256sum"

  mkdir() {
    command mkdir "$@"

    if [[ "$*" == "-p ${cache_dir}/nextcloud2.loc" ]]; then
      touch "$_image_file"
    fi
  }

  vedv::image_service::import() {
    assert_equal "$*" "${_image_file} ${image_name} ${_checksum_file}"
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_success
  assert_output "Image 'nextcloud2.loc/jane@macos/macos-monterey' already exists in the cache, skipping download"
}

@test "vedv::registry_service::pull() Should fail if download_file fails downloading checksum file" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jane'
  }
  vedv::registry_api_client::get_domain() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::download_file() {
    if [[ "$1" == *"macos-monterey.ova.sha256sum" ]]; then
      assert_regex "$*" "/01-public-images/jane@macos/macos-monterey.ova.sha256sum /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova.sha256sum https://nextcloud2.loc"
      return 1
    fi
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Error downloading image checksum '/01-public-images/jane@macos/macos-monterey.ova.sha256sum'"
}

@test "vedv::registry_service::pull() Should fail if download_file fails downloading image file" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jane'
  }
  vedv::registry_api_client::get_domain() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::download_file() {
    if [[ "$1" == *"macos-monterey.ova.sha256sum" ]]; then
      assert_regex "$*" "/01-public-images/jane@macos/macos-monterey.ova.sha256sum /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova.sha256sum https://nextcloud2.loc"
      touch "$2"
      return 0
    fi
    if [[ "$1" == *"macos-monterey.ova" ]]; then
      assert_regex "$*" "/01-public-images/jane@macos/macos-monterey.ova /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova https://nextcloud2.loc"
      return 1
    fi
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output "Error downloading image file '/01-public-images/jane@macos/macos-monterey.ova'"
}

@test "vedv::registry_service::pull() Should succeed" {
  local -r image_fqn='nextcloud2.loc/jane@macos/macos-monterey'
  local -r image_name=''
  local -r no_cache=''

  vedv::image_entity::validate_name() {
    assert_equal "$*" "INVALID_CALL"
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'admin'
  }
  vedv::registry_service::__get_public_image_real_owner() {
    assert_equal "$*" "${image_fqn} https://nextcloud2.loc"
    echo 'jane'
  }
  vedv::registry_api_client::get_domain() {
    assert_equal "$*" "https://nextcloud2.loc"
    echo 'nextcloud2.loc'
  }
  vedv::registry_api_client::download_file() {
    if [[ "$1" == *"macos-monterey.ova.sha256sum" ]]; then
      assert_regex "$*" "/01-public-images/jane@macos/macos-monterey.ova.sha256sum /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova.sha256sum https://nextcloud2.loc"
      touch "$2"
      return 0
    fi
    if [[ "$1" == *"macos-monterey.ova" ]]; then
      assert_regex "$*" "/01-public-images/jane@macos/macos-monterey.ova /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova https://nextcloud2.loc"
      return 0
    fi
  }
  vedv::image_service::import() {
    assert_regex "$*" "/tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova ${image_name} /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova.sha256sum"
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::push()
@test "vedv::registry_service::push() Should fail If validate_image_fqn fails" {
  local -r image_fqn=''
  local -r image_name=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If get_name_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If validate_name fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='_invalid_name'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If get_url_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If get_user fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output "Failed to get registry user"
}

@test "vedv::registry_service::push() Should fail If get_user_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If image_owner != registry_user" {
  local -r image_fqn='nextcloud.loc/jane@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'jane'
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output "Image can not be uploaded, user on fqn must be 'admin'"
}

@test "vedv::registry_service::push() Should fail If export fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output --regexp "Error exporting image to file: '/tmp/tmp\..*/alpine-14.ova'"
}

@test "vedv::registry_service::push() Should fail If get_rel_file_path_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::push() Should fail If create_directory fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-14'
  }
  vedv::registry_api_client::create_directory() {
    assert_equal "$*" "/00-user-images/admin@alpine https://nextcloud.loc"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output "Error creating directory '/00-user-images/admin@alpine'"
}

@test "vedv::registry_service::push() Should fail If upload_file checksum_file fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-14.ova'
  }
  vedv::registry_api_client::create_directory() {
    assert_equal "$*" "/00-user-images/admin@alpine https://nextcloud.loc"
  }
  vedv::registry_api_client::upload_file() {
    assert_regex "$*" "/tmp/tmp\..*/alpine-14.ova.sha256sum /00-user-images/admin@alpine/alpine-14.ova.sha256sum https://nextcloud.loc"
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output "Error uploading image checksum to '/00-user-images/admin@alpine/alpine-14.ova.sha256sum'"
}

@test "vedv::registry_service::push() Should fail If upload_file image_file  fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-14.ova'
  }
  vedv::registry_api_client::create_directory() {
    assert_equal "$*" "/00-user-images/admin@alpine https://nextcloud.loc"
  }
  vedv::registry_api_client::upload_file() {
    if [[ "$*" == "/tmp/tmp."*"/alpine-14.ova /00-user-images/admin@alpine/alpine-14.ova https://nextcloud.loc" ]]; then
      return 1
    fi
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_failure
  assert_output "Error uploading image file to '/00-user-images/admin@alpine/alpine-14.ova'"
}

@test "vedv::registry_service::push() Should succeed" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='alpine'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::validate_name() {
    assert_equal "$*" "$image_name"
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    echo 'admin'
  }
  vedv::image_entity::get_user_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin'
  }
  vedv::image_service::export() {
    assert_regex "$*" "${image_name} /tmp/tmp\..*/alpine-14.ova"
  }
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-14.ova'
  }
  vedv::registry_api_client::create_directory() {
    assert_equal "$*" "/00-user-images/admin@alpine https://nextcloud.loc"
  }
  vedv::registry_api_client::upload_file() {
    if [[ "$*" == "/tmp/tmp."*"/alpine-14.ova /00-user-images/admin@alpine/alpine-14.ova https://nextcloud.loc" ]]; then
      return 0
    fi
    if [[ "$*" == "/tmp/tmp."*"/alpine-14.ova.sha256sum /00-user-images/admin@alpine/alpine-14.ova.sha256sum https://nextcloud.loc" ]]; then
      return 0
    fi
    return 1
  }

  run vedv::registry_service::push \
    "$image_fqn" "$image_name"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::cache_clean()
@test "vedv::registry_service::cache_clean() Should fail If get_domain fails" {
  vedv::registry_service::__get_registry_cache_dir() {
    mktemp -d
  }

  run vedv::registry_service::cache_clean

  assert_success
  assert_output '0'
}
