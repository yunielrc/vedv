#
# Manage images
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './image-entity.bash'
  . './image-builder.bash'
  . './../__base/vmobj-service.bash'
  . './../../ssh-client.bash'
  . './../../hypervisors/virtualbox.bash'
  . '../container/container-service.bash'
  . '../registry/registry-service.bash'
fi

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   image_imported_dir          string    path to the image tmp directory
#   change_password_on_import   bool      change all users password to a generated
#                                         one for security reasons
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::constructor() {
  readonly __VEDV_IMAGE_SERVICE_IMPORTED_DIR="$1"
  readonly __VEDV_IMAGE_SERVICE_CHANGE_PASSWORD_ON_IMPORT="$2"
}

#
# Return if use cache for images
#
# Output:
#  writes true if use cache otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::get_use_cache() {
  vedv::vmobj_service::get_use_cache 'image'
}

#
# Change password on import
#
# Output:
#  writes true or false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::get_change_password_on_import() {
  echo "$__VEDV_IMAGE_SERVICE_CHANGE_PASSWORD_ON_IMPORT"
}

#
# Set use cache for images
#
# Arguments:
#  value     bool     use cache value
#
# Returns:
#   0 on success, non-zero on error.
vedv::image_service::set_use_cache() {
  local -r value="$1"

  vedv::vmobj_service::set_use_cache 'image' "$value"
}

#
# Change the password of all users in the image with a generated one
#
# Arguments:
#   image_id  string  image id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__gen_change_password() {
  local -r image_id="$1"

  local -r password="$(utils::gen_password)"

  vedv::vmobj_service::change_users_password 'image' "$image_id" "$password" || {
    err "Error setting password for image: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
}

#
# Import an image from a file
#
# Arguments:
#   image_file        string  image file
#   [image_name]      string  image name
#   [checksum_file]   string  check sum file (algorithm: sha256sum)
#
# Output:
#  Writes image id and name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::import() {
  local -r image_file="$1"
  local image_name="${2:-}"
  local -r checksum_file="${3:-}"
  # validate arguments
  if [[ ! -f "$image_file" ]]; then
    err "image file doesn't exist"
    return "$ERR_NOFILE"
  fi
  if [[ -n "$image_name" ]]; then
    local exists_image
    exists_image="$(vedv::image_service::exists_with_name "$image_name")" || {
      err "Failed to check if image with name: '${image_name}' already exist"
      return "$ERR_IMAGE_OPERATION"
    }
    readonly exists_image

    if [[ "$exists_image" == true ]]; then
      err "Image with name: '${image_name}' already exist, you can delete it or use another name"
      return "$ERR_IMAGE_OPERATION"
    fi
  fi
  if [[ -n "$checksum_file" ]]; then
    utils::sha256sum_check "$checksum_file" || {
      err "Failed to check sha256sum for image file: '${image_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  # Data gathering
  local _ova_file_sum
  _ova_file_sum="$(utils::crc_sum "$image_file")" || {
    err "Failed to calculate crc sum for image file: '${image_file}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly _ova_file_sum
  local -r image_cache_vm_name="$(vedv::image_cache_entity::get_vm_name "$_ova_file_sum")"

  local image_cache_exists
  image_cache_exists="$(vedv::hypervisor::exists_vm_with_partial_name "$image_cache_vm_name")" || {
    err "Error getting virtual machine with name: '${image_cache_vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_exists
  # Execution
  if [[ "$image_cache_exists" == false ]]; then
    vedv::hypervisor::import "$image_file" "$image_cache_vm_name" &>/dev/null || {
      err "Error creating image cache '${image_cache_vm_name}' vm from ova file '${image_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi
  # Data gathering
  local image_vm_name
  image_vm_name="$(vedv::image_entity::gen_vm_name "$image_name")" || {
    err "Failed to generate image vm name for image: '${image_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  readonly image_vm_name
  # Execution
  vedv::hypervisor::clonevm_link "$image_cache_vm_name" "$image_vm_name" &>/dev/null || {
    err "Failed to clone vm: '${image_cache_vm_name}' to: '${image_vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  local image_id
  image_id="$(vedv::image_entity::get_id_by_vm_name "$image_vm_name")" || {
    err "Error getting image_id for vm_name '${image_vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_id
  # we need to call this func to clean the cache for the vmobj_id is there is any
  vedv::vmobj_service::after_create 'image' "$image_id" || {
    err "Error on after create event: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::image_entity::set_vm_name "$image_id" "$image_vm_name" || {
    err "Failed to set vm name for image: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  vedv::image_entity::____clear_child_container_ids "$image_id" || {
    err "Failed to clear child container ids for image: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  # Data gathering
  if [[ -z "$image_name" ]]; then
    image_name="$(vedv::image_entity::get_image_name_by_vm_name "$image_vm_name")" || {
      err "Error getting image_name for vm_name '${image_vm_name}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi
  readonly image_name

  # Execution
  vedv::image_entity::set_image_cache "$image_id" "$image_cache_vm_name" || {
    err "Error setting attribute image cache '${image_cache_vm_name}' to the image '${image_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::image_entity::set_ova_file_sum "$image_id" "$_ova_file_sum" || {
    err "Error setting attribute ova file sum '${_ova_file_sum}' to the image '${image_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  # change all users password to a generated one for security reasons
  local -r change_password="$(vedv::image_service::get_change_password_on_import)"

  if [[ "$change_password" == true ]]; then

    vedv::image_service::__gen_change_password "$image_id" >/dev/null || {
      err "Error changing password for image '${image_id}'"
      return "$ERR_IMAGE_OPERATION"
    }
    vedv::image_service::stop "$image_id" >/dev/null || {
      err "Error stopping image '${image_id}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  # this layer must be created after any modification to the image file system
  # while importing it, because containers are created from the last layer
  # of the image
  vedv::image_service::create_layer_from "$image_id" "$image_file" >/dev/null || {
    err "Error creating the first layer for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  # Output
  echo "${image_id} ${image_name}"
}

#
# Import an image from a url
#
# Arguments:
#   image_url           string  image url
#   [image_name]        string  image name
#   [checksum_url]      string  checksum url (algorithm: sha256sum)
#
# Output:
#  Writes image id and name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::import_from_url() {
  local -r image_url="$1"
  local -r image_name="${2:-}"
  local -r checksum_url="${3:-}"
  # validate arguments
  if [[ -z "$image_url" ]]; then
    err "image_url is required"
    return "$ERR_INVAL_ARG"
  fi
  # validate url
  if ! utils::is_url "$image_url"; then
    err "image_url is not valid"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -n "$image_name" ]]; then
    vedv::image_entity::validate_name "$image_name" ||
      return "$?"
  fi
  readonly image_name

  if [[ -n "$checksum_url" ]] && ! utils::is_url "$checksum_url"; then
    err "checksum_url is not valid"
    return "$ERR_INVAL_ARG"
  fi

  local -r download_dir="$__VEDV_IMAGE_SERVICE_IMPORTED_DIR"

  if [[ ! -d "$download_dir" ]]; then
    err "Download directory does not exist: '${download_dir}'"
    return "$ERR_IMAGE_OPERATION"
  fi

  local -r image_file="${download_dir}/image-$(md5sum <<<"$image_url" | cut -d' ' -f1).ova"
  local checksum_file=''

  if [[ -n "$checksum_url" ]]; then
    checksum_file="${image_file}.sha256sum"

    utils::download_file "$checksum_url" "$checksum_file" || {
      err "Error downloading checksum from url: '${checksum_url}'"
      return "$ERR_IMAGE_OPERATION"
    }
    # replace the remote image file name with the local one in
    # the checksum file
    local _sha256sum
    _sha256sum="$(cut -d' ' -f1 "$checksum_file")" || {
      err "Error reading checksum file: '${checksum_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
    readonly _sha256sum

    echo "${_sha256sum} ${image_file##*/}" >"$checksum_file" || {
      err "Error writing checksum file: '${checksum_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi
  readonly checksum_file

  utils::download_file "$image_url" "$image_file" || {
    err "Error downloading image from url: '${image_url}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file" || {
    err "Error importing image from file: '${image_file}'"
    return "$ERR_IMAGE_OPERATION"
  }
}

#
# Import an image from file, registry or url
# If parameter image is a name it print the image name and exit without
# checking if the image exists.
#
# Arguments:
#   image         string  image name, url, file or fully qualified name
#   [image_name]  string  image name (default: OVF file name)
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::import_from_any() {
  local -r image="$1"
  local -r image_name="${2:-}"

  if [[ "$(vedv::vmobj_entity::is_name "$image")" == true ]]; then
    echo "0000000000 ${image}"
    return 0
  fi

  if [[ -f "$image" ]]; then
    vedv::image_service::import "$image" "$image_name" || {
      err "Error importing image from file: ${image}"
      return "$ERR_IMAGE_OPERATION"
    }
    return 0
  fi

  if utils::is_url "$image"; then
    vedv::image_service::import_from_url "$image" "$image_name" || {
      err "Error importing image from url: ${image}"
      return "$ERR_IMAGE_OPERATION"
    }
    return 0
  fi

  if [[ "$(vedv::image_entity::is_image_fqn "$image")" == true ]]; then
    vedv::registry_service::pull "$image" "$image_name" || {
      err "Error importing image from registry: ${image}"
      return "$ERR_IMAGE_OPERATION"
    }
    return 0
  fi

  err "Invalid image argument format, it must be a image name, url, file or fully qualified name"
  return "$ERR_INVAL_ARG"
}

#
# Export an image to a file, by default create a checksum file
#
# Arguments:
#   image_name_id   string  image id
#   image_file      string  image file
#   [no_checksum]   bool    do not create a checksum file (default: false)
#
# Output:
#  Writes image id and name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::export_by_id() {
  local -r image_id="$1"
  local -r image_file="$2"
  local -r no_checksum="${3:-false}"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_name_or_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$image_file" ]]; then
    err "Argument 'image_file' is required"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name=''
  vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get image name by id '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly vm_name

  local image_name=''
  image_name="$(vedv::image_entity::get_image_name_by_vm_name "$vm_name")" || {
    err "Failed to get image name for vm '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_name

  if [[ -f "$image_file" ]]; then
    rm -f "$image_file" || {
      err "Failed to remove existing image file: '${image_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  vedv::hypervisor::export "$vm_name" "$image_file" "$image_name" &>/dev/null || {
    err "Failed to export image '${image_name}' to '${image_file}'"
    return "$ERR_IMAGE_OPERATION"
  }

  if [[ "$no_checksum" == true ]]; then
    return 0
  fi

  local -r image_file_dir="${image_file%/*}"
  local -r image_file_basename="${image_file##*/}"
  local -r checksum_file_basename="${image_file_basename}.sha256sum"

  (
    cd "$image_file_dir" || {
      err "Failed to change directory to '${image_file_dir}'"
      return "$ERR_IMAGE_OPERATION"
    }
    sha256sum "$image_file_basename" >"$checksum_file_basename" || {
      err "Failed to create checksum file '${checksum_file_basename}'"
      return "$ERR_IMAGE_OPERATION"
    }
  )

}

#
# Export an image to a file, by default create a checksum file
#
# Arguments:
#   image_name_or_id  string  image to export
#   image_file        string  image file
#   [no_checksum]     bool    do not create a checksum file (default: false)
#
# Output:
#  Writes image id and name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::export() {
  local -r image_name_or_id="$1"
  local -r image_file="$2"
  local -r no_checksum="${3:-false}"

  local image_id
  image_id="$(vedv::vmobj_entity::get_id "$image_name_or_id")" || {
    err "Failed to get id by name or id: ${image_name_or_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly image_id

  vedv::image_service::export_by_id "$image_id" "$image_file" "$no_checksum"
}

#
#  List images
#
# Output:
#  writes  id, name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::list() {
  vedv::vmobj_service::list \
    'image' \
    'true'
}

#
# Remove one image
#
# Arguments:
#   image_id string    image id
#   force    bool      force remove image
#
# Output:
#  writes deleted image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove_one() {
  local -r image_id="$1"
  local -r force="${2:-false}"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$force" ]]; then
    err "Invalid argument 'force': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  ___echo_remove_image_failed() {
    err "Failed to remove image: '${image_id}'"
  }

  local vm_name
  vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Error getting vm name for image: '${image_id}'"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
  }
  readonly vm_name

  if [[ -z "$vm_name" ]]; then
    err "No such image: '${image_id}'"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
  fi

  local containers_ids
  containers_ids="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
    err "Error getting child containers for image: '${image_id}'"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
  }
  readonly containers_ids

  if [[ -n "$containers_ids" ]]; then

    if [[ "$force" == false ]]; then
      err "Failed to remove image '${image_id}' because it has child containers. Remove child containers first or force remove. Child containers ids: ${containers_ids}"
      return "$ERR_IMAGE_OPERATION"
    fi

    vedv::image_service::child_containers_remove_all "$image_id" || {
      err "Failed to remove child containers for image: '${image_id}'"
      ___echo_remove_image_failed
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  local image_cache_vm_name
  image_cache_vm_name="$(vedv::image_entity::get_image_cache "$image_id")" || {
    err "Error getting image cache for images ${image_id}"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_vm_name

  if [[ -z "$image_cache_vm_name" ]]; then
    err "Failed to remove image '${image_id}' because it has no image cache"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
  fi

  vedv::hypervisor::rm "$vm_name" &>/dev/null || {
    err "Failed to remove image: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  vedv::vmobj_service::after_remove 'image' "$image_id" || {
    err "Error on after remove event: '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::hypervisor::delete_snapshot "$image_cache_vm_name" "$vm_name" &>/dev/null || {
    err "Warning, not deleted snapshot on image cache for image: '${image_id}'. The snapshot will be deleted when the image cache is removed, so no need to worry."
  }

  echo "$image_id"
}

#
#  Remove an image
#
# Arguments:
#   force     bool      force remove image
#   image_id  string    container id
#
# Output:
#  writes removed image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove_one_batch() {
  local -r force="$1"
  local -r image_id="$2"

  vedv::image_service::remove_one "$image_id" "$force"
}

#
# Remove one or more images
#
# Arguments:
#   image_ids_or_names  string[]  image ids or names
#   force               bool      force the remove, removing child containers if the image has
#
# Output:
#  writes deleted image_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove() {
  local -r image_ids_or_names="$1"
  local -r force="${2:-false}"

  vedv::vmobj_service::exec_func_on_many_vmobj \
    'image' \
    "vedv::image_service::remove_one_batch '${force}'" \
    "$image_ids_or_names"
}

#
# Remove unused images cache
#
# Output:
#  Writes deleted cache id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove_unused_cache() {
  local image_cache_vm_names
  image_cache_vm_names="$(vedv::hypervisor::list_vms_by_partial_name 'image-cache|')" || {
    err 'Error getting image cache vm_names'
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_vm_names

  if [[ -z "$image_cache_vm_names" ]]; then
    return 0
  fi

  local -a image_cache_vm_names_arr
  readarray -t image_cache_vm_names_arr <<<"$image_cache_vm_names"
  readonly image_cache_vm_names_arr

  local failed_remove=''

  for im_cache_vm_name in "${image_cache_vm_names_arr[@]}"; do

    local snapshots
    snapshots="$(vedv::hypervisor::show_snapshots "$im_cache_vm_name")" || {
      err "Error getting snapshots for vm: '$im_cache_vm_name'"
      return "$ERR_IMAGE_OPERATION"
    }

    if [[ -n "$snapshots" ]]; then

      local -a snapshots_arr
      readarray -t snapshots_arr <<<"$snapshots"

      local -a orphaned_snapshots=()

      for im_vm_name in "${snapshots_arr[@]}"; do

        local exists_im=true
        exists_im="$(vedv::hypervisor::exists_vm_with_partial_name "$im_vm_name")" || {
          err "Error checking if vm exists: '$im_vm_name'"
          return "$ERR_IMAGE_OPERATION"
        }

        if [[ "$exists_im" == true ]]; then
          # The snapshot in the image cache is not orphaned, so it belongs to
          # an a existing image, therefore the image cache is in use and
          # should not be removed

          # but before going to the next image cache, it check if there are
          # orphaned snapshots found out the way up to this point and it try
          # to remove each one
          if [[ "${#orphaned_snapshots[@]}" -gt 0 ]]; then

            for orphaned_snapshot in "${orphaned_snapshots[@]}"; do
              vedv::hypervisor::delete_snapshot "$im_cache_vm_name" "$orphaned_snapshot" &>/dev/null || {
                err "Warning, not deleted orphaned snapshot: '${orphaned_snapshot}' on image cache: '$im_cache_vm_name'"
              }
            done
          fi
          continue 2
        else
          orphaned_snapshots+=("$im_vm_name")
        fi
      done
    fi
    # at this point the image cache is not in use, so it can be removed
    local image_id
    image_id="$(vedv::image_cache_entity::get_image_id_by_vm_name "$im_cache_vm_name")" || {
      err "Error getting image id by vm name: '$im_cache_vm_name'"
      return "$ERR_IMAGE_OPERATION"
    }
    vedv::hypervisor::rm "$im_cache_vm_name" &>/dev/null || {
      failed_remove+="$image_id "
      continue
    }

    echo -n "$image_id "
  done
  echo

  if [[ -n "$failed_remove" ]]; then
    err "Failed to remove caches: ${failed_remove}"
    return "$ERR_IMAGE_OPERATION"
  fi
  return 0
}

#
# Tell if image is started
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes errors to the stderr
#
# Returns:
#   0 if running, 1 otherwise
#
vedv::image_service::is_started() {
  local -r image_id="$1"

  vedv::vmobj_service::is_started 'image' "$image_id"
}

#
# Start an image
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::start() {
  local -r image_id="$1"

  vedv::vmobj_service::start_one 'image' "$image_id" 'true'
}

#
# Stop an image
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::stop() {
  local -r image_id="$1"

  vedv::vmobj_service::stop 'image' "$image_id" 'true'
}

#
# Remove containers
#
# Arguments:
#   image_id  string        id of the image
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::child_containers_remove_all() {
  local -r image_id="$1"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local container_ids
  container_ids="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
    err "Failed to get child containers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly container_ids

  if [[ -z "$container_ids" ]]; then
    return 0
  fi

  local -a container_ids_arr
  IFS=' ' read -r -a container_ids_arr <<<"$container_ids"
  readonly container_ids_arr

  for container_id in "${container_ids_arr[@]}"; do
    if ! vedv::container_service::remove_one "$container_id" 'true' &>/dev/null; then
      err "Failed to remove container: ${container_id}"
      return "$ERR_IMAGE_OPERATION"
    fi
  done

  return 0
}

#
# Create a layer
#
# Arguments:
#   image_id    string  image id
#   layer_name  string  layer name
#   layer_id    string  layer id
#
# Output:
#   Writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::create_layer() {
  local -r image_id="$1"
  local -r layer_name="$2"
  local -r layer_id="$3"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return $?
  vedv::image_entity::validate_layer_name "$layer_name" ||
    return $?
  vedv::image_entity::validate_id "$layer_id" ||
    return $?

  local exists_layer
  exists_layer="$(vedv::image_entity::has_layer_id "$image_id" "$layer_id")" || {
    err "Failed to check if layer '${layer_name}' exists for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly exists_layer

  if [[ "$exists_layer" == true ]]; then
    err "Layer '${layer_name}' already exists for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  fi

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get vm name for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_vm_name

  local -r full_layer_name="layer:${layer_name}|id:${layer_id}|"

  vedv::hypervisor::take_snapshot "$image_vm_name" "$full_layer_name" &>/dev/null || {
    err "Failed to create layer '${full_layer_name}' for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  echo "$layer_id"
}

#
# Create FROM layer
#
# Arguments:
#   image_id    string  image id
#   image_file  string  image file
#
# Output:
#   Writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::create_layer_from() {
  local -r image_id="$1"
  local -r image_file="$2"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return $?

  if [[ ! -f "$image_file" ]]; then
    err "image file doesn't exist, path: '${image_file}'"
    return "$ERR_NOFILE"
  fi

  local layer_id
  layer_id="$(utils::crc_sum "$image_file")" || {
    err "Failed to calculate crc sum for image file '${image_file}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layer_id
  local -r layer_name='FROM'

  vedv::image_service::create_layer "$image_id" "$layer_name" "$layer_id"
}
#
# Remove layer
#
# Arguments:
#   image_id  string        image id
#   layer_id  string        layer id
#
# Output:
#   Writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::delete_layer() {
  local -r image_id="$1"
  local -r layer_id="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$layer_id" ]]; then
    err "Argument 'layer_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get image vm name for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image vm name '${image_id}' not found"
    return "$ERR_IMAGE_OPERATION"
  fi

  local layer_full_name
  layer_full_name="$(vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$layer_id")" || {
    err "Failed to get layer full name for image '${image_id}' and layer '${layer_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layer_full_name

  if [[ -z "$layer_full_name" ]]; then
    err "Layer '${layer_id}' not found for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  fi

  vedv::hypervisor::delete_snapshot "$image_vm_name" "$layer_full_name" 1>/dev/null || {
    err "Failed to delete layer '${layer_id}' for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  return 0
}

#
# Restore last layer
#
# Arguments:
#   image_id  string        image id
#
# Output:
#   Writes error messages to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::restore_last_layer() {
  local -r image_id="$1"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local last_layer_id
  last_layer_id="$(vedv::image_entity::get_last_layer_id "$image_id")" || {
    err "Failed to get last layer id for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly last_layer_id

  if [[ -z "$last_layer_id" ]]; then
    err "Last layer not found for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  fi

  vedv::image_service::restore_layer "$image_id" "$last_layer_id" || {
    err "Failed to restore last layer '${last_layer_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  return 0
}
#
# Restore layer
#
# Arguments:
#   image_id  string        image id
#   layer_id  string        layer id
#
# Output:
#   Writes error messages to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::restore_layer() {
  local -r image_id="$1"
  local -r layer_id="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$layer_id" ]]; then
    err "Argument 'layer_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get image vm name for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image vm name for '${image_id}' not found"
    return "$ERR_IMAGE_OPERATION"
  fi

  local layer_full_name
  layer_full_name="$(vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$layer_id")" || {
    err "Failed to get layer full name for image '${image_id}' and layer '${layer_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layer_full_name

  if [[ -z "$layer_full_name" ]]; then
    err "Layer '${layer_id}' not found for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  fi

  vedv::hypervisor::restore_snapshot "$image_vm_name" "$layer_full_name" &>/dev/null || {
    err "Failed to restore layer '${layer_id}' for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  return 0
}

#
# Execute cmd in a image
#
# Arguments:
#   image_id  string     image id or name
#   cmd       string     command to execute
#   [user]    string     image user
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::execute_cmd() {
  local -r image_id="$1"
  local -r cmd="$2"
  local -r user="${3:-}"

  vedv::vmobj_service::execute_cmd_by_id \
    'image' \
    "$image_id" \
    "$cmd" \
    "$user"
}

#
# Copy files from local filesystem to a image
#
# Arguments:
#   image_id  string     image id or name
#   src       string     local source path
#   dest      string     image destination path
#   [user]    string     image user
#   [chown]   string     chown files to user
#   [chmod]   string     chmod files to mode
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::copy() {
  local -r image_id="$1"
  local -r src="$2"
  local -r dest="$3"
  local -r user="${4:-}"
  local -r chown="${5:-}"
  local -r chmod="${6:-}"

  vedv::vmobj_service::copy_by_id \
    'image' \
    "$image_id" \
    "$src" \
    "$dest" \
    "$user" \
    '' \
    "$chown" \
    "$chmod"
}

#
# Create an user if not exits and set its name to
# the image
#
# Arguments:
#   image_id   string  image id
#   user_name  string  user name
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::set_user() {
  local -r image_id="$1"
  local -r user_name="$2"

  vedv::vmobj_service::fs::set_user \
    'image' \
    "$image_id" \
    "$user_name"
}

#
# Creates and set the default workdir for the image
#
# Arguments:
#   image_id  string  image id
#   workdir   string  workdir
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::set_workdir() {
  local -r image_id="$1"
  local -r workdir="$2"

  vedv::vmobj_service::fs::set_workdir \
    'image' \
    "$image_id" \
    "$workdir"
}

#
# Set the shell for all users in the image
#
# Arguments:
#   image_id  string  image id
#   shell     string  shell name (e.g. /bin/bash, or bash)
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::set_shell() {
  local -r image_id="$1"
  local -r shell="$2"

  vedv::vmobj_service::fs::set_shell \
    'image' \
    "$image_id" \
    "$shell"
}

#
# Add environment variable to vmobj filesystem
#
# Arguments:
#   image_id  string  image id
#   env_var   string  env var (e.g. NAME=nalyd)
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
vedv::image_service::fs::add_environment_var() {
  local -r image_id="$1"
  local -r env_var="$2"

  vedv::vmobj_service::fs::add_environment_var \
    'image' \
    "$image_id" \
    "$env_var"
}

#
# Get environment variables from image filesystem
#
# Arguments:
#   image_id  string     image id
#
# Output:
#  writes environment variables (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::list_environment_vars() {
  local -r image_id="$1"

  vedv::vmobj_service::fs::list_environment_vars \
    'image' \
    "$image_id"
}

#
# Save the number of memory on the image fs
#
# Arguments:
#   image_id  string     image id
#   memory    integer    memory
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::set_system() {
  local -r image_id="$1"
  local -ri cpus="$2"
  local -ri memory="${3:-}"

  local commands=''

  if [[ $cpus -gt 0 ]]; then
    commands="vedv-setcpus '${cpus}'; "
  fi
  if [[ "$memory" -gt 0 ]]; then
    commands="${commands}vedv-setmemory '${memory}'"
  fi
  readonly commands

  if [[ -z "$commands" ]]; then
    err "At least one of cpus or memory must be set"
    return "$ERR_INVAL_ARG"
  fi

  vedv::vmobj_service::execute_cmd_by_id 'image' "$image_id" "$commands" 'root' '<none>' || {
    err "Failed to modify system for image: ${image_id}"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::vmobj_service::modify_system \
    'image' \
    "$image_id" \
    "$cpus" \
    "$memory" >/dev/null
}

#
# Get the number of cpus from the image fs
#
# Arguments:
#   image_id  string    image id
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::get_cpus() {
  local -r image_id="$1"

  local -r cmd='vedv-getcpus'

  vedv::vmobj_service::execute_cmd_by_id 'image' "$image_id" "$cmd" 'root' '<none>' || {
    err "Failed to get cpus for image: ${image_id}"
    return "$ERR_IMAGE_OPERATION"
  }
}

#
# Get the number of memory from the image fs
#
# Arguments:
#   image_id  string    image id
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::get_memory() {
  local -r image_id="$1"

  local -r cmd='vedv-getmemory'

  vedv::vmobj_service::execute_cmd_by_id 'image' "$image_id" "$cmd" 'root' '<none>' || {
    err "Failed to get memory for image: ${image_id}"
    return "$ERR_IMAGE_OPERATION"
  }
}

#
# Delete layer cache
# This function is used to delete the layers others than
# the first layer (FROM)
#
# Arguments:
#   image_id  string     image id
#
# Output:
#  writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::delete_layer_cache() {
  local -r image_id="$1"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local layers_ids
  layers_ids="$(vedv::image_entity::get_layers_ids "$image_id")" || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  if [[ -z "$layers_ids" ]]; then
    return 0
  fi

  local -a layers_ids_arr
  IFS=' ' read -r -a layers_ids_arr <<<"$layers_ids"

  local -r layer_from_id="${layers_ids_arr[0]}"
  layers_ids_arr=("${layers_ids_arr[@]:1}")
  # reverse array
  local -a reversed_array=()
  for ((i = ${#layers_ids_arr[@]} - 1; i >= 0; i--)); do
    reversed_array+=("${layers_ids_arr[i]}")
  done
  layers_ids_arr=("${reversed_array[@]}")
  # layers_ids_arr=($(tac -s ' ' <<<"${layers_ids_arr[@]}")) # inefficient
  readonly layers_ids_arr

  for layer_id in "${layers_ids_arr[@]}"; do
    vedv::image_service::delete_layer "$image_id" "$layer_id" || {
      err "Failed to delete layer '${layer_id}' for image '${image_id}'"
      return "$ERR_IMAGE_OPERATION"
    }
  done

  vedv::image_service::restore_layer "$image_id" "$layer_from_id" || {
    err "Failed to restore layer '${layer_from_id}' for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
}

#
# Build an image from a Vedvfile,
#
# Arguments:
#   vedvfile              string  Vedvfile full path
#   [image_name]          string  name of the image
#   [force]               bool    force the build, removing child containers if the image has
#   [no_cache]            bool    do not use cache when building the image
#   [no_wait_after_build] bool    if true, it will not wait for the
#                                 image to save data cache and stopping
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::build() {
  local -r vedvfile="$1"
  local -r image_name="${2:-}"
  local -r force="${3:-false}"
  local -r no_cache="${4:-false}"
  local -r no_wait_after_build="${5:-}"

  vedv::image_builder::build \
    "$vedvfile" \
    "$image_name" \
    "$force" \
    "$no_cache" \
    "$no_wait_after_build"
}

#
# Add expose ports to image
#
# Arguments:
#   image_id  string    image id
#   ports     string[]  ports (e.g. 80/tcp 443/udp 8080)
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::fs::add_exposed_ports() {
  local -r image_id="$1"
  local -r ports="$2"

  vedv::vmobj_service::fs::add_exposed_ports \
    'image' \
    "$image_id" \
    "$ports"
}

#
# List exposed ports from image filesystem
#
# Arguments:
#   image_name_or_id  string    image name or id
#
# Output:
#   writes exposed ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::cache::list_exposed_ports() {
  local -r image_name_or_id="$1"
  # validate arguments
  if [[ -z "$image_name_or_id" ]]; then
    err "Invalid argument 'vmobj_name_or_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local image_id
  image_id="$(vedv::vmobj_entity::get_id "$image_name_or_id")" || {
    err "Failed to get id for image: '${image_name_or_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_id

  vedv::image_entity::cache::get_exposed_ports "$image_id"
}

#
# Set image filesystem vedv data to image entity
#
# Arguments:
#   image_id  string    image id
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::cache_data() {
  local -r image_id="$1"

  vedv::vmobj_service::cache_data \
    'image' \
    "$image_id" || {
    err "Failed to cache data for image '${image_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }

  local cpus
  cpus="$(vedv::image_service::fs::get_cpus "$image_id")" || {
    err "Failed to get cpus for image ${image_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly cpus

  vedv::image_entity::cache::set_cpus "$image_id" "$cpus" || {
    err "Failed to set cpus for image ${image_id}"
    return "$ERR_VMOBJ_OPERATION"
  }

  local memory
  memory="$(vedv::image_service::fs::get_memory "$image_id")" || {
    err "Failed to get memory for image ${image_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly memory

  vedv::image_entity::cache::set_memory "$image_id" "$memory" || {
    err "Failed to set memory for image ${image_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
#  Exists image with id
#
# Arguments:
#  image_id string    image id
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::exists_with_id() {
  local -r vmobj_id="$1"

  vedv::vmobj_service::exists_with_id \
    'image' \
    "$vmobj_id"
}

#
#  Exists image with name
#
# Arguments:
#  image_name string  image name
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::exists_with_name() {
  local -r vmobj_name="$1"

  vedv::vmobj_service::exists_with_name \
    'image' \
    "$vmobj_name"
}
