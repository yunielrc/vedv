#
# Manage images
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
  . './image-entity.bash'
  . './image-builder.bash'
  . '../container/container-service.bash'
  . './../../ssh-client.bash'
fi

# REFACTOR: use vedv::hypervisor::<function> instead of
# vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::<functions>

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   hypervisor  string       name of the script
#   ssh_ip  string           ssh ip
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::constructor() {
  readonly __VEDV_IMAGE_SERVICE_HYPERVISOR="$1"
  readonly __VEDV_IMAGE_SERVICE_SSH_IP="$2"
}

#
# Import an OVA image from file
#
# Arguments:
#   image_file      OVF file image
#   [image_name]    image name (default: OVF file name + random id)
#   [return_image_id]  print the image id instead image name
#
# Output:
#  Writes image name or image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__pull_from_file() {
  local -r image_file="$1"
  local -r custom_image_name="${2:-}"
  local -r return_image_id="${3:-false}"

  if [[ ! -f "$image_file" ]]; then
    err "OVA file image doesn't exist"
    return "$ERR_NOFILE"
  fi
  local vm_name="$(vedv::image_entity::gen_vm_name_from_ova_file "$image_file")"
  local image_id="$(vedv::image_entity::get_image_id_by_vm_name "$vm_name")"
  local -r _ova_file_sum="$image_id"
  local image_name="$(vedv::image_entity::get_image_name_by_vm_name "$vm_name")"
  local -r image_cache_vm_name="image-cache|crc:${image_id}0|"

  if [[ -n "$custom_image_name" ]]; then
    vm_name="$(vedv::image_entity::gen_vm_name "$custom_image_name")"
    image_id="$(vedv::image_entity::get_image_id_by_vm_name "$vm_name")"
    image_name="$custom_image_name"
  fi
  readonly vm_name image_id image_name

  local image_exists
  image_exists="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$vm_name")" || {
    err "Error getting virtual machine with name: '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_exists

  if [[ -n "$image_exists" ]]; then
    err "There is another image with the same name: ${image_name}, you must delete it or use another name"
    return "$ERR_IMAGE_OPERATION"
  fi

  # Import an OVF from a file
  local image_cache_exists
  image_cache_exists="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$image_cache_vm_name")" || {
    err "Error getting virtual machine with name: '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_exists

  if [[ -z "$image_cache_exists" ]]; then
    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::import &>/dev/null "$image_file" "$image_cache_vm_name" || {
      err "Error creating image cache '${image_cache_vm_name}' vm from ova file '${image_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::clonevm_link "$image_cache_vm_name" "$vm_name" &>/dev/null || {
    err "Error cloning image cache '${image_cache_vm_name}' to the image vm '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::image_entity::set_image_cache "$image_id" "$image_cache_vm_name" || {
    err "Error setting attribute image cache '${image_cache_vm_name}' to the image vm '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  vedv::image_entity::set_ova_file_sum "$image_id" "$_ova_file_sum" || {
    err "Error setting attribute ova file sum '${_ova_file_sum}' to the image vm '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }

  if [[ "$return_image_id" != true ]]; then
    echo "$image_name"
  else
    echo "$image_id"
  fi

  return 0
}

# Pull an OVF file from a registry or file
# and create an image
#
# Arguments:
#   image string               image name or an OVF file that  #                              will be pulled
#   [image_name string]        image name (default: OVF file name)
#   [return_image_id bool]   print the image id
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::pull() {
  # IMPL: test this function
  # TODO: validate fields and test
  local -r image="$1"
  local -r image_name="${2:-}"
  local -r return_image_id="${3:-false}"

  if [[ -f "$image" ]]; then
    vedv::image_service::__pull_from_file "$image" "$image_name" "$return_image_id" || {
      err "Error pulling image '${image}' from file"
      return "$ERR_IMAGE_OPERATION"
    }
  else
    # IMPL: Pull an OVF image from a registry
    err "Not implemented: 'vedv::image_service::__pull_from_registry'"
    return "$ERR_NOTIMPL"
  fi
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

  local vm_names
  vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list)" || {
    err "Error getting virtual machines names"
    return "$ERR_IMAGE_OPERATION"
  }
  vm_names="$(echo "$vm_names" | grep "image:.*|" || :)"
  readonly vm_names

  for vm_name in $vm_names; do
    local image_id
    image_id="$(vedv::image_entity::get_image_id_by_vm_name "$vm_name")" || {
      err "Error getting image id from vm name: '${vm_name}'"
      return "$ERR_IMAGE_OPERATION"
    }

    local image_name
    image_name="$(vedv::image_entity::get_image_name_by_vm_name "$vm_name")" || {
      err "Error getting image name from vm name: '${vm_name}'"
      return "$ERR_IMAGE_OPERATION"
    }

    echo "${image_id} ${image_name}"
  done
}

#
# Remove one or more images
#
# Arguments:
#   image_ids string    image ids
#
# Output:
#  writes deleted image_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove_by_id() {
  local -ra image_ids=("$@")

  if [[ "${#image_ids[@]}" -eq 0 ]]; then
    err 'At least one image id is required'
    return "$ERR_INVAL_ARG"
  fi

  local -A image_failed=()

  for image_id in "${image_ids[@]}"; do

    local vm_name
    vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
      image_failed["Error getting vm name for images"]+="$image_id "
      image_failed["Failed to remove images"]+="$image_id "
      continue
    }

    if [[ -z "$vm_name" ]]; then
      image_failed['No such images']+="$image_id "
      continue
    fi

    local containers_ids
    containers_ids="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
      image_failed["Error getting child containers for images"]+="$image_id "
      image_failed["Failed to remove images"]+="$image_id "
      continue
    }

    if [[ -n "$containers_ids" ]]; then
      image_failed["Failed to remove image '${image_id}' because it has containers, remove them first"]="$containers_ids"
      image_failed["Failed to remove images"]+="$image_id "
      continue
    fi

    local image_cache_vm_name
    image_cache_vm_name="$(vedv::image_entity::get_image_cache "$image_id")" || {
      image_failed["Error getting image cache for images"]+="$image_id "
      image_failed["Failed to remove images"]+="$image_id "
      continue
    }

    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::rm "$vm_name" &>/dev/null || {
      image_failed["Failed to remove images"]+="$image_id "
      continue
    }

    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::delete_snapshot "$image_cache_vm_name" "$vm_name" &>/dev/null || {
      image_failed["Error deleting snapshot for images"]+="$image_id "
      continue
    }

    echo -n "$image_id "
  done

  echo
  for err_msg in "${!image_failed[@]}"; do
    err "${err_msg}: ${image_failed["$err_msg"]}"
  done

  if [[ "${#image_failed[@]}" -ne 0 ]]; then
    return "$ERR_IMAGE_OPERATION"
  fi

  return 0
}

#
# Remove one or more images
#
# Arguments:
#   image_ids_or_names string    image ids or names
#
# Output:
#  writes deleted image_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove() {
  local -ra image_ids_or_names=("$@")

  if [[ "${#image_ids_or_names[@]}" -eq 0 ]]; then
    err 'At least one image is required'
    return "$ERR_INVAL_ARG"
  fi

  local -a image_ids

  for image_id_or_name in "${image_ids_or_names[@]}"; do
    local image_id
    image_id="$(vedv::image_entity::get_id_by_image_name "$image_id_or_name")" || {
      if [[ $? != "$ERR_NOT_FOUND" ]]; then
        err "Error getting image id by image name: '${image_id_or_name}'"
      fi
      image_ids+=("$image_id_or_name")
      continue
    }
    image_ids+=("$image_id")
  done

  vedv::image_service::remove_by_id "${image_ids[@]}"
}

#
# Remove one or more images
#
# Arguments:
#   image_ids_or_names string    image ids or names
#
# Output:
#  writes deleted image_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::rm() {
  vedv::image_service::remove "$@"
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
  image_cache_vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name 'image-cache|')" || {
    err 'Error getting image cache vm names'
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_vm_names

  local failed_remove=''

  for vm_name in $image_cache_vm_names; do
    local snapshots
    snapshots="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::show_snapshots "$vm_name")" || {
      err "Error getting snapshots for vm: '$vm_name'"
      return "$ERR_IMAGE_OPERATION"
    }

    if [[ -z "$snapshots" ]]; then
      local image_id
      image_id="$(vedv::image_cache_entity::get_image_id_by_vm_name "$vm_name")" || {
        err "Error getting image id by vm name: '$vm_name'"
        return "$ERR_IMAGE_OPERATION"
      }

      vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::rm "$vm_name" &>/dev/null || {
        failed_remove+="$image_id "
        continue
      }

      echo -n "$image_id "
    fi
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

  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name
  vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get vm name for image: '$image_id'"
    return "$ERR_IMAGE_OPERATION"
  }

  local is_running
  is_running="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::is_running "$vm_name")" || {
    err "Failed to check if is running vm: '$vm_name'"
    return "$ERR_HYPERVISOR_OPERATION"
  }
  readonly is_running
  # TODO: use echo true|false instead of returning 1|0
  if [[ "$is_running" == false ]]; then
    return 1
  fi
  return 0
}

#
# Start image if isn't running
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
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  # TODO: check errors on vedv::image_service::is_started call
  if ! vedv::image_service::is_started "$image_id"; then
    local image_vm_name
    image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
      err "Failed to get image vm name"
      return "$ERR_IMAGE_OPERATION"
    }
    readonly image_vm_name

    if [[ -z "$image_vm_name" ]]; then
      err "There is no vm name for image ${image_id}"
      return "$ERR_IMAGE_OPERATION"
    fi
    # start the vm
    local _ssh_port
    _ssh_port="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::assign_random_host_forwarding_port "$image_vm_name" 'ssh' 22)" || {
      err "Failed to assign random host forwarding port to image with id ${image_id}"
      return "$ERR_IMAGE_OPERATION"
    }
    readonly _ssh_port

    if [[ -z "$_ssh_port" ]]; then
      err "Empty ssh port for image with id ${image_id}"
      return "$ERR_IMAGE_OPERATION"
    fi
    vedv::image_entity::set_ssh_port "$image_id" "$_ssh_port" || {
      err "Failed to set ssh port ${_ssh_port} to image with id ${image_id}"
      return "$ERR_IMAGE_OPERATION"
    }
    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::start "$image_vm_name" || {
      err "Failed to start image with id ${image_id}"
      return "$ERR_IMAGE_OPERATION"
    }
    vedv::ssh_client::wait_for_ssh_service "$__VEDV_IMAGE_SERVICE_SSH_IP" "$_ssh_port" || {
      err "Failed to wait for ssh on port ${_ssh_port}"
      return "$ERR_IMAGE_OPERATION"
    }
  fi
  return 0
}

#
# Stop image if it's running
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

  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get image vm name"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "There is no vm name for image ${image_id}"
    return "$ERR_IMAGE_OPERATION"
  fi
  # stop the vm
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::shutdown "$image_vm_name" || {
    err "Failed to stop image with id ${image_id}"
    return "$ERR_HYPERVISOR_OPERATION"
  }
  #
  # TODO: test the code below
  #
  ___vm_is_running() {
    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::is_running "$image_vm_name" || {
      err "Failed to check if image with id ${image_id} is running"
      return "$ERR_HYPERVISOR_OPERATION"
    }
  }

  local is_running=true
  local -i attemps=10

  while [[ "$is_running" == true && "$attemps" -gt 0 ]]; do
    sleep 1
    ((attemps -= 1))
    is_running="$(___vm_is_running)" || return
  done
  readonly is_running

  if [[ "$is_running" == true ]]; then
    err "Failed to stop image with id ${image_id}, trying to poweroff it..."

    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::poweroff "$image_vm_name" || {
      err "Failed to poweroff image with id ${image_id}"
      return "$ERR_HYPERVISOR_OPERATION"
    }
    return "$ERR_HYPERVISOR_OPERATION"
  fi
  #
  #
  #
  return 0
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

  local failed_rm_containers=''

  for container_id in $container_ids; do
    vedv::container_service::rm "$container_id" &>/dev/null || {
      failed_rm_containers+="${container_id} "
    }
  done
  readonly failed_rm_containers

  if [[ -n "$failed_rm_containers" ]]; then
    err "Failed to remove containers: ${failed_rm_containers}"
    return "$ERR_IMAGE_OPERATION"
  fi

  return 0
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

  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::delete_snapshot "$image_vm_name" "$layer_full_name" 1>/dev/null || {
    err "Failed to delete layer '${layer_id}' for image '${image_id}'"
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

  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::restore_snapshot "$image_vm_name" "$layer_full_name" &>/dev/null || {
    err "Failed to restore layer '${layer_id}' for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  return 0
}

#
# Build an image from a Vedvfile,
#
# Arguments:
#   vedvfile string       Vedvfile full path
#   [image_name] string   name of the image
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::build() { vedv::image_builder::build "$@"; }
