#
# Registry Base Service
#
#

# for code completion
if false; then
  . './../../utils.bash'
  . './registry-api-client.bash'
  . './../image/image-service.bash'
fi

#
# Constructor
#
# Arguments:
#   registry_cache_dir       string    path to the registry cache directory
#   image_exported_dir       string    path to the image exported directory
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::constructor() {
  readonly __VEDV_REGISTRY_SERVICE_CACHE_DIR="$1"
  readonly __VEDV_REGISTRY_SERVICE_IMAGE_EXPORTED_DIR="$2"
}

#
# Get registry image cache dir
#
# Output:
#  Writes registry_image_cache_dir (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__get_registry_cache_dir() {
  echo "$__VEDV_REGISTRY_SERVICE_CACHE_DIR"
}

#
# Get real owner of the image in the registry
#
# Arguments:
#   image_fqn       string  e.g.: nextcloud.loc/admin@alpine/alpine-13
#                           scheme: [domain/]user@collection/image-name
#   [registry_url]  string  registry server url
#
# Output:
#  Writes image_owner (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__get_public_image_real_owner() {
  local -r image_fqn="$1"
  local -r registry_url="${2:-}"
  # validate arguments
  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  local rel_file_path
  rel_file_path="$(vedv::image_entity::get_rel_file_path_from_fqn "$image_fqn")" ||
    return $?
  readonly rel_file_path

  local -r file="/01-public-images/${rel_file_path}"

  vedv::registry_api_client::get_file_owner "$file" "$registry_url" || {
    err "Failed to get image owner for image '${image_fqn}'"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# Download an image from a registry
#
# Arguments:
#   image_fqn       string  e.g.: nextcloud.loc/admin@alpine/alpine-13
#                           scheme: [domain/]user@collection/image-name
#   [image_name]    string  image name
#   [no_cache]      bool    do not use cache when downloading the image
#
# Output:
#  Writes image name or image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::pull() {
  local -r image_fqn="$1"
  local image_name="${2:-}"
  local -r no_cache="${3:-false}"
  # validate arguments
  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"
  if [[ -n "$image_name" ]]; then
    vedv::image_entity::validate_name "$image_name" ||
      return "$?"
  fi
  readonly image_name
  #
  # refactor to use vedv::image_entity::get_url_from_fqn
  local image_registry_domain
  image_registry_domain="$(vedv::image_entity::get_domain_from_fqn "$image_fqn")" ||
    return $?
  readonly image_registry_domain

  local registry_url=''

  if [[ -n "$image_registry_domain" ]]; then
    if [[ "$image_registry_domain" =~ ^https?:// ]]; then
      registry_url="$image_registry_domain"
    else
      registry_url="https://${image_registry_domain}"
    fi
  fi
  readonly registry_url

  local registry_user
  registry_user="$(vedv::registry_api_client::get_user "$registry_url")" || {
    err "Failed to get registry user"
    return "$ERR_REGISTRY_OPERATION"
  }
  readonly registry_user

  local image_owner
  image_owner="$(vedv::image_entity::get_user_from_fqn "$image_fqn")" ||
    return $?
  readonly image_owner

  local rel_file_path
  rel_file_path="$(vedv::image_entity::get_rel_file_path_from_fqn "$image_fqn")" ||
    return $?
  readonly rel_file_path

  local remote_image_file="/00-user-images/${rel_file_path}"
  local is_public_image=false

  if [[ "$registry_user" != "$image_owner" ]]; then
    is_public_image=true
    remote_image_file="/01-public-images/${rel_file_path}"
  fi
  readonly remote_image_file is_public_image

  local -r remote_checksum_file="${remote_image_file}.sha256sum"
  # When the image is public verify that the image owner in the fqn is really
  # the owner of the image in the registry
  if [[ "$is_public_image" == true ]]; then
    local real_image_owner=''
    real_image_owner="$(vedv::registry_service::__get_public_image_real_owner "$image_fqn" "$registry_url")" || {
      err "Failed to get image owner from the registry for image '${image_fqn}'"
      return "$ERR_REGISTRY_OPERATION"
    }
    readonly real_image_owner

    if [[ "$real_image_owner" != "$image_owner" ]]; then
      err "Image '${image_fqn}' belongs to user '${real_image_owner}' and not to '${image_owner}'"
      err "For security reasons, the image can not be downloaded"
      return "$ERR_REGISTRY_OPERATION"
    fi
  fi

  local registry_domain=''
  registry_domain="$(vedv::registry_api_client::get_domain "$registry_url")" ||
    return $?
  readonly registry_domain

  local image_cache_dir
  image_cache_dir="$(vedv::registry_service::__get_registry_cache_dir)/${registry_domain}"
  readonly image_cache_dir

  if [[ ! -d "$image_cache_dir" ]]; then
    mkdir -p "$image_cache_dir" || {
      err "Failed to create image cache dir: '${image_cache_dir}'"
      return "$ERR_FAILED_CREATE_DIR"
    }
  fi

  local -r image_fqn_wo_domain="${image_fqn#"${image_registry_domain}/"}"

  local image_file
  image_file="${image_cache_dir}/$(vedv::image_entity::fqn_to_file_name "$image_fqn_wo_domain")" ||
    return $?
  readonly image_file

  local -r checksum_file="${image_file}.sha256sum"

  if [[ "$no_cache" == false && -f "$image_file" ]]; then
    echo "Image '${image_fqn}' already exists in the cache, skipping download"
  else
    # Download the image and checksum file
    vedv::registry_api_client::download_file "$remote_checksum_file" "$checksum_file" "$registry_url" || {
      err "Error downloading image checksum '${remote_checksum_file}'"
      return "$ERR_COPY_FILE"
    }

    local -r remote_image_file_basename="${remote_image_file##*/}"
    local -r image_file_basename="${image_file##*/}"
    # replace the remote image file name with the local one in
    # the checksum file
    sed -i "s/${remote_image_file_basename}/${image_file_basename}/" "$checksum_file" ||
      return $?

    vedv::registry_api_client::download_file "$remote_image_file" "$image_file" "$registry_url" || {
      err "Error downloading image file '${remote_image_file}'"
      return "$ERR_COPY_FILE"
    }
  fi
  # Check and import the image
  vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file" || {
    err "Error importing image from file: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# Upload an image to a registry
#
# Arguments:
#   image_fqn     string  e.g.: nextcloud.loc/admin@alpine/alpine-13
#                         scheme: [domain/]user@collection/image-name
#   [image_name]  string  name of the image that will be pushed to the registry
#                         if not specified, the name on fqn will be used
#
# Output:
#  Writes image name or image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::push() {
  local -r image_fqn="$1"
  local image_name="${2:-}"
  # validate arguments
  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  local fqn_image_name=''
  fqn_image_name="$(vedv::image_entity::get_name_from_fqn "$image_fqn")" ||
    return $?
  readonly fqn_image_name

  if [[ -n "$image_name" ]]; then
    vedv::image_entity::validate_name "$image_name" ||
      return "$?"
  else
    image_name="$fqn_image_name"
  fi
  readonly image_name

  local registry_url=''
  registry_url="$(vedv::image_entity::get_url_from_fqn "$image_fqn")" ||
    return $?
  readonly registry_url

  local registry_user
  registry_user="$(vedv::registry_api_client::get_user "$registry_url")" || {
    err "Failed to get registry user"
    return "$ERR_REGISTRY_OPERATION"
  }
  readonly registry_user

  local image_owner
  image_owner="$(vedv::image_entity::get_user_from_fqn "$image_fqn")" ||
    return $?
  readonly image_owner

  if [[ "$image_owner" != "$registry_user" ]]; then
    err "Image can not be uploaded, user on fqn must be '${registry_user}'"
    return "$ERR_REGISTRY_OPERATION"
  fi

  local -r tmp_dir="$__VEDV_REGISTRY_SERVICE_IMAGE_EXPORTED_DIR"

  local -r image_file="${tmp_dir}/${fqn_image_name}.ova"
  local -r checksum_file="${image_file}.sha256sum"

  vedv::image_service::export \
    "$image_name" \
    "$image_file" || {
    err "Error exporting image to file: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }

  local rel_file_path
  rel_file_path="$(vedv::image_entity::get_rel_file_path_from_fqn "$image_fqn")" ||
    return $?
  readonly rel_file_path

  local -r remote_directory="/00-user-images/${rel_file_path%/*}"
  local -r remote_image_file="/00-user-images/${rel_file_path}"
  local -r remote_checksum_file="${remote_image_file}.sha256sum"

  vedv::registry_api_client::create_directory "$remote_directory" "$registry_url" || {
    err "Error creating directory '${remote_directory}'"
    return "$ERR_REGISTRY_OPERATION"
  }

  vedv::registry_api_client::upload_file "$checksum_file" "$remote_checksum_file" "$registry_url" || {
    err "Error uploading image checksum to '${remote_checksum_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }

  vedv::registry_api_client::upload_file "$image_file" "$remote_image_file" "$registry_url" || {
    err "Error uploading image file to '${remote_image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
}
