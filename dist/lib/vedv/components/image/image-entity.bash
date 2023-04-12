# Image Entity
#
# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# +----------------------------+
# |    image                   |
# +----------------------------+
# | - id: string               |
# | - name: string             |
# | - ova_file_sum: string     |
# | - image_cache: string      |
# | - layers_ids: string[]     |
# | - containers_ids: integer[]|
# +----------------------------+
vedv::image_entity::constructor() {
  readonly __VEDV_IMAGE_ENTITY_HYPERVISOR="$1"
}

#
# Validate attribute
#
# Arguments:
#   attribute string   attribute to validate (image_cache|ova_file_sum|ssh_port)
#
# Returns:
#   0 if valid, non-zero value if invalid
#
vedv::image_entity::__validate_attribute() {
  local -r attribute="$1"
  # validate arguments
  if [[ -z "$attribute" ]]; then
    err "Argument 'attribute' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  local -r valid_attributes='image_cache|ova_file_sum|ssh_port'

  if [[ "$attribute" != @($valid_attributes) ]]; then
    err "Invalid attribute: ${attribute}, valid attributes are: ${valid_attributes}"
    return "$ERR_INVAL_ARG"
  fi
  return 0
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
vedv::image_entity::validate_vm_name() {
  local -r vm_name="$1"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  local -r name_pattern="$UTILS_REGEX_NAME"
  local -r pattern="^image:${name_pattern}\|crc:${name_pattern}\|\$"

  if [[ ! "$vm_name" =~ $pattern ]]; then
    err "Invalid image vm name: '${vm_name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Generate a vm name from OVA image file
#
# Arguments:
#   image_file string      OVA file image
#
# Output:
#  Writes generated vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::gen_vm_name_from_ova_file() {
  local -r image_file="$1"

  if [[ -z "$image_file" ]]; then
    err "Invalid argument 'image_file': ${image_file}"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name="${image_file,,}"
  vm_name="${vm_name%.ova}"

  local -r crc_sum="$(utils::crc_file_sum "$image_file")"
  vm_name="image:${vm_name##*/}|crc:${crc_sum}|"

  echo "$vm_name"
}

#
# Generate image vm name
#
# Arguments:
#   [image_name string]       image name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::gen_vm_name() {
  local image_name="${1:-}"

  if [[ -z "$image_name" ]]; then
    image_name="$(petname)"
  fi

  local -r crc_sum="$(echo "$image_name" | utils::crc_sum)"

  echo "image:${image_name}|crc:${crc_sum}|"
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
vedv::image_entity::get_vm_name() {
  local -r image_id="$1"

  utils::validate_name_or_id "$image_id" || return "$?"

  vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::list_wms_by_partial_name "|crc:${image_id}|" | head -n 1
}

#
# Get the vm name of an image if exists
#
# Arguments:
#   image_name string     image name
#
# Output:
#  writes image vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_vm_name_by_image_name() {
  local -r image_name="$1"
  utils::validate_name_or_id "$image_name" || return "$?"

  local vm_name
  vm_name="$(vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::list_wms_by_partial_name "image:${image_name}|")" || {
    err "Failed to get vm name of image: ${image_name}"
    return "$ERR_IMAGE_ENTITY"
  }

  head -n 1 <<<"$vm_name"
}

#
# Get image name from vm name
#
# Arguments:
#   image_vm_name string       image vm name
#
# Output:
#  Writes image_name string to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_image_name_by_vm_name() {
  local -r image_vm_name="$1"
  # validate arguments
  vedv::image_entity::validate_vm_name "$image_vm_name" || return "$?"

  local image_name="${image_vm_name#'image:'}"
  image_name="${image_name%'|crc:'*}"
  echo "$image_name"
}

#
# Get image id from image vm name
#
# Arguments:
#   image_vm_name string       image vm name
#
# Output:
#  Writes image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_image_id_by_vm_name() {
  local -r image_vm_name="$1"

  vedv::image_entity::validate_vm_name "$image_vm_name" || return "$?"

  local result="${image_vm_name#*'|crc:'}"
  echo "${result%'|'}"
}

#
# Get image id by image name
#
# Arguments:
#   image_name string       image name
#
# Output:
#  Writes image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_id_by_image_name() {
  local -r image_name="$1"

  utils::validate_name_or_id "$image_name" || return "$?"

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name_by_image_name "$image_name")"
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image with name '${image_name}' not found"
    return "$ERR_NOT_FOUND"
  fi

  local image_id
  image_id="$(vedv::image_entity::get_image_id_by_vm_name "$image_vm_name")"
  readonly image_id

  echo "$image_id"
}

#
# Set attribute value
#
# Arguments:
#   image_id  string       image id
#   attribute  string      attribute
#   value  string          value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::__set_attribute() {
  local -r image_id="$1"
  local -r attribute="$2"
  local -r value="$3"

  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  vedv::image_entity::__validate_attribute "$attribute" || return "$?"

  eval "local -r _${attribute}='${value}'"

  local -r image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")"
  local -r description="$(vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::get_description "$image_vm_name")"
  # the subshell avoid loading global variables
  (
    eval "$description"

    local updated_description="image_cache='${_image_cache:-"${image_cache:-}"}'
ova_file_sum='${_ova_file_sum:-"${ova_file_sum:-}"}'
ssh_port=${_ssh_port:-"${ssh_port:-}"}"

    vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::set_description "$image_vm_name" "$updated_description"
  )
}

#
# Get attribute value
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes attribute (string) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::__get_attribute() {
  local -r image_id="$1"
  local -r attribute="$2"

  utils::validate_name_or_id "$image_id" || return "$?"
  vedv::image_entity::__validate_attribute "$attribute" || return "$?"

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Error getting the vm name for the image id: '${image_id}'"
    return "$ERR_NOT_FOUND"
  }
  readonly image_vm_name
  # validate vm name
  vedv::image_entity::validate_vm_name "$image_vm_name" || return "$?"

  (
    local description
    description="$(vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::get_description "$image_vm_name")" || {
      err "Error getting the description for the image vm name: '${image_vm_name}'"
      return "$ERR_NOT_FOUND"
    }
    readonly description

    if [[ -z "$description" ]]; then
      err "Description for the image vm name: '${image_vm_name}' is empty"
      return "$ERR_INVAL_VALUE"
    fi

    . <(echo "$description")
    echo "${!attribute:-}"
  )
}

#
# Get ova_file_sum value
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes ova_file_sum (string) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_ova_file_sum() {
  local -r image_id="$1"

  vedv::image_entity::__get_attribute "$image_id" 'ova_file_sum'
}

#
# Set ova_file_sum value
#
# Arguments:
#   image_id  string       image id
#   ova_file_sum  string   ova file sum
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::set_ova_file_sum() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::image_entity::__set_attribute "$image_id" 'ova_file_sum' "$value"
}

#
# Get image_cache value
#
# Arguments:
#   image_id  string       image id
#
# Output:
#  Writes image_cache (string) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_image_cache() {
  local -r image_id="$1"

  vedv::image_entity::__get_attribute "$image_id" 'image_cache'
}

#
# Set image_cache value
#
# Arguments:
#   image_id  string       image id
#   image_cache string    image cache
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::set_image_cache() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::image_entity::__set_attribute "$image_id" 'image_cache' "$value"
}

#
# Get ssh_port value
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes ssh_port (int) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_ssh_port() {
  local -r image_id="$1"

  vedv::image_entity::__get_attribute "$image_id" 'ssh_port'
}

#
# Set ssh_port value
#
# Arguments:
#   image_id  string       image id
#   ssh_port  int          ssh port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::set_ssh_port() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::image_entity::__set_attribute "$image_id" 'ssh_port' "$value"
}

#
# Get snapshots names
#
# Arguments:
#   image_id  string       image id
#    [_type]  string       type of the child
#                          (e.g. container|layer, default is empty)
# Output:
#  Writes child containers_ids (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::__get_snapshots_names() {
  local -r image_id="$1"
  local -r _type="${2:-}"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$_type" ]]; then
    err "Argument '_type' is required"
    return "$ERR_INVAL_ARG"
  fi

  local -r valid_types='container|layer'

  if [[ "$_type" != @($valid_types) ]]; then
    err "Invalid type: ${_type}, valid values are: ${valid_types}"
    return "$ERR_INVAL_ARG"
  fi

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get image vm name for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image vm name for image '${image_id}' is empty"
    return "$ERR_IMAGE_OPERATION"
  fi

  local snapshot_names
  snapshot_names="$(vedv::"$__VEDV_IMAGE_ENTITY_HYPERVISOR"::show_snapshots "$image_vm_name")" || {
    err "Failed to get snapshots names for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly snapshot_names
  echo "$snapshot_names" | grep -Po "^${_type}:.*\|.*\d+\|?\$" || :
}

#
# Get child containers
#
# Arguments:
#   image_id  string       image id
#    _type  string         type of the child (e.g. container|layer)
#
# Output:
#  Writes child_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::__get_child_ids() {
  local -r image_id="$1"
  local -r _type="$2"

  local snapshot_names
  snapshot_names="$(vedv::image_entity::__get_snapshots_names "$image_id" "$_type")" || {
    err "Failed to get snapshots names for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly snapshot_names

  local -r ids="$(echo "$snapshot_names" | cut -d'|' -f2 | cut -d':' -f2 | tr '\n' ' ' | sed 's/\s*$//')"

  echo "$ids"
}

#
# Get child containers
#
# Arguments:
#   image_id  string       image id
#
# Output:
#  Writes child containers_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_child_containers_ids() {
  local -r image_id="$1"
  vedv::image_entity::__get_child_ids "$image_id" 'container'
}

#
# Has containers
#
# Arguments:
#   image_id  string       image id
#
# Output:
#  Writes true (bool) if has containers, or false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::has_containers() {
  local -r image_id="$1"

  local child_containers_ids
  child_containers_ids="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
    err "Failed to get child containers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly child_containers_ids

  if [[ -z "$child_containers_ids" ]]; then
    echo false
    return 0
  fi

  echo true
}

#
# Get layers
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes layers_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_layers_ids() {
  local -r image_id="$1"
  vedv::image_entity::__get_child_ids "$image_id" 'layer'
}

#
# Get snapshot name by layer id
#
# Arguments:
#   image_id string       image id
#   layer_id string       layer id
#
# Output:
#  Writes snapshot name (string) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_snapshot_name_by_layer_id() {
  local -r image_id="$1"
  local -r layer_id="$2"

  local snapshot_names
  snapshot_names="$(vedv::image_entity::__get_snapshots_names "$image_id" 'layer')" || {
    err "Failed to get snapshots names for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly snapshot_names
  local -r name_pattern="$UTILS_REGEX_NAME"
  echo "$snapshot_names" | grep -Po "^layer:${name_pattern}\|id:${layer_id}\|\$" || :
}

#
# Get last layer id
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes last layer id (string) value to the stdout
#
# Returns:
#   0 on success, non-zero on error.
vedv::image_entity::get_last_layer_id() {
  local -r image_id="$1"

  local -a last_layer_id
  # shellcheck disable=SC2207
  last_layer_id=($(vedv::image_entity::get_layers_ids "$image_id")) || return $?

  if [[ "${#last_layer_id[@]}" -eq 0 ]]; then
    return 0
  fi

  echo "${last_layer_id[-1]}"
}
