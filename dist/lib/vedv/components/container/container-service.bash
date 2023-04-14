#
# Manage containers
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
  . '../image/image-service.bash'
  . '../image/image-entity.bash'
  . './../../ssh-client.bash'
  . './container-entity.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::constructor() {
  :
}

#
# Create a new container
#
# Arguments:
#   image                image name or an OVF file
#   container_name       container name
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
    exists_container="$(vedv::container_service::__exits_with_name "$container_name")" || {
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
      err "Failed to pull image: '$image'"
      return "$ERR_CONTAINER_OPERATION"
    }
  else
    image_name="$image"
  fi
  readonly image_name

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name_by_image_name "$image_name")" || {
    err "Failed to get image vm name for image: '$image_name'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image: '${image_name}' does not exist"
    return "$ERR_NOT_FOUND"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::gen_vm_name "$container_name")"
  readonly container_vm_name

  # create a vm snapshoot, the snapshoot is the container
  local image_id
  image_id="$(vedv::image_entity::get_id_by_image_name "$image_name")" || {
    err "Failed to get image id for image: '$image_name'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_id

  local last_layer_id
  last_layer_id="$(vedv::image_entity::get_last_layer_id "$image_id")" || {
    err "Failed to get last image layer id for image: '$image_name'"
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

  vedv::hypervisor::set_description "$container_vm_name" "$image_vm_name" || {
    err "Failed to set description for vm: '$container_vm_name'"
    return "$ERR_CONTAINER_OPERATION"
  }

  if [[ -z "$container_name" ]]; then
    container_name="$(vedv::container_entity::get_container_name_by_vm_name "$container_vm_name")" || {
      err "Failed to get container name for vm: '$container_vm_name'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  echo "$container_name"
}

#
# Execute an operation (function) upon one or more stopped containers
#
# Arguments:
#   container_name_or_ids     container name or id
#
# Output:
#  writes container name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__execute_operation_upon_containers() {
  # TODO: this is ambiguous, put flag run the operation by id
  # And if it happens that you want to run by id and a container has that id as its name?
  local -r operation="${1:-}"

  if [[ -z "$operation" ]]; then
    err "Invalid argument 'operation': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  shift

  local -ra container_name_or_ids=("$@")

  local -r valid_operations='start|stop|rm'

  if [[ "$operation" != @($valid_operations) ]]; then
    err "Invalid operation: ${operation}, valid operations are: ${valid_operations}"
    return "$ERR_INVAL_ARG"
  fi

  if [[ "${#container_name_or_ids[@]}" -eq 0 ]]; then
    err 'At least one container is required'
    return "$ERR_INVAL_ARG"
  fi

  local -A containers_failed=()

  local vm_name
  ___assign_vm_name_by_partial_name() {
    local -r __partial_name="$1"

    vm_name="$(vedv::hypervisor::list_vms_by_partial_name "$__partial_name")" || {
      err "Failed to get vm name for container: '${container}'"
      return "$ERR_CONTAINER_OPERATION"
    }
    vm_name="$(head -n 1 <<<"$vm_name" || :)"
  }

  for container in "${container_name_or_ids[@]}"; do
    ___assign_vm_name_by_partial_name "container:${container}|"

    if [[ -z "$vm_name" ]]; then
      ___assign_vm_name_by_partial_name "|crc:${container}|"

      if [[ -z "$vm_name" ]]; then
        containers_failed['No such containers']+="$container "
        continue
      fi
    fi

    local container_image_vm_name=''

    if [[ "$operation" == 'rm' ]]; then
      container_image_vm_name="$(vedv::hypervisor::get_description "$vm_name")" || {
        containers_failed["Failed to get vm description for containers"]+="$container "
        continue
      }

      if [[ -z "$container_image_vm_name" ]]; then
        containers_failed["no 'container_image_vm_name' for containers"]+="$container "
        continue
      fi
    fi

    vedv::hypervisor::"$operation" "$vm_name" &>/dev/null || {
      containers_failed["Failed to ${operation} containers"]+="$container "
      continue
    }

    if [[ "$operation" == 'rm' ]]; then
      vedv::hypervisor::delete_snapshot "$container_image_vm_name" "$vm_name" &>/dev/null || {
        containers_failed["Failed to delete snapshot for containers"]+="$container "
        continue
      }
    fi

    echo -n "$container "
  done

  echo
  for err_msg in "${!containers_failed[@]}"; do
    err "${err_msg}: ${containers_failed["$err_msg"]}"
  done

  if [[ "${#containers_failed[@]}" -ne 0 ]]; then
    return "$ERR_CONTAINER_OPERATION"
  fi

  return 0
}

#
# Start one or more stopped containers
#
# Arguments:
#   container_name_or_ids     container name or id
#
# Output:
#  writes container name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::start() {
  vedv::container_service::__execute_operation_upon_containers start "$@"
}

#
#  Stop one or more running containers
#
# Arguments:
#   container_name_or_ids     container name or id
#
# Output:
#  writes container name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::stop() {
  vedv::container_service::__execute_operation_upon_containers stop "$@"
}

#
#  Remove one or more running containers
#
# Arguments:
#   container_name_or_ids     container name or id
#
# Output:
#  writes container name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::rm() {
  vedv::container_service::__execute_operation_upon_containers rm "$@"
}

#
#  List containers
#
# Arguments:
#   [list_all]               default: false, list running containers
#   [partial_name]           name of the exported VM
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

  local hypervisor_cmd='list_running'

  if [[ "$list_all" == true ]]; then
    hypervisor_cmd='list'
  fi
  readonly hypervisor_cmd

  local vm_names

  if [[ -n "$partial_name" ]]; then
    vm_names="$(vedv::hypervisor::"$hypervisor_cmd")" || {
      err "Failed to list containers"
      return "$ERR_CONTAINER_OPERATION"
    }
    vm_names="$(grep "container:${partial_name}.*|" <<<"$vm_names" || :)"
  else
    vm_names="$(vedv::hypervisor::"$hypervisor_cmd")" || {
      err "Failed to list containers"
      return "$ERR_CONTAINER_OPERATION"
    }
    vm_names="$(grep "container:.*|" <<<"$vm_names" || :)"
  fi
  readonly vm_names

  for vm_name in $vm_names; do
    local container_id container_name

    container_id="$(vedv::container_entity::get_container_id_by_vm_name "$vm_name")" || {
      err "Failed to get container id for vm: '${vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
    container_name="$(vedv::container_entity::get_container_name_by_vm_name "$vm_name")" || {
      err "Failed to get container name for vm: '${vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
    echo "${container_id} ${container_name}"
  done
}

#
#  Exists container with name
#
# Arguments:
#  container_name           container name
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__exits_with_name() {
  local -r container_name="$1"
  # validate argument
  if [[ -z "$container_name" ]]; then
    err "Argument 'container_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  local output
  output="$(vedv::hypervisor::exists_vm_with_partial_name "container:${container_name}|")" || {
    err "Hypervisor failed to check if container with name '${container_name}' exists"
    return "$ERR_CONTAINER_OPERATION"
  }

  echo "$output"
}

# IMPL: Create and run a container from an image
vedv::container_service::run() {
  echo 'vedv::container_service::run'
}
