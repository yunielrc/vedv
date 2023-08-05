#
# Image Entity
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../__base/vmobj-entity.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# CONSTANTS

readonly VEDV_IMAGE_ENTITY_TYPE='image'
# shellcheck disable=SC2034
readonly VEDV_IMAGE_ENTITY_VALID_ATTRIBUTES='image_cache|ova_file_sum|child_containers_ids'
readonly VEDV_IMAGE_ENTITY_REGEX_LAYER_NAME='[A-Z]{2,10}'
readonly VEDV_IMAGE_ENTITY_SNAPSHOT_TYPES='layer'
# scheme: USER@REPO/NAME
readonly VEDV_IMAGE_ENTITY_EREGEX_IMAGE_FQN="(${UTILS_HTTP_URL_EREGEX}/)?[a-zA-Z0-9_]+@${VEDV_VMOBJ_ENTITY_EREGEX_NAME}/${VEDV_VMOBJ_ENTITY_EREGEX_NAME}"

# VARIABLES

# FUNCTIONS

#
# Validate if given value is an image fqn
#
# Arguments:
#   value string   value to validate
#                  scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes true or false (bool) to stdout
#
# Returns:
#   0
#
vedv::image_entity::is_image_fqn() {
  local -r value="$1"

  if [[ "$value" =~ ^${VEDV_IMAGE_ENTITY_EREGEX_IMAGE_FQN}$ ]]; then
    echo true
  else
    echo false
  fi
}

#
# Validate image fqn
#
# Arguments:
#   image_fqn string   image_fqn to validate
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes error message to stderr
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::validate_image_fqn() {
  local -r image_fqn="$1"

  if [[ "$(vedv::image_entity::is_image_fqn "$image_fqn")" == false ]]; then
    err "Invalid argument '${image_fqn}'"
    return "$ERR_INVAL_ARG"
  fi
  return 0
}

#
# Image fqn to file name
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#  Writes filename (string) to stdout
#  eg: domain__user@collection__image-name.ova
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::fqn_to_file_name() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  local -r file_name="${image_fqn//\//__}.ova"
  echo "${file_name//:/__}"
}

#
# Get domain from fqn
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes domain (string) or nothing to stdout
#   eg: domain
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_domain_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  grep -Pom1 "^${UTILS_HTTP_URL_EREGEX}[^/]" <<<"$image_fqn" || :
}

#
# Get url from fqn, or nothing if no domain
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
# Output:
#   Writes url (string) or nothing to stdout
#   eg: domain.com, writes: https://domain.com
#   eg: http://domain.com, writes: http://domain.com
#   eg: https://domain.com, writes: https://domain.com
#   eg: nothing, writes nothing
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_url_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  local image_registry_domain
  image_registry_domain="$(vedv::image_entity::get_domain_from_fqn "$image_fqn")" ||
    return $?
  readonly image_registry_domain

  local registry_url=''

  if [[ -n "$image_registry_domain" ]]; then
    if [[ "$image_registry_domain" =~ ^https?:// ]]; then
      registry_url="$image_registry_domain"
    else
      registry_url="https://${image_registry_domain}"
    fi
  fi

  echo "$registry_url"
}

#
# Get user from fqn
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes user to stdout
#   eg: user
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_user_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  grep -Pom1 "[^/][a-zA-Z0-9_]+(?=@)" <<<"$image_fqn"
}

#
# Get collection from fqn
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes collection (string) to stdout
#   eg: collection
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_collection_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  grep -Pom1 "@\K${VEDV_VMOBJ_ENTITY_EREGEX_NAME}[^/]" <<<"$image_fqn"
}

#
# Get name from fqn
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes name (string) to stdout
#   eg: image-name
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_name_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  echo "${image_fqn##*/}"
}

#
# Get relative file path from fqn
#
# Arguments:
#   image_fqn string   image fqn
#                      scheme: [domain/]user@collection/image-name
#
# Output:
#   Writes rel_file_path (string) to stdout
#   eg: user@collection/image-name.ova
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::get_rel_file_path_from_fqn() {
  local -r image_fqn="$1"

  vedv::image_entity::validate_image_fqn "$image_fqn" ||
    return "$?"

  echo "$(grep -Pom1 "[^/][a-zA-Z0-9_]+@\S+" <<<"$image_fqn").ova"
}

#
# Validate if given id is valid
#
# Arguments:
#   id string   id to validate
#
# Output:
#   Writes error message to stderr
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::validate_id() {
  vedv::vmobj_entity::validate_id "$@"
}

#
# Validate if image name is valid
#
# Arguments:
#   image_name string   name to validate
#
# Output:
#   Writes error message to stderr
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::validate_name() {
  vedv::vmobj_entity::validate_name "$@"
}

#
# Validate if given id is valid
#
# Arguments:
#   layer_name string   layer_name to validate
#
# Output:
#   Writes error message to stderr
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::image_entity::validate_layer_name() {
  local -r layer_name="$1"

  if [[ ! "$layer_name" =~ ^${VEDV_IMAGE_ENTITY_REGEX_LAYER_NAME}$ ]]; then
    err "Invalid layer name '${layer_name}'"
    return "$ERR_INVAL_ARG"
  fi
  return 0
}

#
# Generate image vm name
#
# Arguments:
#   [image_name]  string  image name
#
# Output:
#  Writes generated vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::gen_vm_name() {
  vedv::vmobj_entity::gen_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
}

#
# Set the vm name of a image
#
# Arguments:
#   image_id  string     image id
#   vm_name   string     vm name
#
# Output:
#  writes image vm name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::set_vm_name() {
  vedv::vmobj_entity::set_vm_name "$VEDV_IMAGE_ENTITY_TYPE" "$@"
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

  local -r valid_types="$VEDV_IMAGE_ENTITY_SNAPSHOT_TYPES"

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
vedv::image_entity::__get_snapshots_ids() {
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
# Get child containers ids
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

  vedv::vmobj_entity::__get_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'child_containers_ids'
}

#
# Clear child containers ids
# (only for internal use of image_service when an image is imported)
#
# Arguments:
#   image_id            string  image id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::____clear_child_container_ids() {
  local -r image_id="$1"
  # validate arguments
  vedv::vmobj_entity::validate_id "$image_id" ||
    return "$?"

  vedv::vmobj_entity::__set_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'child_containers_ids' \
    ''
}

#
# Add child container id
# (only for internal use of container_service when creating a container)
#
# Arguments:
#   image_id            string  image id
#   child_container_id  string  child container id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::____add_child_container_id() {
  local -r image_id="$1"
  local -r child_container_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_id "$image_id" ||
    return "$?"
  vedv::vmobj_entity::validate_id "$child_container_id" ||
    return "$?"

  local child_containers_ids_str=''
  child_containers_ids_str="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
    err "Failed to get child containers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly child_containers_ids_str

  local -a child_containers_ids_arr=()
  IFS=' ' read -r -a child_containers_ids_arr <<<"$child_containers_ids_str"

  for el in "${child_containers_ids_arr[@]}"; do
    if [[ "$el" == "$child_container_id" ]]; then
      err "Failed to add child container '${child_container_id}' to image '${image_id}', it is already added"
      return "$ERR_IMAGE_OPERATION"
    fi
  done

  child_containers_ids_arr+=("$child_container_id")

  vedv::vmobj_entity::__set_attribute \
    "$VEDV_IMAGE_ENTITY_TYPE" \
    "$image_id" \
    'child_containers_ids' \
    "${child_containers_ids_arr[*]}"
}

#
# Remove child container id
# (only for internal use of container_service when container is deleted)
#
# Arguments:
#   image_id            string  image id
#   child_container_id  string  child container id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::____remove_child_container_id() {
  local -r image_id="$1"
  local -r child_container_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_id "$image_id" ||
    return "$?"
  vedv::vmobj_entity::validate_id "$child_container_id" ||
    return "$?"

  local child_containers_ids_str=''
  child_containers_ids_str="$(vedv::image_entity::get_child_containers_ids "$image_id")" || {
    err "Failed to get child containers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly child_containers_ids_str

  local -a child_containers_ids_arr=()
  IFS=' ' read -r -a child_containers_ids_arr <<<"$child_containers_ids_str"

  for i in "${!child_containers_ids_arr[@]}"; do
    if [[ "${child_containers_ids_arr[$i]}" == "$child_container_id" ]]; then
      unset "child_containers_ids_arr[$i]"

      vedv::vmobj_entity::__set_attribute \
        "$VEDV_IMAGE_ENTITY_TYPE" \
        "$image_id" \
        'child_containers_ids' \
        "${child_containers_ids_arr[*]}"

      return 0
    fi
  done

  err "Failed to remove child container '${child_container_id}' from image '${image_id}', it was not found"
  return "$ERR_IMAGE_OPERATION"
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
# Get layer at index
#
# Arguments:
#   image_id string       image id
#   index    int          layer index
#
# Output:
#  Writes layers_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_layer_at() {
  local -r image_id="$1"
  local -ri index="$2"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return "$?"
  if [[ $index -lt 0 ]]; then
    err "Index must be greater or equal to 0"
    return "$ERR_INVAL_VALUE"
  fi

  local layers_ids
  layers_ids="$(vedv::image_entity::get_layers_ids "$image_id")" || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layers_ids

  if [[ -z "$layers_ids" ]]; then
    err "Failed to get layer id for image '${image_id}', it has no layers"
    return "$ERR_INVAL_VALUE"
  fi

  local -a layers_ids_arr=()
  IFS=' ' read -r -a layers_ids_arr <<<"$layers_ids"
  readonly layers_ids_arr

  if [[ $index -ge ${#layers_ids_arr[@]} ]]; then
    err "Failed to get layer id for image '${image_id}', index '${index}' is out of range"
    return "$ERR_INVAL_VALUE"
  fi

  echo "${layers_ids_arr[$index]}"
}

#
# Get first layer id
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
vedv::image_entity::get_first_layer_id() {
  local -r image_id="$1"
  vedv::image_entity::get_layer_at "$image_id" 0
}

#
# Search for a layer id by its name and return its index
#
# Arguments:
#   image_id string       image id
#   layer_id string       layer id
#
# Output:
#  Writes -1 if not found, or index (int) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_layer_index() {
  local -r image_id="$1"
  local -r layer_id="$2"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return "$?"
  vedv::image_entity::validate_id "$layer_id" ||
    return "$?"

  local layers_ids
  layers_ids="$(vedv::image_entity::get_layers_ids "$image_id")" || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layers_ids

  if [[ -z "$layers_ids" ]]; then
    echo '-1'
    return 0
  fi

  local -a layers_ids_arr=()
  IFS=' ' read -r -a layers_ids_arr <<<"$layers_ids"
  readonly layers_ids_arr

  for i in "${!layers_ids_arr[@]}"; do
    if [[ "${layers_ids_arr[$i]}" == "$layer_id" ]]; then
      echo "$i"
      return 0
    fi
  done

  echo '-1'
}

#
# Search for a layer id by its id and returns true if found
# or false otherwise
#
# Arguments:
#   image_id string       image id
#   layer_id string       layer id
#
# Output:
#  Writes -1 if not found, or index (int) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::has_layer_id() {
  local image_id="$1"
  local layer_id="$2"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return "$?"
  vedv::image_entity::validate_id "$layer_id" ||
    return "$?"

  local layer_index
  layer_index="$(vedv::image_entity::get_layer_index "$image_id" "$layer_id")" || {
    err "Failed to get layer index for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }
  readonly layer_index

  if [[ $layer_index -eq -1 ]]; then
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
  vedv::image_entity::__get_snapshots_ids "$image_id" 'layer'
}

#
# Get layer count
#
# Arguments:
#   image_id string       image id
#
# Output:
#  Writes layers count (int) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::get_layer_count() {
  local -r image_id="$1"
  # validate arguments
  vedv::image_entity::validate_id "$image_id" ||
    return "$?"

  local -a layer_ids
  # shellcheck disable=SC2207
  layer_ids=($(vedv::image_entity::get_layers_ids "$image_id")) || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_IMAGE_OPERATION"
  }

  echo "${#layer_ids[@]}"
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

  echo "$snapshot_names" | grep -Eo "^layer:${VEDV_IMAGE_ENTITY_REGEX_LAYER_NAME}\|id:${layer_id}\|\$" || :
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

#
# Get cpus value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes cpus (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_cpus() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_cpus "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set cpus value
#
#
# Arguments:
#   image_id  string  image id
#   cpus     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_cpus() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_cpus "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}

#
# Get memory value
#
# Arguments:
#   image_id  string  image id
#
# Output:
#  Writes memory (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::get_memory() {
  local -r image_id="$1"

  vedv::vmobj_entity::cache::get_memory "$VEDV_IMAGE_ENTITY_TYPE" "$image_id"
}

#
# Set memory value
#
#
# Arguments:
#   image_id  string  image id
#   memory     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_entity::cache::set_memory() {
  local -r image_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::cache::set_memory "$VEDV_IMAGE_ENTITY_TYPE" "$image_id" "$value"
}
