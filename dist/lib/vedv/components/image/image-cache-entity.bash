# Image Cache Entity
#
# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# +----------------------------+
# |    image-cache             |
# +----------------------------+
# | - id: string               |
# +----------------------------+
vedv::image_cache_entity::constructor() {
  readonly __VEDV_IMAGE_CACHE_ENTITY_HYPERVISOR="$1"
}

#
# Validate vm name
#
# Arguments:
#   vm_name string   name to validate
#
# Returns:
#   0 if valid, 1 if invalid
#
vedv::image_cache_entity::validate_vm_name() {
  local -r vm_name="$1"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  local -r name_pattern="$UTILS_REGEX_NAME"
  local -r pattern="^image-cache\|crc:${name_pattern}\|\$"

  if [[ ! "$vm_name" =~ $pattern ]]; then
    err "Invalid image vm name: '${vm_name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Get the vm name of an image
#
# Arguments:
#   image_id string     image id
#
# Output:
#  writes image vm name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_cache_entity::get_vm_name() {
  local -r image_id="$1"

  utils::validate_name_or_id "$image_id" || return "$?"
  # TODO: solve, this way mask the errors
  vedv::"$__VEDV_IMAGE_CACHE_ENTITY_HYPERVISOR"::list_wms_by_partial_name "|crc:${image_id}|" | head -n 1
}

#
# Get image id from image vm name
#
# Arguments:
#   image_vm_name string       image vm name
#
# Output:
#  Writes image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_cache_entity::get_image_id_by_vm_name() {
  local -r image_vm_name="$1"

  vedv::image_cache_entity::validate_vm_name "$image_vm_name" || return "$?"

  local result="${image_vm_name#*'|crc:'}"
  echo "${result%'|'}"
}
