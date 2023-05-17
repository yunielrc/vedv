#
# Manage containers
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './container-entity.bash'
  . './../__base/vmobj-service.bash'
  . '../image/image-entity.bash'
  . '../image/image-service.bash'
  . './../../ssh-client.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#  ssh_ip string    ssh ip address
#
# Returns:
#   0 on success, non-zero on error.
#
# vedv::container_service::constructor() {

# }

#
# Create a new container
#
# Arguments:
#   image           string  image name or an OVF file
#   container_name  string  container name
#
# Output:
#  Writes container ID to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::create() {
  local -r image="$1"
  local container_name="${2:-}"

  if [[ -z "$image" ]]; then
    err "Invalid argument 'image': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -n "$container_name" ]]; then
    local exists_container
    exists_container="$(vedv::vmobj_service::exists_with_name 'container' "$container_name")" || {
      err "Failed to check if container with name: '${container_name}' already exist"
      return "$ERR_CONTAINER_OPERATION"
    }
    readonly exists_container

    if [[ "$exists_container" == true ]]; then
      err "Container with name: '${container_name}' already exist"
      return "$ERR_CONTAINER_OPERATION"
    fi
  fi

  local image_name

  if [[ -f "$image" ]]; then
    image_name="$(petname)" || {
      err "Failed to generate a random name"
      return "$ERR_CONTAINER_OPERATION"
    }
    vedv::image_service::pull "$image" "$image_name" &>/dev/null || {
      err "Failed to pull image: '${image}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  else
    image_name="$image"
  fi
  readonly image_name

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name_by_image_name "$image_name")" || {
    err "Failed to get image vm name for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image: '${image_name}' does not exist"
    return "$ERR_NOT_FOUND"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::gen_vm_name "$container_name")" || {
    err "Failed to generate container vm name for container: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  # create a vm snapshoot, the snapshoot is the container
  local image_id
  image_id="$(vedv::image_entity::get_id_by_vm_name "$image_vm_name")" || {
    err "Failed to get image id for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_id

  local last_layer_id
  last_layer_id="$(vedv::image_entity::get_last_layer_id "$image_id")" || {
    err "Failed to get last image layer id for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly last_layer_id

  local layer_vm_snapshot_name=''

  if [[ -n "$last_layer_id" ]]; then
    layer_vm_snapshot_name="$(vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$last_layer_id")" || {
      err "Failed to get image layer snapshot name for image: '$image_name'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi
  readonly layer_vm_snapshot_name

  vedv::hypervisor::clonevm_link "$image_vm_name" "$container_vm_name" "$layer_vm_snapshot_name" &>/dev/null || {
    err "Failed to clone vm: '$image_vm_name' to: '$container_vm_name'"
    return "$ERR_CONTAINER_OPERATION"
  }

  if [[ -z "$container_name" ]]; then
    container_name="$(vedv::container_entity::get_container_name_by_vm_name "$container_vm_name")" || {
      err "Failed to get container name for vm: '${container_vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
    readonly container_name
  fi

  local container_id
  container_id="$(vedv::container_entity::get_id_by_vm_name "$container_vm_name")" || {
    err "Failed to get container id for vm: '${container_vm_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_id

  vedv::container_entity::set_parent_image_id "$container_id" "$image_id" || {
    err "Failed to set parent image id for container: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  echo "$container_name"
}

#
# Tell if a container is started
#
# Arguments:
#   container_id string       container id
#
# Output:
#  Writes true if started otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::is_started() {
  vedv::vmobj_service::is_started 'container' "$@"
}

#
# Start one or more containers by name or id
#
# Arguments:
#   containers_name_or_id     containers name or id
#
# Output:
#  writes started containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::start() {
  vedv::vmobj_service::start 'container' true "$@"
}

#
# Start one or more containers by name or id
# without waiting for ssh to be started
#
# Arguments:
#   containers_name_or_id     containers name or id
#
# Output:
#  writes started containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::start_no_wait_ssh() {
  vedv::vmobj_service::start 'container' false "$@"
}

#
#  Stop securely one or more running containers by name or id
#
# Arguments:
#   containers_name_or_id     containers name or id
#
# Output:
#  writes stopped containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::stop() {
  vedv::vmobj_service::stop 'container' true "$@"
}

#
#  Remove a container
#
# Arguments:
#   container_id  string     container id
#   force         bool       force remove container
#
# Output:
#  writes removed container id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove_one() {
  local -r container_id="$1"
  local -r force="${2:-false}"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$force" ]]; then
    err "Invalid argument 'force': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::get_vm_name "$container_id")" || {
    err "Failed to get vm name for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  if [[ -z "$container_vm_name" ]]; then
    err "There is no container with id '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  local parent_image_id
  parent_image_id="$(vedv::container_entity::get_parent_image_id "$container_id")" || {
    err "Failed to get parent image id for container '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly parent_image_id

  if [[ -z "$parent_image_id" ]]; then
    err "No 'parent_image_id' for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  # If the container that is being removed (CBR) has siblings running containers
  # (SRC) with a snapshot on the parent image that was created after the snapshot
  # of the CBR, then we can't remove the CBR snapshot because it's being used
  # by the SRC and the hypervisor fails doing the CBR snapshot removal.
  #
  # The solution is to stop all the SRC and then remove the CBR snapshot.
  #
  local running_siblings_ids
  running_siblings_ids="$(vedv::container_service::__get_running_siblings_ids "$container_id")" || {
    err "Failed to get running siblings ids for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly running_siblings_ids

  if [[ -n "$running_siblings_ids" ]]; then

    if [[ "$force" == false ]]; then
      err "Can't remove container: '${container_id}' because it has running sibling containers"
      err "You can Use the 'force' flag to stop them automatically and remove the container"
      err "Or you can stop them manually and then remove the container"
      err "Sibling containers ids: '${running_siblings_ids}'"
      return "$ERR_CONTAINER_OPERATION"
    fi
    # shellcheck disable=SC2086
    vedv::container_service::stop $running_siblings_ids >/dev/null || {
      err "Failed to stop some sibling container"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  vedv::hypervisor::rm "$container_vm_name" &>/dev/null || {
    err "Failed to remove container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  local parent_image_vm_name
  parent_image_vm_name="$(vedv::image_entity::get_vm_name "$parent_image_id")" || {
    err "Failed to get vm name for parent image id: '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly parent_image_vm_name

  vedv::hypervisor::delete_snapshot "$parent_image_vm_name" "$container_vm_name" &>/dev/null || {
    err "Failed to delete snapshot of container '${container_id}' on parent image '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  echo "$container_id"
}

#
#  Remove a container
#
# Arguments:
#   force         bool       force remove container
#   container_id  string     container id
#
# Output:
#  writes removed container id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove_one_batch() {
  local -r force="$1"
  local -r container_id="$2"

  vedv::container_service::remove_one "$container_id" "$force"
}

#
# Get the running sibling containers ids of a container
#
# Arguments:
#   container_id  string     container id
#
# Output:
#  writes running sibling containers ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__get_running_siblings_ids() {
  local -r container_id="$1"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local parent_image_id
  parent_image_id="$(vedv::container_entity::get_parent_image_id "$container_id")" || {
    err "Failed to get parent image id for container '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly parent_image_id

  if [[ -z "$parent_image_id" ]]; then
    err "No 'parent_image_id' for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  local image_childs_ids
  image_childs_ids="$(vedv::image_entity::get_child_containers_ids "$parent_image_id")" || {
    err "Failed to get child containers ids for image: '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_childs_ids

  if [[ -z "$image_childs_ids" ]]; then
    err "No child containers ids for image: '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi
  # shellcheck disable=SC2206
  local -a image_childs_ids_arr=($image_childs_ids)

  local -a running_siblings_ids_arr=()

  for image_child_id in "${image_childs_ids_arr[@]}"; do

    if [[ "$image_child_id" == "$container_id" ]]; then
      continue
    fi

    local is_started
    is_started="$(vedv::container_service::is_started "$image_child_id")" || {
      err "Failed to check if container is started: '${image_child_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }

    if [[ "$is_started" == true ]]; then
      running_siblings_ids_arr+=("$image_child_id")
    fi
  done

  echo "${running_siblings_ids_arr[*]}"
}

#
# Remove one or more containers by name or id
#
# Arguments:
#   force         bool       force remove container (true|false)
#   containers_name_or_id string     containers name or id
#
# Output:
#  writes removed containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove() {
  local -r force="$1"
  # validate arguments
  if [[ -z "$force" ]]; then
    err "Invalid argument 'force': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  shift

  vedv::vmobj_service::exec_func_on_many_vmobj \
    'container' \
    "vedv::container_service::remove_one_batch ${force}" \
    "$@"
}

#
#  List containers
#
# Arguments:
#   [list_all]      bool       default: false, list running containers
#   [partial_name]  string     name of the exported VM
#
# Output:
#  writes image id, name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::list() {
  local -r list_all="${1:-false}"
  local -r partial_name="${2:-}"

  vedv::vmobj_service::list \
    'container' \
    "$list_all" \
    "$partial_name"
}

#
# Execute cmd in a container
#
# Arguments:
#   container_id_or_name  string    container id or name
#   cmd                   string    command to execute
#   [user]                string    user name
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::execute_cmd() {
  local -r container_id_or_name="$1"
  local -r cmd="$2"
  local -r user="${3:-}"

  vedv::vmobj_service::execute_cmd \
    'container' \
    "$container_id_or_name" \
    "$cmd" \
    "$user"
}

#
# Establish a ssh connection to a container
#
# Arguments:
#   container_id_or_name  string     container id or name
#   [user]                string     container user
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::connect() {
  local -r container_id_or_name="$1"
  local -r user="${2:-}"

  vedv::vmobj_service::connect 'container' "$container_id_or_name" "$user"
}

#
# Copy files from local filesystem to a container
#
# Arguments:
#   container_id_or_name  string     container id or name
#   src                   string     local source path
#   dest                  string     container destination path
#   [user]                string     container user
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::copy() {
  local -r container_id_or_name="$1"
  local -r src="$2"
  local -r dest="$3"
  local -r user="${4:-}"

  vedv::vmobj_service::copy \
    'container' \
    "$container_id_or_name" \
    "$src" \
    "$dest" \
    "$user"
}
