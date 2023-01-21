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
  local -r container_name="${2:-}"

  # Import an OVF from a file or url
  local -r image_vm_name=$(vedv::image_service::pull "$image")
  local -r container_vm_name="$(vedv::container_service::__gen_container_vm_name "$container_name")"

  if [[ -n "$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$container_vm_name")" ]]; then
    err "container with name: '${container_name}' already exist"
    return "$ERR_VM_EXIST"
  fi

  # create a vm snapshoot, the snapshoot is the container
  local output
  local -i ecode=0
  output="$(vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::clonevm_link "$image_vm_name" "$container_vm_name" 2>&1)" || ecode=$?

  if [[ $ecode -eq 0 ]]; then
    echo "$container_vm_name"
  else
    err "$output"
  fi

  return $ecode
}

# IMPL: Start one or more stopped containers
vedv::container_service::start() {
  echo 'vedv::container_service::start'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::start
}

#  IMPL: Stop one or more running containers
vedv::container_service::stop() {
  echo 'vedv::container_service::stop'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::stop
}

# IMPL: Remove one or more containers
vedv::container_service::rm() {
  echo 'vedv::container_service::rm'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::rm
}

# IMPL: Create and run a container from an image
vedv::container_service::run() {
  echo 'vedv::container_service::run'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::run
}
