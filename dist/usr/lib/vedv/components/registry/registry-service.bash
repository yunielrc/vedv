#
# Registry Base Service
#
#

# for code completion
if false; then
  . './../../utils.bash'
  . './../../file-downloader.bash'
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
# Create registry directory structure
#
# Arguments:
#   [registry_url]  string  registry server url
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__create_registry_dir_structure() {
  local -r registry_url="$1"

  vedv::registry_api_client::create_directory '/00-user-images' "$registry_url" || {
    err "Error creating directory '/00-user-images'"
    return "$ERR_REGISTRY_OPERATION"
  }
  vedv::registry_api_client::create_directory '/01-public-images' "$registry_url" || {
    err "Error creating directory '/01-public-images'"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# Download an image if it is a link.
# A link is a text file that only contains the url to the image.
#
# Arguments:
#   image_file              string  path to the image file
#   downloaded_image_file   string  path to the downloaded image file
#
# Output:
#  Writes error message to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__download_image_from_link() {
  local -r image_file="$1"
  local -r downloaded_image_file="$2"
  # validate arguments
  if [[ ! -f "$image_file" ]]; then
    err "image_file does not exist"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$downloaded_image_file" ]]; then
    err "downloaded_image_file is empty"
    return "$ERR_INVAL_ARG"
  fi
  # check that image is a link
  # size in bytes
  local size
  size="$(du -b "$image_file" | awk '{print $1}')" || {
    err "Failed to get image file size: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
  readonly size

  if [[ "$size" -gt 1024 ]]; then
    # the image is not a link and is already downloaded
    if [[ "$image_file" != "$downloaded_image_file" ]]; then
      mv "$image_file" "$downloaded_image_file" || {
        err "Failed to move image file: '${image_file}'"
        return "$ERR_REGISTRY_OPERATION"
      }
    fi
    return 0
  fi

  local image_address
  image_address="$(<"$image_file")" || {
    err "Failed to get image address from file: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
  readonly image_address

  file_downloader::any_download "$image_address" "$downloaded_image_file" || {
    err "Error downloading image from address: '${image_address}'"
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
#  Writes image id and name (string) to the stdout
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

  vedv::registry_service::__create_registry_dir_structure "$registry_url" || {
    err "Failed to create registry directory structure"
    return "$ERR_REGISTRY_OPERATION"
  }

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

  if [[ "$no_cache" == true || ! -f "$image_file" ]]; then
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

  vedv::registry_service::__download_image_from_link "$image_file" "$image_file" || {
    err "Error downloading image from link file: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }

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
# Upload an image to a registry (base function)
#
# Arguments:
#   image_fqn           string      e.g.: nextcloud.loc/admin@alpine/alpine-13
#   image_export_func   string      function that export the files to be
#                                   uploaded
#
# Output:
#   Writes image name or image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__push() {
  local -r image_fqn="$1"
  local -r image_export_func="$2"
  # validate arguments
  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$ERR_INVAL_ARG"

  if [[ -z "$image_export_func" ]]; then
    err "image_export_func can not be empty"
    return "$ERR_INVAL_ARG"
  fi
  #

  local fqn_image_name=''
  fqn_image_name="$(vedv::image_entity::get_name_from_fqn "$image_fqn")" ||
    return $?
  readonly fqn_image_name

  local registry_url=''
  registry_url="$(vedv::image_entity::get_url_from_fqn "$image_fqn")" ||
    return $?
  readonly registry_url

  vedv::registry_service::__create_registry_dir_structure "$registry_url" || {
    err "Failed to create registry directory structure"
    return "$ERR_REGISTRY_OPERATION"
  }

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

  eval "$image_export_func" || {
    err "Error exporting image to: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }

  local rel_file_path
  rel_file_path="$(vedv::image_entity::get_rel_file_path_from_fqn "$image_fqn")" ||
    return $?
  readonly rel_file_path

  local -r remote_directory="/00-user-images/${rel_file_path%/*}"
  local -r remote_image_file="/00-user-images/${rel_file_path}"
  local -r remote_checksum_file="${remote_image_file}.sha256sum"

  # remove temporary files
  # shellcheck disable=SC2064
  trap "rm -f '$image_file' '$checksum_file'" INT TERM EXIT

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

#
# Export image file and checksum file to a directory
#
# Arguments:
#   image_name   string   name of the image that will be exported
#   image_file   string   path for the exported image file
#
# Output:
#  Writes errors to sdterr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__push_image_exporter() {
  local -r image_name="$1"
  local -r image_file="$2"
  # validate arguments
  if [[ -z "$image_name" ]]; then
    err "image_name can not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$image_file" ]]; then
    err "image_file can not be empty"
    return "$ERR_INVAL_ARG"
  fi

  vedv::image_service::export \
    "$image_name" \
    "$image_file" || {
    err "Error exporting image to file: '${image_file}'"
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
  if [[ -n "$image_name" ]]; then
    vedv::image_entity::validate_name "$image_name" ||
      return "$?"
  else
    image_name="$(vedv::image_entity::get_name_from_fqn "$image_fqn")" || {
      err "Failed to get image name from fqn: '${image_fqn}'"
      return "$ERR_INVAL_ARG"
    }
  fi
  readonly image_name

  local -r image_export_func="vedv::registry_service::__push_image_exporter '${image_name}' \"\$image_file\""

  vedv::registry_service::__push "$image_fqn" "$image_export_func" || {
    err "Error pushing image to registry"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# Export image link file and checksum file to a directory
#
# Arguments:
#   image_file        string  path to the image file
#   checksum_file     string  path to the checksum file
#   image_address     string  image address that will be used as a link
#   checksum_address  string  checksum address of the image
#
# Output:
#  Writes errors to sdterr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::__push_link_image_exporter() {
  local -r image_file="$1"
  local -r checksum_file="$2"
  local -r image_address="$3"
  local -r checksum_address="$4"
  # validate arguments
  if [[ -z "$image_file" ]]; then
    err "image_file can not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$checksum_file" ]]; then
    err "checksum_file can not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ "$(file_downloader::is_address "$image_address")" == false ]]; then
    err "image_address is not valid"
    return "$ERR_INVAL_ARG"
  fi
  if [[ "$(file_downloader::is_address "$checksum_address")" == false ]]; then
    err "checksum_address is not valid"
    return "$ERR_INVAL_ARG"
  fi

  echo "$image_address" >"$image_file" || {
    err "Error creating image link: '${image_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
  file_downloader::any_download "$checksum_address" "$checksum_file" || {
    err "Error downloading checksum from address: '${checksum_address}'"
    return "$ERR_DOWNLOAD"
  }

  sed -i "s/\s\S\+\.ova\s*$/ ${image_file##*/}/" "$checksum_file" || {
    err "Error updating checksum file: '${checksum_file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# Upload an image link to a registry
#
# Arguments:
#   image_address     string    image address that will be used as a link
#   checksum_address  string    checksum address of the image
#   image_fqn         string    e.g.: nextcloud.loc/admin@alpine/alpine-13
#
# Output:
#   Writes image name or image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::push_link() {
  local -r image_address="$1"
  local -r checksum_address="$2"
  local -r image_fqn="$3"
  # validate arguments
  if [[ "$(file_downloader::is_address "$image_address")" == false ]]; then
    err "image_address is not valid"
    return "$ERR_INVAL_ARG"
  fi
  if [[ "$(file_downloader::is_address "$checksum_address")" == false ]]; then
    err "checksum_address is not valid"
    return "$ERR_INVAL_ARG"
  fi

  local -r image_export_func="vedv::registry_service::__push_link_image_exporter \"\$image_file\" \"\$checksum_file\" '${image_address}' '${checksum_address}'"

  vedv::registry_service::__push "$image_fqn" "$image_export_func" || {
    err "Error pushing image link to registry"
    return "$ERR_REGISTRY_OPERATION"
  }
}

#
# clean the registry cache
#
# Output:
#   Writes the space freed to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_service::cache_clean() {

  local -r registry_cache_dir="$(vedv::registry_service::__get_registry_cache_dir)"

  local space_freed
  space_freed="$(du -sh "$registry_cache_dir" | awk '{print $1}')" ||
    return "$ERR_REGISTRY_OPERATION"
  readonly space_freed

  find "$registry_cache_dir" -type f \
    \( -name '*.ova' -o -name '*.ova.sha256sum' \) -delete ||
    return "$ERR_REGISTRY_OPERATION"

  echo "space_freed: ${space_freed}"
}
