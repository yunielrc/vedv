#
# Manage images
#
#

# REQUIRE
# . '../../utils.bash'

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
vedv::image_service::constructor() {
  readonly __VEDV_IMAGE_SERVICE_HYPERVISOR="$1"
}

#
# Get image name from image vm name
#
# Arguments:
#   image_vm_name       image vm name
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::_get_image_name() {
  local -r image_vm_name="$1"

  local image_name="${image_vm_name#'image:'}"
  image_name="${image_name%'|crc:'*}"
  echo "$image_name"
}

# Get image id from image vm name
#
# Arguments:
#   image_vm_name       image vm name
#
# Output:
#  Writes image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::_get_image_id() {
  local -r image_vm_name="$1"

  echo "${image_vm_name#*'|crc:'}"
}

#
# Generate a vm name from OVA image file
#
# Arguments:
#   image_file      OVA file image
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__gen_vm_name() {
  local -r image_file="$1"

  if [[ -z "$image_file" ]]; then
    err "Invalid argument 'image_file': ${image_file}"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name="${image_file,,}"
  vm_name="${vm_name%.ova}"
  local -r crc_sum="$(cksum "$image_file" | cut -d' ' -f1)"
  vm_name="image:${vm_name##*/}|crc:${crc_sum}"

  echo "$vm_name"
}

#
# Import an OVA image from file
#
# Arguments:
#   image_file      OVF file image
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__pull_from_file() {
  local -r image_file="$1"

  if [[ ! -f "$image_file" ]]; then
    err "OVA file image doesn't exist"
    return "$ERR_NOFILE"
  fi

  local -r vm_name="$(vedv::image_service::__gen_vm_name "$image_file")"
  local -r image_id="$(vedv::image_service::_get_image_id "$vm_name")"
  local -r image_name="$(vedv::image_service::_get_image_name "$vm_name")"

  if [[ -n "$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "|crc:${image_id}")" ]]; then
    echo "$image_name"
    return 0
  fi

  # Import an OVF from a file
  local output
  local -i ecode=0
  output="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::import "$image_file" "$vm_name" 2>&1)" || ecode=$?

  if [[ $ecode -eq 0 ]]; then
    echo "$image_name"
  else
    err "$output"
  fi

  return $ecode
}

# Pull an OVF image from a registry or file
#
# Arguments:
#   image      image name or an OVF file
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::pull() {
  # IMPL: test this function
  local -r image="$1"

  if [[ -f "${image:-}" ]]; then
    vedv::image_service::__pull_from_file "$image"
  else
    # IMPL: Pull an OVF image from a registry
    err "Not implemented: 'vedv::image_service::__pull_from_registry'"
    return "$ERR_NOTIMPL"
  fi
}

# IMPL: Pull an image or a repository from a registry
vedv::image_service::import() {
  echo 'vedv:image:pull'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::pull
}

# IMPL: Build an image from a Vedvfile
vedv::image_service::build() {
  echo 'vedv:image:build'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::build
}
