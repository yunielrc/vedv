#
# Container Entity
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# +----------------------------+
# |    container               |
# +----------------------------+
# | - id: string               |
# | - name: string             |
# +----------------------------+
vedv::container_entity::constructor() {
  readonly __VEDV_CONTAINER_ENTITY_HYPERVISOR="$1"
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
vedv::container_entity::__validate_vm_name() {
  local -r vm_name="$1"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  local -r name_pattern="$UTILS_REGEX_NAME"
  local -r pattern="^container:${name_pattern}\|crc:${name_pattern}\|\$"

  if [[ ! "$vm_name" =~ $pattern ]]; then
    err "Invalid container vm name: '${vm_name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Generate container vm name
#
# Arguments:
#   [container_name string]       container name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::gen_vm_name() {
  local container_name="${1:-}"

  if [[ -z "$container_name" ]]; then
    container_name="$(petname)" || {
      err "Failed to generate a random name"
      return "$ERR_CONTAINER_ENTITY"
    }
  fi

  local -r crc_sum="$(echo "$container_name" | utils::crc_sum)"

  echo "container:${container_name}|crc:${crc_sum}|"
}

#
# Get the vm name of a container
#
# Arguments:
#   container_id string     container id
#
# Output:
#  writes container vm name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_vm_name() {
  local -r container_id="$1"

  utils::validate_name_or_id "$container_id" || return "$?"

  local vms
  vms="$(vedv::"$__VEDV_CONTAINER_ENTITY_HYPERVISOR"::list_wms_by_partial_name "|crc:${container_id}|")" || {
    err "Failed to get vm name of container: ${container_id}"
    return "$ERR_CONTAINER_ENTITY"
  }

  head -n 1 <<<"$vms"
}

#
# Get the vm name of a container if exists
#
# Arguments:
#   container_name string     container name
#
# Output:
#  writes container vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_vm_name_by_container_name() {
  local -r container_name="$1"
  utils::validate_name_or_id "$container_name" || return "$?"

  local vm_name
  vm_name="$(vedv::"$__VEDV_CONTAINER_ENTITY_HYPERVISOR"::list_wms_by_partial_name "container:${container_name}|")" || {
    err "Failed to get vm name of container: ${container_name}"
    return "$ERR_IMAGE_ENTITY"
  }

  head -n 1 <<<"$vm_name"
}

#
# Get container name from vm name
#
# Arguments:
#   container_vm_name string       container vm name
#
# Output:
#  Writes container_name string to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_container_name_by_vm_name() {
  local -r container_vm_name="$1"
  # validate arguments
  vedv::container_entity::__validate_vm_name "$container_vm_name" || return "$?"

  local container_name="${container_vm_name#'container:'}"
  container_name="${container_name%'|crc:'*}"
  echo "$container_name"
}

#
# Get container id from container vm name
#
# Arguments:
#   container_vm_name string       container vm name
#
# Output:
#  Writes container_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_container_id_by_vm_name() {
  local -r container_vm_name="$1"

  vedv::container_entity::__validate_vm_name "$container_vm_name" || return "$?"

  local result="${container_vm_name#*'|crc:'}"
  echo "${result%'|'}"
}

#
# Get container id by container name
#
# Arguments:
#   container_name string       container name
#
# Output:
#  Writes container_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_id_by_container_name() {
  local -r container_name="$1"

  utils::validate_name_or_id "$container_name" || return "$?"

  local container_vm_name
  container_vm_name="$(vedv::container_entity::get_vm_name_by_container_name "$container_name")"
  readonly container_vm_name

  if [[ -z "$container_vm_name" ]]; then
    err "Container with name '${container_name}' not found"
    return "$ERR_NOT_FOUND"
  fi

  local container_id
  container_id="$(vedv::container_entity::get_container_id_by_vm_name "$container_vm_name")"
  readonly container_id

  echo "$container_id"
}
