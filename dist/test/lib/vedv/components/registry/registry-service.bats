# shellcheck disable=SC2317,SC2031,SC2030
load test_helper

setup() {
  # vedv::registry_service::constructor "$(mktemp -d)"
  export __VEDV_REGISTRY_SERVICE_CACHE_DIR="$(mktemp -d)"
  export __VEDV_REGISTRY_SERVICE_IMAGE_EXPORTED_DIR="$(mktemp -d)"

  file_downloader::constructor ''
  export __VEDV_FILE_DOWNLOADER_USER_AGENT
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
  vedv::registry_service::__download_image_from_link() {
    assert_regex "$*" "/tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova /tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova"
  }
  vedv::image_service::import() {
    assert_equal "$*" "${_image_file} ${image_name} ${_checksum_file}"
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_success
  assert_output ""
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

@test "vedv::registry_service::pull() Should fail If __download_image_from_link fails" {
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
  vedv::registry_service::__download_image_from_link() {
    assert_regex "$*" "/tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova /tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova"
    return 1
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_failure
  assert_output --partial "Error downloading image from link file:"
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

  vedv::registry_service::__download_image_from_link() {
    assert_regex "$*" "/tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova /tmp/tmp.*/nextcloud2.loc/jane@macos__macos-monterey.ova"
  }

  vedv::image_service::import() {
    assert_regex "$*" "/tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova ${image_name} /tmp/.*/nextcloud2.loc/jane@macos__macos-monterey.ova.sha256sum"
  }

  run vedv::registry_service::pull \
    "$image_fqn" "$image_name" "$no_cache"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::__push()
@test "vedv::registry_service::__push() Should fail If validate_image_fqn fails" {
  local -r image_fqn=''
  local -r image_export_func=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If image_export_func is empty" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=''

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If get_name_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If get_url_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If get_user fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
  }
  vedv::image_entity::get_url_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'https://nextcloud.loc'
  }
  vedv::registry_api_client::get_user() {
    assert_equal "$*" "https://nextcloud.loc"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output "Failed to get registry user"
}

@test "vedv::registry_service::__push() Should fail If get_user_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If image_owner != registry_user" {
  local -r image_fqn='nextcloud.loc/jane@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output "Image can not be uploaded, user on fqn must be 'admin'"
}

@test "vedv::registry_service::__push() Should fail If image_export_func fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func='vedv::registry_service::image_export_func'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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
  vedv::registry_service::image_export_func() {
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output --regexp "Error exporting image to: '/tmp/tmp\..*/alpine-14.ova'"
}

@test "vedv::registry_service::__push() Should fail If get_rel_file_path_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output ""
}

@test "vedv::registry_service::__push() Should fail If create_directory fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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
  vedv::image_entity::get_rel_file_path_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'admin@alpine/alpine-14'
  }
  vedv::registry_api_client::create_directory() {
    assert_equal "$*" "/00-user-images/admin@alpine https://nextcloud.loc"
    return 1
  }

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output "Error creating directory '/00-user-images/admin@alpine'"
}

@test "vedv::registry_service::__push() Should fail If upload_file checksum_file fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output "Error uploading image checksum to '/00-user-images/admin@alpine/alpine-14.ova.sha256sum'"
}

@test "vedv::registry_service::__push() Should fail If upload_file image_file  fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_failure
  assert_output "Error uploading image file to '/00-user-images/admin@alpine/alpine-14.ova'"
}

@test "vedv::registry_service::__push() Should succeed" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_export_func=':'

  vedv::image_entity::validate_image_fqn() {
    assert_equal "$*" "$image_fqn"
  }
  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'alpine-14'
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

  run vedv::registry_service::__push \
    "$image_fqn" "$image_export_func"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::__push_image_exporter()
@test "vedv::registry_service::__push_image_exporter() Should fail If image_name is empty" {
  local -r image_name=''
  local -r image_file=''

  run vedv::registry_service::__push_image_exporter \
    "$image_name" "$image_file"

  assert_failure
  assert_output "image_name can not be empty"
}

@test "vedv::registry_service::__push_image_exporter() Should fail If image_file is empty" {
  local -r image_name='image1'
  local -r image_file=''

  run vedv::registry_service::__push_image_exporter \
    "$image_name" "$image_file"

  assert_failure
  assert_output "image_file can not be empty"
}

@test "vedv::registry_service::__push_image_exporter() Should fail If export fails" {
  local -r image_name='image1'
  local -r image_file='image1.ova'

  vedv::image_service::export() {
    assert_equal "$*" "image1 image1.ova"
    return 1
  }

  run vedv::registry_service::__push_image_exporter \
    "$image_name" "$image_file"

  assert_failure
  assert_output --partial "Error exporting image to file: "
}

@test "vedv::registry_service::__push_image_exporter() Should succeed" {
  local -r image_name='image1'
  local -r image_file='image1.ova'

  vedv::image_service::export() {
    assert_equal "$*" "image1 image1.ova"
  }

  run vedv::registry_service::__push_image_exporter \
    "$image_name" "$image_file"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::push()
@test "vedv::registry_service::push() Should fail With invalid image name" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name='/invalid/'

  run vedv::registry_service::push "$image_fqn" "$image_name"

  assert_failure
  assert_output "Invalid argument '/invalid/'"
}

@test "vedv::registry_service::push() Should fail If get_name_from_fqn fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name=''

  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    return 1
  }

  run vedv::registry_service::push "$image_fqn" "$image_name"

  assert_failure
  assert_output --partial "Failed to get image name from fqn:"
}

@test "vedv::registry_service::push() Should fail If __push fails" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name=''

  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'image1'
  }
  vedv::registry_service::__push() {
    assert_equal "$*" "${image_fqn} vedv::registry_service::__push_image_exporter 'image1' \"\$image_file\""
    return 1
  }

  run vedv::registry_service::push "$image_fqn" "$image_name"

  assert_failure
  assert_output "Error pushing image to registry"
}

@test "vedv::registry_service::push() Should succeed" {
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'
  local -r image_name=''

  vedv::image_entity::get_name_from_fqn() {
    assert_equal "$*" "$image_fqn"
    echo 'image1'
  }
  vedv::registry_service::__push() {
    assert_equal "$*" "${image_fqn} vedv::registry_service::__push_image_exporter 'image1' \"\$image_file\""
  }

  run vedv::registry_service::push "$image_fqn" "$image_name"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::__push_link_image_exporter()
@test "vedv::registry_service::__push_link_image_exporter() Should fail With empty image_file" {
  local -r image_file=""
  local -r checksum_file=""
  local -r image_address=""
  local -r checksum_address=""

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output "image_file can not be empty"
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail With empty checksum_file" {
  local -r image_file="file"
  local -r checksum_file=""
  local -r image_address=""
  local -r checksum_address=""

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output "checksum_file can not be empty"
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail With invalid image_address" {
  local -r image_file="file"
  local -r checksum_file="file.sha256sum"
  local -r image_address="invalid"
  local -r checksum_address=""

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output "image_address is not valid"
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail With invalid checksum_address" {
  local -r image_file="file"
  local -r checksum_file="file.sha256sum"
  local -r image_address="http://registry.get/image1"
  local -r checksum_address="invalid"

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output "checksum_address is not valid"
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail If creating image link fails" {
  local -r image_file="$(mktemp)"
  local -r checksum_file="file.sha256sum"
  local -r image_address="http://registry.get/image1"
  local -r checksum_address="http://registry.get/image1.sha256sum"

  chmod -w "$image_file"

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output --partial "Error creating image link:"
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail If download_file fails" {
  local -r image_file="$(mktemp)"
  local -r checksum_file="file.sha256sum"
  local -r image_address="http://registry.get/image1"
  local -r checksum_address="http://registry.get/image1.sha256sum"

  file_downloader::any_download() {
    assert_equal "$*" "${checksum_address} ${checksum_file}"
    return 1
  }

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output --partial "Error downloading checksum from address: "
}

@test "vedv::registry_service::__push_link_image_exporter() Should fail If sed fails" {
  local -r image_file="$(mktemp)"
  local -r checksum_file="/tmp/vedv/fileabc123456.sha256sum"
  local -r image_address="http://registry.get/image1"
  local -r checksum_address="http://registry.get/image1.sha256sum"

  file_downloader::any_download() {
    assert_equal "$*" "${checksum_address} ${checksum_file}"
  }

  run vedv::registry_service::__push_link_image_exporter \
    "$image_file" "$checksum_file" "$image_address" "$checksum_address"

  assert_failure
  assert_output --partial "Error updating checksum file: "
}

# Tests for vedv::registry_service::push_link()
@test "vedv::registry_service::push_link() Should fail With invalid image_address" {
  local -r image_address='invalid'
  local -r checksum_address=''
  local -r image_fqn=''

  run vedv::registry_service::push_link \
    "$image_address" "$checksum_address" "$image_fqn"

  assert_failure
  assert_output "image_address is not valid"
}

@test "vedv::registry_service::push_link() Should fail With invalid checksum_address" {
  local -r image_address='http://registry.get/image1'
  local -r checksum_address='invalid'
  local -r image_fqn=''

  run vedv::registry_service::push_link \
    "$image_address" "$checksum_address" "$image_fqn"

  assert_failure
  assert_output "checksum_address is not valid"
}

@test "vedv::registry_service::push_link() Should fail If push fails" {
  local -r image_address='http://registry.get/image1'
  local -r checksum_address='http://registry.get/image1.sha256sum'
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'

  vedv::registry_service::__push() {
    assert_equal "$*" "${image_fqn} vedv::registry_service::__push_link_image_exporter \"\$image_file\" \"\$checksum_file\" '${image_address}' '${checksum_address}'"
    return 1
  }

  run vedv::registry_service::push_link \
    "$image_address" "$checksum_address" "$image_fqn"

  assert_failure
  assert_output "Error pushing image link to registry"
}

@test "vedv::registry_service::push_link() Should succeed" {
  local -r image_address='http://registry.get/image1'
  local -r checksum_address='http://registry.get/image1.sha256sum'
  local -r image_fqn='nextcloud.loc/admin@alpine/alpine-14'

  vedv::registry_service::__push() {
    assert_equal "$*" "${image_fqn} vedv::registry_service::__push_link_image_exporter \"\$image_file\" \"\$checksum_file\" '${image_address}' '${checksum_address}'"
  }

  run vedv::registry_service::push_link \
    "$image_address" "$checksum_address" "$image_fqn"

  assert_success
  assert_output ""
}

# Tests for vedv::registry_service::cache_clean()
@test "vedv::registry_service::cache_clean() Should succeed" {
  vedv::registry_service::__get_registry_cache_dir() {
    mktemp -d
  }

  run vedv::registry_service::cache_clean

  assert_success
  assert_output 'space_freed: 0'
}

# Tests for vedv::registry_service::__download_image_from_link()
@test "vedv::registry_service::__download_image_from_link() Should faild If image_file not exists" {
  local -r image_file=''
  local -r downloaded_image_file=''

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_failure
  assert_output "image_file does not exist"
}
@test "vedv::registry_service::__download_image_from_link() Should faild If downloaded_image_file is empty" {
  local -r image_file="$TEST_OVA_FILE"
  local -r downloaded_image_file=''

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_failure
  assert_output "downloaded_image_file is empty"
}

@test "vedv::registry_service::__download_image_from_link() Should faild If du fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r downloaded_image_file="$(mktemp)"

  awk() {
    if [[ ! -t 0 ]]; then
      if [[ "$(cat -)" == *"$TEST_OVA_FILE" ]]; then
        return 1
      fi
      cat - | awk
    fi
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_failure
  assert_output "Failed to get image file size: '${TEST_OVA_FILE}'"
}

@test "vedv::registry_service::__download_image_from_link() Should faild If mv fails" {
  local -r image_file="$TEST_OVA_FILE"
  local -r downloaded_image_file="$(mktemp)"

  mv() {
    if [[ "$*" == "${image_file} ${downloaded_image_file}" ]]; then
      return 1
    fi
    mv "$@"
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_failure
  assert_output --partial "Failed to move image file:"
}

@test "vedv::registry_service::__download_image_from_link() Should succeed if image is not a link" {
  local -r image_file="$TEST_OVA_FILE"
  local -r downloaded_image_file="$(mktemp)"

  mv() {
    if [[ "$*" != "${image_file} ${downloaded_image_file}" ]]; then
      mv "$@"
    fi
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_success
  assert_output ''
}

@test "vedv::registry_service::__download_image_from_link() Should succeed if image is not a link and src = dest" {
  local -r image_file="$TEST_OVA_FILE"
  local -r downloaded_image_file="$TEST_OVA_FILE"

  mv() {
    assert_equal "$*" "INVALID_CALL"
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_success
  assert_output ''
}

@test "vedv::registry_service::__download_image_from_link() Should fail If download_file fails" {
  local -r image_file="$(mktemp)"
  local -r downloaded_image_file="$(mktemp)"

  echo 'http://get.file/image.ova' >"$image_file"

  mv() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::any_download() {
    assert_equal "$*" "http://get.file/image.ova ${downloaded_image_file}"
    return 1
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_failure
  assert_output "Error downloading image from address: 'http://get.file/image.ova'"
}

@test "vedv::registry_service::__download_image_from_link() Should succeed" {
  local -r image_file="$(mktemp)"
  local -r downloaded_image_file="$(mktemp)"

  echo 'http://get.file/image.ova' >"$image_file"

  mv() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::any_download() {
    assert_equal "$*" "http://get.file/image.ova ${downloaded_image_file}"
  }

  run vedv::registry_service::__download_image_from_link \
    "$image_file" "$downloaded_image_file"

  assert_success
  assert_output ""
}
