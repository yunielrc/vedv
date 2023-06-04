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
fi

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
# vedv::image_service::constructor() {

# }

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

  local vm_name
  vm_name="$(vedv::image_entity::gen_vm_name_from_ova_file "$image_file")" || {
    err "Error generating vm_name from ova_file '${image_file}'"
    return "$ERR_IMAGE_OPERATION"
  }
  local image_id
  image_id="$(vedv::image_entity::get_id_by_vm_name "$vm_name")" || {
    err "Error getting image_id by vm_name '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  local -r _ova_file_sum="$image_id"
  local image_name
  image_name="$(vedv::image_entity::get_image_name_by_vm_name "$vm_name")" || {
    err "Error getting image_name by vm_name '${vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  local -r image_cache_vm_name="image-cache|crc:${image_id}0|"

  if [[ -n "$custom_image_name" ]]; then
    vm_name="$(vedv::image_entity::gen_vm_name "$custom_image_name")" || {
      err "Error generating vm_name from image_name: '${custom_image_name}'"
      return "$ERR_IMAGE_OPERATION"
    }
    image_id="$(vedv::image_entity::get_id_by_vm_name "$vm_name")" || {
      err "Error getting image_id by vm_name '${vm_name}'"
      return "$ERR_IMAGE_OPERATION"
    }
    image_name="$custom_image_name"
  fi
  readonly vm_name image_id image_name

  local image_exists
  image_exists="$(vedv::hypervisor::list_vms_by_partial_name "$vm_name")" || {
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
  image_cache_exists="$(vedv::hypervisor::list_vms_by_partial_name "$image_cache_vm_name")" || {
    err "Error getting virtual machine with name: '${image_cache_vm_name}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_cache_exists

  if [[ -z "$image_cache_exists" ]]; then
    vedv::hypervisor::import "$image_file" "$image_cache_vm_name" &>/dev/null || {
      err "Error creating image cache '${image_cache_vm_name}' vm from ova file '${image_file}'"
      return "$ERR_IMAGE_OPERATION"
    }
  fi

  vedv::hypervisor::clonevm_link "$image_cache_vm_name" "$vm_name" &>/dev/null || {
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

  vedv::hypervisor::delete_snapshot "$image_cache_vm_name" "$vm_name" &>/dev/null || {
    err "Error deleting snapshot for image: '${image_id}'"
    ___echo_remove_image_failed
    return "$ERR_IMAGE_OPERATION"
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
#   force               bool      force the remove, removing child containers if the image has
#   image_ids_or_names  @string   image ids or names
#
# Output:
#  writes deleted image_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove() {
  local -r force="$1"
  # validate arguments
  if [[ -z "$force" ]]; then
    err "Invalid argument 'force': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  shift

  vedv::vmobj_service::exec_func_on_many_vmobj \
    'image' \
    "vedv::image_service::remove_one_batch ${force}" \
    "$@"
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

  for vm_name in "${image_cache_vm_names_arr[@]}"; do
    local snapshots
    snapshots="$(vedv::hypervisor::show_snapshots "$vm_name")" || {
      err "Error getting snapshots for vm: '$vm_name'"
      return "$ERR_IMAGE_OPERATION"
    }

    if [[ -z "$snapshots" ]]; then
      local image_id
      image_id="$(vedv::image_cache_entity::get_image_id_by_vm_name "$vm_name")" || {
        err "Error getting image id by vm name: '$vm_name'"
        return "$ERR_IMAGE_OPERATION"
      }

      vedv::hypervisor::rm "$vm_name" &>/dev/null || {
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
  vedv::vmobj_service::is_started 'image' "$@"
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
  vedv::vmobj_service::start_one 'image' 'true' "$@"
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
  vedv::vmobj_service::stop 'image' 'true' "$@"
  # vedv::vmobj_service::secure_stop_one 'image' "$@"
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
vedv::image_service::set_user() {
  local -r image_id="$1"
  local -r user_name="$2"

  vedv::vmobj_service::set_user \
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
vedv::image_service::set_workdir() {
  local -r image_id="$1"
  local -r workdir="$2"

  vedv::vmobj_service::set_workdir \
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
vedv::image_service::set_shell() {
  local -r image_id="$1"
  local -r shell="$2"

  vedv::vmobj_service::set_shell \
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
vedv::image_service::add_environment_var() {
  local -r image_id="$1"
  local -r env_var="$2"

  vedv::vmobj_service::add_environment_var \
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
vedv::image_service::get_environment_vars() {
  local -r image_id="$1"

  vedv::vmobj_service::get_environment_vars \
    'image' \
    "$image_id"
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
#   vedvfile      string  Vedvfile full path
#   [image_name]  string  name of the image
#   [force]       bool    force the build, removing child containers if the image has
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::build() {
  vedv::image_builder::build "$@"
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
vedv::image_service::add_exposed_ports() {
  local -r image_id="$1"
  local -r ports="$2"

  vedv::vmobj_service::add_exposed_ports \
    'image' \
    "$image_id" \
    "$ports"
}

#
# Get expose ports from image
#
# Arguments:
#   image_name_or_id  string    image id
#
# Output:
#   writes expose ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::list_exposed_ports() {
  local -r image_name_or_id="$1"

  vedv::vmobj_service::list_exposed_ports \
    'image' \
    "$image_name_or_id"
}
