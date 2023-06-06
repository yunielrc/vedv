#
# Image Entity
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../__base/vmobj-entity.bash'
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

# CONSTANTS

readonly VEDV_IMAGE_ENTITY_TYPE='image'
# shellcheck disable=SC2034
readonly VEDV_IMAGE_ENTITY_VALID_ATTRIBUTES='image_cache|ova_file_sum|ssh_port|user_name|workdir|environment|exposed_ports|shell'

# FUNCTIONS

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
  vedv::vmobj_entity::gen_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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
  vedv::vmobj_entity::get_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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
  vedv::vmobj_entity::get_vm_name_by_vmobj_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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
  vedv::vmobj_entity::get_vmobj_name_by_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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
vedv::image_entity::get_id_by_vm_name() {
  vedv::vmobj_entity::get_vmobj_id_by_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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
  vedv::vmobj_entity::get_id_by_vmobj_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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

  vedv::vmobj_entity::__get_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'ova_file_sum'
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

  vedv::vmobj_entity::__set_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'ova_file_sum' \
    "$value"
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

  vedv::vmobj_entity::__get_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'image_cache'
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

  vedv::vmobj_entity::__set_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'image_cache' \
    "$value"
}

#
# Get ssh_port value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes ssh_port (int) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_ssh_port() {
  local -r image_id="$1"
  vedv::vmobj_entity::get_ssh_port "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set ssh_port value
#
# Arguments:
#   image_id  string  image id
#   ssh_port  int     ssh port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::set_ssh_port() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::set_ssh_port "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
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
  snapshot_names="$(vedv::hypervisor::show_snapshots "$image_vm_name")" || {
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

  echo "$snapshot_names" | cut -d'|' -f2 | cut -d':' -f2 | tr '\n' ' ' | sed 's/\s*$//'
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
  last_layer_id=($(vedv::image_entity::get_layers_ids "$image_id")) ||
    return $?

  if [[ "${#last_layer_id[@]}" -eq 0 ]]; then
    return 0
  fi

  echo "${last_layer_id[-1]}"
}

#
# Get user_name value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes user_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_user_name() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_user_name "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set user_name value
#
#
# Arguments:
#   image_id  string  image id
#   user_name     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_user_name() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_user_name "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}

#
# Get workdir value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes workdir (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_workdir() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_workdir "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set workdir value
#
#
# Arguments:
#   image_id  string  image id
#   workdir     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_workdir() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_workdir "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}

#
# Get environment value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes environment (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_environment() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_environment "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set environment value
#
#
# Arguments:
#   image_id  string  image id
#   environment     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_environment() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_environment "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}

#
# Get exposed_ports value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes exposed_ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_exposed_ports() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_exposed_ports "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set exposed_ports value
#
#
# Arguments:
#   image_id  string  image id
#   exposed_ports     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_exposed_ports() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_exposed_ports "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}

#
# Get shell value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes shell (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_shell() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_shell "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set shell value
#
#
# Arguments:
#   image_id  string  image id
#   shell     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_shell() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_shell "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}
