#
# VMObj Entity
#
# Its provide a common base for VMObj Entities
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   type                      string   type (e.g. 'container|image')
#   valid_attributes_dict_str string   (eg: $(arr2str valid_attributes_dict))
#
vedv::vmobj_entity::constructor() {
  readonly __VEDV_VMOBJ_ENTITY_TYPE="$1"
  # This doesn't work on tests
  # declare -rn __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT="$2"
  readonly __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR="$2"

  # validate arguments
  if [[ -z "$__VEDV_VMOBJ_ENTITY_TYPE" ]]; then
    err "Argument 'type' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -z "$__VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR" ]]; then
    err "Argument 'valid_attributes' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
}

vedv::vmobj_entity::__get_valid_attributes() {
  local -r type="$1"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  eval local -rA att_dict="$__VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR"
  # shellcheck disable=SC2154
  local -r valid_att="${att_dict["$type"]}"

  if [[ -z "$valid_att" ]]; then
    err "Valid Attributes for type '${type}' not found"
    return "$ERR_INVAL_VALUE"
  fi

  echo "$valid_att"
}

#
# Validate attribute
#
# Arguments:
#   type string   type to validate (e.g. 'container|image')
#
# Returns:
#   0 if valid, non-zero value if invalid
#
vedv::vmobj_entity::validate_type() {
  local -r type="$1"
  # validate arguments
  if [[ -z "$type" ]]; then
    err "Argument 'type' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$type" != @($__VEDV_VMOBJ_ENTITY_TYPE) ]]; then
    err "Invalid type: ${type}, valid types are: ${__VEDV_VMOBJ_ENTITY_TYPE}"
    return "$ERR_INVAL_ARG"
  fi
  return 0
}

#
# Validate attribute
#
# Arguments:
#   type string   type to validate (e.g. 'container|image')
#   attribute string   attribute to validate
#
# Returns:
#   0 if valid, non-zero value if invalid
#
vedv::vmobj_entity::__validate_attribute() {
  local -r type="$1"
  local -r attribute="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$attribute" ]]; then
    err "Argument 'attribute' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local valid_attributes
  valid_attributes="$(vedv::vmobj_entity::__get_valid_attributes "$type")" ||
    return "$?"
  readonly valid_attributes

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
#   type string   type (e.g. 'container|image')
#   vm_name string   name to validate
#
# Returns:
#   0 if valid, 1 if invalid
#
vedv::vmobj_entity::__validate_vm_name() {
  local -r type="$1"
  local -r vm_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r name_pattern="$UTILS_REGEX_NAME"
  local -r pattern="^${type}:${name_pattern}\|crc:${name_pattern}\|\$"

  if [[ ! "$vm_name" =~ $pattern ]]; then
    err "Invalid ${type} vm name: '${vm_name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Generate vm name
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   [vmobj_name string]       vmobj name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::gen_vm_name() {
  local -r type="$1"
  local vmobj_name="${2:-}"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_name" ]]; then
    vmobj_name="$(petname)" || {
      err "Failed to generate a random name"
      return "$ERR_VMOBJ_ENTITY"
    }
  fi

  local -r crc_sum="$(utils::crc_sum <<<"$vmobj_name")"

  echo "${type}:${vmobj_name}|crc:${crc_sum}|"
}

#
# Get the vm name
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_id string     vmobj id
#
# Output:
#  writes vmobj vm name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_vm_name() {
  local -r type="$1"
  local -r vmobj_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_id" ||
    return "$?"

  local vms
  vms="$(vedv::hypervisor::list_vms_by_partial_name "|crc:${vmobj_id}|")" || {
    err "Failed to get vm name of ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_ENTITY"
  }

  head -n 1 <<<"$vms"
}

#
# Get the vm name of a vmobj if exists
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_name string     vmobj name
#
# Output:
#  writes vmobj vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_vm_name_by_vmobj_name() {
  local -r type="$1"
  local -r vmobj_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_name" ||
    return "$?"

  local vm_name
  vm_name="$(vedv::hypervisor::list_vms_by_partial_name "${type}:${vmobj_name}|")" || {
    err "Failed to get vm name of ${type}: ${vmobj_name}"
    return "$ERR_VMOBJ_ENTITY"
  }

  head -n 1 <<<"$vm_name"
}

#
# Get vmobj name from vm name
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_vm_name string       vmobj vm name
#
# Output:
#  Writes vmobj_name string to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_vmobj_name_by_vm_name() {
  local -r type="$1"
  local -r vmobj_vm_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::__validate_vm_name "$type" "$vmobj_vm_name" ||
    return "$?"

  local vmobj_name="${vmobj_vm_name#"${type}:"}"
  vmobj_name="${vmobj_name%'|crc:'*}"
  echo "$vmobj_name"
}

#
# Get vmobj id from vmobj vm name
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_vm_name string       container vm name
#
# Output:
#  Writes vmobj_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_vmobj_id_by_vm_name() {
  local -r type="$1"
  local -r vmobj_vm_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::__validate_vm_name "$type" "$vmobj_vm_name" ||
    return "$?"

  local result="${vmobj_vm_name#*'|crc:'}"
  echo "${result%'|'}"
}

#
# Get vmobj id by vmobj name
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_name string       vmobj name
#
# Output:
#  Writes vmobj_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_id_by_vmobj_name() {
  local -r type="$1"
  local -r vmobj_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_name" ||
    return "$?"

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name_by_vmobj_name "$type" "$vmobj_name")" || {
    err "Failed to get vm name of ${type}: ${vmobj_name}"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "${type^} with name '${vmobj_name}' not found"
    return "$ERR_NOT_FOUND"
  fi

  local vmobj_id
  vmobj_id="$(vedv::vmobj_entity::get_vmobj_id_by_vm_name "$type" "$vmobj_vm_name")" || {
    err "Failed to get id of ${type}: ${vmobj_name}"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly vmobj_id

  echo "$vmobj_id"
}

#
# Get entity as dictionary
#
# Arguments:
#   type string               type (e.g. 'container|image')
#   vmobj_id string           image id
#
# Output:
#  Writes dictionary_str (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_dictionary() {
  local -r type="$1"
  local -r vmobj_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_id" ||
    return "$?"

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Error getting the vm name for the ${type}: '${vmobj_id}'"
    return "$ERR_NOT_FOUND"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "Vm name for the ${type}: '${vmobj_id}' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  local vm_description
  vm_description="$(vedv::hypervisor::get_description "$vmobj_vm_name")" || {
    err "Error getting the description for the vm name: '${vmobj_vm_name}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  vm_description="${vm_description//\\/}"
  readonly vm_description

  if [[ -z "$vm_description" ]]; then
    err "Description for the vm name: '${vmobj_vm_name}' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  # e.g.: vm_description='([parent_image_id]="alpine1" [ssh_port]=22 ...)'
  eval local -A vmobj_dict="$vm_description" || return $?
  # shellcheck disable=SC2199
  if [[ "${#vmobj_dict[@]}" -eq 0 ]]; then
    err "Empty dictionary for the vm name: '${vmobj_vm_name}'"
    return "$ERR_INVAL_VALUE"
  fi

  local vmojb_name
  vmojb_name="$(vedv::vmobj_entity::get_vmobj_name_by_vm_name "$type" "$vmobj_vm_name")" || {
    err "Error getting the vmobj name for the vm name: '${vmobj_vm_name}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly vmojb_name

  vmobj_dict['id']="$vmobj_id"
  vmobj_dict['type']="$type"
  vmobj_dict['name']="$vmojb_name"
  vmobj_dict['vm_name']="$vmobj_vm_name"

  arr2str vmobj_dict
}

#
# Get attribute value
#
# Arguments:
#   type string               type (e.g. 'container|image')
#   vmobj_id string           image id
#   attribute  string         attribute
# Output:
#  Writes attribute (string) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::__get_attribute() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r attribute="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_id" ||
    return "$?"
  vedv::vmobj_entity::__validate_attribute "$type" "$attribute" ||
    return "$?"

  local dictionary_str
  dictionary_str="$(vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id")" || {
    err "Failed to get the dictionary for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly dictionary_str
  # shellcheck disable=SC2178
  local -rA vmobj_dict="$dictionary_str"

  echo "${vmobj_dict["$attribute"]}"
}

#
# Create a new vmobj dictionary
#
# Arguments:
#   type string               type (e.g. 'container|image')
#
# Output:
#  Writes dictionary_str (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::__create_new_vmobj_dict() {
  local -r type="$1"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  # create and initialize the new vmobj_dict
  local -A vmobj_dict=()

  local valid_attributes
  valid_attributes="$(vedv::vmobj_entity::__get_valid_attributes "$type")" || {
    err "Failed to get the valid attributes for ${type}"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly valid_attributes

  local -a valid_attributes_arr
  IFS='|' read -ra valid_attributes_arr <<<"$valid_attributes"

  for valid_attribute in "${valid_attributes_arr[@]}"; do
    vmobj_dict["$valid_attribute"]=""
  done

  arr2str vmobj_dict
}

#
# Set attribute value
#
# Arguments:
#   type string               type (e.g. 'container|image')
#   vmobj_id  string   image id
#   attribute  string      attribute
#   value  string          value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::__set_attribute() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r attribute="$3"
  local -r value="$4"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  utils::validate_name_or_id "$vmobj_id" ||
    return "$?"
  vedv::vmobj_entity::__validate_attribute "$type" "$attribute" ||
    return "$?"

  if [[ -z "$value" ]]; then
    err "Value for the attribute: '${attribute}' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Error getting the vm name for the ${type}: '${vmobj_id}'"
    return "$ERR_NOT_FOUND"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "Vm name for the ${type}: '${vmobj_id}' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  # e.g.: vm_description='([parent_image_id]="alpine1" [ssh_port]=22 ...)'
  local vm_description
  vm_description="$(vedv::hypervisor::get_description "$vmobj_vm_name")" || {
    err "Error getting the description for the vm name: '${vmobj_vm_name}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  vm_description="${vm_description//\\/}" # remove backslashes
  readonly vm_description

  local -A vmobj_dict
  local vmobj_dict_str="$vm_description"

  if [[ -z "$vmobj_dict_str" ]]; then
    # create and initialize the new vmobj_dict
    vmobj_dict_str="$(vedv::vmobj_entity::__create_new_vmobj_dict "$type")" || {
      err "Failed to create a new vmobj dictionary for the ${type}: '${vmobj_id}'"
      return "$ERR_VMOBJ_ENTITY"
    }
  fi
  readonly vmobj_dict_str
  # I don't like eval but here it validate the dictionary syntax
  # and throws an error if it is invalid
  eval vmobj_dict="$vmobj_dict_str" || return $?

  if [[ "${#vmobj_dict[@]}" -eq 0 ]]; then
    err "Empty dictionary for the vm name: '${vmobj_vm_name}'"
    return "$ERR_INVAL_VALUE"
  fi

  vmobj_dict["$attribute"]="$value"

  local updated_description
  updated_description="$(arr2str vmobj_dict)" || return $?

  vedv::hypervisor::set_description "$vmobj_vm_name" "$updated_description" || {
    err "Failed to set description of vm: ${vmobj_vm_name}"
    return "$ERR_VMOBJ_ENTITY"
  }
}

#
# Set ssh_port value
#
# Arguments:
#   type string            type (e.g. 'container|image')
#   vmobj_id  string       vmobj id
#   ssh_port  int          ssh port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::set_ssh_port() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'ssh_port' \
    "$value"
}

#
# Get ssh_port value
#
# Arguments:
#   type string               type (e.g. 'container|image')
#   vmobj_id  string       vmobj id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_ssh_port() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'ssh_port'
}
