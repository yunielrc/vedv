#
# Manage containers
#
#

# REQUIRE
# . '../../utils.bash'
# . '../image/image-service.bash'

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   hypervisor       name of the script
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::constructor() {
  readonly __VEDV_CONTAINER_SERVICE_HYPERVISOR="$1"
}

#
# Generate container vm name from a image vm name
#
# Arguments:
#   image_vm_name     image name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__gen_container_vm_name_from_image_vm_name() {
  local -r image_vm_name="$1"

  local container_name="${image_vm_name#'image:'}"
  container_name="${container_name%'|crc'*}"

  local -r crc_sum="$(echo "$container_name" | cksum | cut -d' ' -f1)"
  local -r container_vm_name="container:${container_name}|crc:${crc_sum}"

  echo "$container_vm_name"
}

#
# Generate container vm name
#
# Arguments:
#   [container_name]       container name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__gen_container_vm_name() {
  local container_name="${1:-}"

  if [[ -z "$container_name" ]]; then
    container_name="$(petname)"
  fi

  local -r crc_sum="$(echo "$container_name" | cksum | cut -d' ' -f1)"
  local -r container_vm_name="container:${container_name}|crc:${crc_sum}"

  echo "$container_vm_name"
}

#
# Get container name from container vm name
#
# Arguments:
#   container_vm_name       container vm name
#
# Output:
#  Writes container name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::_get_container_name() {
  local -r container_vm_name="$1"

  local container_name="${container_vm_name#'container:'}"
  container_name="${container_name%'|crc:'*}"
  echo "$container_name"
}

# Get container id from container vm name
#
# Arguments:
#   container_vm_name       container vm name
#
# Output:
#  Writes container id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::_get_container_id() {
  local -r container_vm_name="$1"

  echo "${container_vm_name#*'|crc:'}"
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

  # Import an OVF from a file or url
  local image_name
  image_name=$(vedv::image_service::pull "$image")
  readonly image_name
  local -r image_vm_name="$(vedv::"${__VEDV_CONTAINER_SERVICE_HYPERVISOR}"::list_wms_by_partial_name "image:${image_name}|" | head -n 1)"

  local container_vm_name
  container_vm_name="$(vedv::container_service::__gen_container_vm_name "$container_name")"
  readonly container_vm_name

  if [[ -n "$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$container_vm_name")" ]]; then
    err "container with name: '${container_name}' already exist"
    return "$ERR_VM_EXIST"
  fi

  # create a vm snapshoot, the snapshoot is the container
  local output
  local -i ecode=0
  output="$(vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::clonevm_link "$image_vm_name" "$container_vm_name" 2>&1)" || ecode=$?

  if [[ $ecode -eq 0 ]]; then

    [[ -z "$container_name" ]] &&
      container_name="$(vedv::container_service::_get_container_name "$container_vm_name")"

    echo "$container_name"
  else
    err "$output"
  fi

  return $ecode
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

  for container in "${container_name_or_ids[@]}"; do
    local vm_name="$(vedv::"${__VEDV_CONTAINER_SERVICE_HYPERVISOR}"::list_wms_by_partial_name "container:${container}|" | head -n 1)"

    if [[ -z "$vm_name" ]]; then
      vm_name="$(vedv::"${__VEDV_CONTAINER_SERVICE_HYPERVISOR}"::list_wms_by_partial_name "|crc:${container}" | head -n 1)"

      if [[ -z "$vm_name" ]]; then
        containers_failed['No such containers']+="$container "
        continue
      fi
    fi

    if ! vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::"$operation" "$vm_name" &>/dev/null; then
      containers_failed["Failed to ${operation} containers"]+="$container "
      continue
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
  # FIXME: to remove running containers must require a `force` flag
  # FIXME: remove deleted container parent image snapshot
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
    vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::"$hypervisor_cmd")"
    vm_names="$(echo "$vm_names" | grep "container:${partial_name}.*|" || :)"
  else
    vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::"$hypervisor_cmd")"
    vm_names="$(echo "$vm_names" | grep "container:.*|" || :)"
  fi
  readonly vm_names

  for vm_name in $vm_names; do
    echo "$(vedv::container_service::_get_container_id "$vm_name") $(vedv::container_service::_get_container_name "$vm_name")"
  done
}

# IMPL: Create and run a container from an image
vedv::container_service::run() {
  echo 'vedv::container_service::run'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::run
}
