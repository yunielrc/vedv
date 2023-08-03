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

# CONSTANTS
readonly VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES='vm_name|ssh_port|user_name|workdir|environment|exposed_ports|shell|cpus|memory|password'

readonly VEDV_VMOBJ_ENTITY_EREGEX_NAME='[[:lower:]](-|_|[[:lower:]]|[[:digit:]]){1,28}([[:lower:]]|[[:digit:]])'
readonly VEDV_VMOBJ_ENTITY_EREGEX_ID='[[:digit:]]{6,11}'
readonly VEDV_VMOBJ_ENTITY_BREGEX_NAME='[[:lower:]]\(-\|_\|[[:lower:]]\|[[:digit:]]\)\{1,28\}\([[:lower:]]\|[[:digit:]]\)'
readonly VEDV_VMOBJ_ENTITY_BREGEX_ID='[[:digit:]]\{6,11\}'
# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   memory_cache_dir          string   memory cache dir
#   type                      string   type (e.g. 'container|image')
#   valid_attributes_dict_str string   (eg: $(arr2str valid_attributes_dict))
#   default_user              string   default user
#   default_password          string   default password
#
vedv::vmobj_entity::constructor() {
  __VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR="$1"
  readonly __VEDV_VMOBJ_ENTITY_TYPE="$2"
  # This doesn't work on tests
  # declare -rn __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT="$2"
  readonly __VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR="$3"
  readonly __VEDV_DEFAULT_USER="$4"
  readonly __VEDV_DEFAULT_PASSWORD="$5"

  # validate arguments
  if [[ -z "$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR" ]]; then
    err "Argument 'memory_cache_dir' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -d "$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR" ]]; then
    err "Argument 'memory_cache_dir' must be a directory"
    return "$ERR_INVAL_ARG"
  fi

  readonly __VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR="${__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR%/}/vmobj_entity"

  if [[ ! -d "$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR" ]]; then
    mkdir "$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR" || {
      err "Failed to create memory cache dir"
      return "$ERR_FAILED_CREATE_DIR"
    }
  fi

  if [[ -z "$__VEDV_VMOBJ_ENTITY_TYPE" ]]; then
    err "Argument 'type' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$__VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES_DICT_STR" ]]; then
    err "Argument 'valid_attributes' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$__VEDV_DEFAULT_USER" ]]; then
    err "Argument 'default_user' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$__VEDV_DEFAULT_PASSWORD" ]]; then
    err "Argument 'default_password' must not be empty"
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

  echo "${VEDV_VMOBJ_ENTITY_VALID_ATTRIBUTES}|${valid_att}"
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
# Get a vm_name regex by id
#
# Arguments:
#   type string   type to validate (e.g. 'container|image')
#   id   string   vmobj id of the vm
#
# Output:
#   Writes regex (string) to stdout
#
# Returns:
#   0 on success, non-zero value on failure
#
vedv::vmobj_entity::vm_name_bregex_by_id() {
  local -r type="$1"
  local -r id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_id "$id" ||
    return "$?"

  echo "${type}:${VEDV_VMOBJ_ENTITY_BREGEX_NAME}|crc:${id}|"
}
vname_bregex_by_id() { vedv::vmobj_entity::vm_name_bregex_by_id "$@"; }

#
# Get a vm_name regex by name
#
# Arguments:
#   type string   type to validate (e.g. 'container|image')
#   name string   vmobj name of the vm
#
# Output:
#   Writes regex (string) to stdout
#
# Returns:
#   0 on success, non-zero value on failure
#
vedv::vmobj_entity::vm_name_bregex_by_name() {
  local -r type="$1"
  local -r name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_name "$name" ||
    return "$?"

  echo "${type}:${name}|crc:${VEDV_VMOBJ_ENTITY_BREGEX_ID}|"
}
vname_bregex_by_name() { vedv::vmobj_entity::vm_name_bregex_by_name "$@"; }

#
# Validate if given value is an id
#
# Arguments:
#   value string   value to validate
#
# Output:
#   Writes true or false (bool) to stdout
#
# Returns:
#   0
#
vedv::vmobj_entity::is_id() {
  local -r value="$1"

  if [[ "$value" =~ ^${VEDV_VMOBJ_ENTITY_EREGEX_ID}$ ]]; then
    echo true
  else
    echo false
  fi
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
vedv::vmobj_entity::validate_id() {
  local -r id="$1"

  if [[ "$(vedv::vmobj_entity::is_id "$id")" == false ]]; then
    err "Invalid argument '${id}'"
    return "$ERR_INVAL_ARG"
  fi
  return 0
}

#
# Validate if given value is a name
#
# Arguments:
#   value string   value to validate
#
# Output:
#   Writes true or false (bool) to stdout
#
# Returns:
#   0
#
vedv::vmobj_entity::is_name() {
  local -r value="$1"

  if [[ "$value" =~ ^${VEDV_VMOBJ_ENTITY_EREGEX_NAME}$ ]]; then
    echo true
  else
    echo false
  fi
}

#
# Validate if given name is valid
#
# Arguments:
#   name string   name to validate
#
# Output:
#   Writes error message to stderr
#
# Returns:
#   0 if valid, non-zero id if invalid
#
vedv::vmobj_entity::validate_name() {
  local -r name="$1"

  if [[ "$(vedv::vmobj_entity::is_name "$name")" == false ]]; then
    err "Invalid argument '${name}'"
    return "$ERR_INVAL_ARG"
  fi
  return 0
}

#
# Get a vmobj name or id and return the id
# If received a name, it calculates the id
# and returns it.
# If received an id, it returns it as is.
#
# Arguments:
#   vmobj_name_or_id  string  vmobj name or id
#
# Output:
#   writes the id to stdout
#
# Returns:
#  0 on success, non-zero value on failure
#
vedv::vmobj_entity::get_id() {
  local -r vmobj_name_or_id="$1"
  # validate arguments

  if [[ "$(vedv::vmobj_entity::is_id "$vmobj_name_or_id")" == true ]]; then
    echo "$vmobj_name_or_id"
    return 0
  fi

  if [[ "$(vedv::vmobj_entity::is_name "$vmobj_name_or_id")" == true ]]; then
    # shellcheck disable=SC2119
    crc_sum <<<"$vmobj_name_or_id"
    return 0
  fi

  err "Invalid name or id: '${vmobj_name_or_id}'"

  return "$ERR_INVAL_ARG"
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
vedv::vmobj_entity::validate_vm_name() {
  local -r type="$1"
  local -r vm_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r pattern="^${type}:${VEDV_VMOBJ_ENTITY_EREGEX_NAME}\|crc:${VEDV_VMOBJ_ENTITY_EREGEX_ID}\|\$"

  if [[ ! "$vm_name" =~ $pattern ]]; then
    err "Invalid ${type} vm name: '${vm_name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Generate vm name
# the id is unique for the name
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
# Set vm_name
#
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   vm_name    string  vm_name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::set_vm_name() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'vm_name' \
    "$value"
}

#
# Get vm name
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes vm_name (string) to the stdout.
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
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"

  local vm_name=''
  vm_name="$(vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" 'vm_name')" || {
    err "Error getting attribute vm_name for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }

  if [[ -z "$vm_name" ]]; then
    vm_name="$(vedv::hypervisor::list_vms_by_partial_name "$(vname_bregex_by_id "$type" "$vmobj_id")")" || {
      err "Error getting the vm name for the ${type}: '${vmobj_id}'"
      return "$ERR_VMOBJ_ENTITY"
    }

    if [[ -z "$vm_name" ]]; then
      err "${type^} with id '${vmobj_id}' not found"
      return "$ERR_NOT_FOUND"
    fi

    vedv::vmobj_entity::__set_attribute \
      "$type" \
      "$vmobj_id" \
      'vm_name' \
      "$vm_name" || {
      err "Error setting attribute vm_name for the ${type}: '${vmobj_id}'"
      return "$ERR_VMOBJ_ENTITY"
    }
  fi

  echo "$vm_name"
}

#
# Get the vm name of a vmobj if exists
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_name string     vmobj name
#
# Output:
#  writes vmobj vm_name (string) or nothing to the stdout
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
  vedv::vmobj_entity::validate_name "$vmobj_name" ||
    return "$?"

  local vm_name
  vm_name="$(vedv::hypervisor::list_vms_by_partial_name "$(vname_bregex_by_name "$type" "$vmobj_name")")" || {
    err "Failed to get vm name of ${type}: ${vmobj_name}"
    return "$ERR_VMOBJ_ENTITY"
  }

  echo "$vm_name"
}

#
# Calculate the vm name of a vmobj
# this function don't check if the vmobj exists
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
vedv::vmobj_entity::calc_vm_name_by_vmobj_name() {
  local -r type="$1"
  local -r vmobj_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_name "$vmobj_name" ||
    return "$?"

  vedv::vmobj_entity::gen_vm_name "$type" "$vmobj_name"
}

#
# Get vmobj name from vm name
# this function don't check if the vmobj exists
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
  vedv::vmobj_entity::validate_vm_name "$type" "$vmobj_vm_name" ||
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
  vedv::vmobj_entity::validate_vm_name "$type" "$vmobj_vm_name" ||
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
  vedv::vmobj_entity::validate_name "$vmobj_name" ||
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
# Calculate vmobj id by vmobj name
# this function don't check if the vmobj exists
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
vedv::vmobj_entity::calc_id_by_vmobj_name() {
  local -r type="$1"
  local -r vmobj_name="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_name "$vmobj_name" ||
    return "$?"
  # shellcheck disable=SC2119
  crc_sum <<<"$vmobj_name"
}

#
# Get entity as dictionary
#
# Arguments:
#   type     string   type (e.g. 'container|image')
#   vmobj_id string   image id
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
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"

  local cached_dictionary_str
  cached_dictionary_str="$(vedv::vmobj_entity::__memcache_get_data "$type" "$vmobj_id")" || {
    err "Failed to get the cached dictionary for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly cached_dictionary_str

  local dictionary_str=''

  if [[ -n "$cached_dictionary_str" ]]; then
    dictionary_str="$cached_dictionary_str"
  else
    local vmobj_vm_name
    vmobj_vm_name="$(vedv::hypervisor::list_vms_by_partial_name "$(vname_bregex_by_id "$type" "$vmobj_id")")" || {
      err "Error getting the vm name for the ${type}: '${vmobj_id}'"
      return "$ERR_VMOBJ_ENTITY"
    }
    readonly vmobj_vm_name

    if [[ -z "$vmobj_vm_name" ]]; then
      err "${type^} with id '${vmobj_id}' not found"
      return "$ERR_NOT_FOUND"
    fi

    dictionary_str="$(vedv::hypervisor::get_description "$vmobj_vm_name")" || {
      err "Error getting the description for the vm name: '${vmobj_vm_name}'"
      return "$ERR_VMOBJ_ENTITY"
    }

    if [[ -z "$dictionary_str" ]]; then
      vedv::vmobj_entity::__create_new_vmobj_dict "$type" || {
        err "Failed to create new dictionary for the ${type}: '${vmobj_id}'"
        return "$ERR_VMOBJ_ENTITY"
      }
      return 0
    fi
    # create memory cache for the vmobj data
    vedv::vmobj_entity::__memcache_set_data "$type" "$vmobj_id" "$dictionary_str" || {
      err "Failed to set the cached dictionary for the ${type}: '${vmobj_id}'"
      return "$ERR_VMOBJ_ENTITY"
    }
  fi
  readonly dictionary_str
  # e.g.: dictionary_str='([parent_image_id]="alpine1" [ssh_port]=22 ...)'
  eval local -A vmobj_dict="$dictionary_str" || return $?
  # shellcheck disable=SC2199
  if [[ "${#vmobj_dict[@]}" -eq 0 ]]; then
    err "Empty dictionary for vmobj: '${vmobj_id}'"
    return "$ERR_INVAL_VALUE"
  fi

  vmobj_dict['id']="$vmobj_id"
  vmobj_dict['type']="$type"

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
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"
  vedv::vmobj_entity::__validate_attribute "$type" "$attribute" ||
    return "$?"

  local dictionary_str
  dictionary_str="$(vedv::vmobj_entity::get_dictionary "$type" "$vmobj_id")" || {
    if [[ "$?" -eq "$ERR_NOT_FOUND" ]]; then
      err "${type^} with id '${vmobj_id}' not found"
      return "$ERR_NOT_FOUND"
    fi
    err "Failed to get the dictionary for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly dictionary_str
  # shellcheck disable=SC2178
  local -rA vmobj_dict="$dictionary_str"

  if [[ -v vmobj_dict["$attribute"] ]]; then
    echo "${vmobj_dict["$attribute"]}"
  fi
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
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  image id
#   attribute string  attribute
#   value     string  value
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
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"
  vedv::vmobj_entity::__validate_attribute "$type" "$attribute" ||
    return "$?"

  local -A vmobj_dict=()
  vmobj_dict["$attribute"]="$value"

  vedv::vmobj_entity::set_dictionary "$type" "$vmobj_id" "$(arr2str vmobj_dict)"
}

#
# Save dictionary
# invalid properties will be ignored
#
# Arguments:
#   type            string  type (e.g. 'container|image')
#   vmobj_id        string  image id
#   dictionary_str  string  dictionary_str
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::set_dictionary() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r dictionary_str="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"

  if [[ -z "$dictionary_str" ]]; then
    err "Argument 'dictionary_str' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  local -A dict
  eval dict="$dictionary_str" || return $?
  readonly dict

  if [[ "${#dict[@]}" -eq 0 ]]; then
    err "Dictionary for argument 'dictionary_str' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::hypervisor::list_vms_by_partial_name "$(vname_bregex_by_id "$type" "$vmobj_id")")" || {
    err "Error getting the vm name for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "${type^} with id '${vmobj_id}' not found"
    return "$ERR_NOT_FOUND"
  fi
  # e.g.: saved_dict_str='([parent_image_id]="alpine1" [ssh_port]=22 ...)'
  local saved_dict_str=''
  saved_dict_str="$(vedv::hypervisor::get_description "$vmobj_vm_name")" || {
    err "Failed to get saved dictionary for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly saved_dict_str

  local -A saved_dict=()

  if [[ -n "$saved_dict_str" ]]; then
    eval saved_dict="$saved_dict_str" || return $?
  fi
  readonly saved_dict

  local new_dict_str=''
  new_dict_str="$(vedv::vmobj_entity::__create_new_vmobj_dict "$type")" || {
    err "Failed to create a new vmobj dictionary for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  readonly new_dict_str

  local -A new_dict
  eval new_dict="$new_dict_str" || return $?

  for key in "${!new_dict[@]}"; do
    if [[ -v dict["$key"] ]]; then
      new_dict["$key"]="${dict[$key]}"
      continue
    fi
    if [[ -v saved_dict["$key"] ]]; then
      new_dict["$key"]="${saved_dict[$key]}"
    fi
  done

  local data
  data="$(arr2str new_dict)" || return $?
  readonly data
  # update data on memory
  vedv::vmobj_entity::__memcache_set_data "$type" "$vmobj_id" "$data" || {
    err "Failed to update memory cache for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
  # update data on disk
  vedv::hypervisor::set_description "$vmobj_vm_name" "$data" || {
    err "Failed to set description of vm: ${vmobj_vm_name}"
    return "$ERR_VMOBJ_ENTITY"
  }
}

#
# Get memory cache data for a given vmobj
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  image id
#
# Output:
#  Writes data (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::__memcache_get_data() {
  local -r type="$1"
  local -r vmobj_id="$2"

  local -r memcache_dir="$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR"

  if [[ ! -d "$memcache_dir" ]]; then
    err "Memory cache directory does not exist: '${memcache_dir}'"
    return "$ERR_VMOBJ_ENTITY"
  fi

  local -r memcache_data_file="${memcache_dir}/${type}-${vmobj_id}"

  if [[ ! -f "$memcache_data_file" ]]; then
    return 0
  fi

  cat "$memcache_data_file"
}

#
# Update memory cache data for a given vmobj
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  image id
#   data      string  updated data
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::__memcache_set_data() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r data="$3"

  if [[ -z "$data" ]]; then
    err "Argument 'data' can not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  local -r memcache_dir="$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR"

  if [[ ! -d "$memcache_dir" ]]; then
    err "Memory cache directory does not exist: '${memcache_dir}'"
    return "$ERR_VMOBJ_ENTITY"
  fi

  local -r memcache_data_file="${memcache_dir}/${type}-${vmobj_id}"
  # update the memory cache
  echo "$data" >"$memcache_data_file" || {
    err "Failed to update the memory cache for the ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_ENTITY"
  }
}

#
# Delete memory cache for a given vmobj
# When a vmobj is removed, its memory cache should be deleted.
# When a vmobj is created, any memory cache with the same object
# id should be removed.
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  image id
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::memcache_delete_data() {
  local -r type="$1"
  local -r vmobj_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  vedv::vmobj_entity::validate_id "$vmobj_id" ||
    return "$?"

  local -r memcache_dir="$__VEDV_VMOBJ_ENTITY_MEMORY_CACHE_DIR"

  if [[ ! -d "$memcache_dir" ]]; then
    err "Memory cache directory does not exist: '${memcache_dir}'"
    return "$ERR_VMOBJ_ENTITY"
  fi

  local -r memcache_data_file="${memcache_dir}/${type}-${vmobj_id}"

  if [[ -f "$memcache_data_file" ]]; then
    rm -f "$memcache_data_file" || {
      err "Failed to remove the memory cache file: '${memcache_data_file}'"
      return "$ERR_VMOBJ_ENTITY"
    }
  fi
}

#
# Set ssh_port value
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#   ssh_port  int     ssh port
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
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes ssh_port (int) to the stdout.
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

#
# Set password
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#   password  int     ssh port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::set_password() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'password' \
    "$value"
}

#
# Get password
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes password (int) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::get_password() {
  local -r type="$1"
  local -r vmobj_id="$2"

  local password=''
  password="$(vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" 'password')" ||
    return $?
  readonly password

  if [[ -n "$password" ]]; then
    echo "$password"
    return 0
  fi

  echo "$__VEDV_DEFAULT_PASSWORD"
}

#
# Set user name
#
# This function can be only used by the
# vedv::vmobj_service and this is the
# responsible of creating the user and
# update the working directory and other
# user related properties when the user
# name is changed.
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   user_name  string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_user_name() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'user_name' \
    "$value"
}

#
# Get user name
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes user_name (string) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_user_name() {
  local -r type="$1"
  local -r vmobj_id="$2"

  local user_name=''
  user_name="$(vedv::vmobj_entity::__get_attribute "$type" "$vmobj_id" 'user_name')" || {
    err "Failed to get user name of the vmobj: ${vmobj_id}"
    return "$ERR_VMOBJ_ENTITY"
  }

  if [[ -z "$user_name" ]]; then
    echo "$__VEDV_DEFAULT_USER"
    return 0
  fi

  echo "$user_name"
}

#
# Set workdir
#
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   workdir    string  workdir
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_workdir() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'workdir' \
    "$value"
}

#
# Get workdir
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes workdir (string) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_workdir() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'workdir'
}

#
# Set environment
#
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   environment    string  environment
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_environment() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'environment' \
    "$value"
}

#
# Get environment
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes environment (text) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_environment() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'environment'
}

#
# Set exposed_ports
#
#
# Arguments:
#   type          string  type (e.g. 'container|image')
#   vmobj_id      string  vmobj id
#   exposed_ports text    exposed_ports
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_exposed_ports() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'exposed_ports' \
    "$value"
}

#
# Get exposed_ports
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes exposed_ports (text) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_exposed_ports() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'exposed_ports'
}

#
# Set shell
#
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   shell    string  shell
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_shell() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'shell' \
    "$value"
}

#
# Get shell
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes shell (string) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_shell() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'shell'
}

#
# Set cpus
#
#
# Arguments:
#   type       string  type (e.g. 'container|image')
#   vmobj_id   string  vmobj id
#   cpus       string  cpus
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_cpus() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -ri value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'cpus' \
    "$value"
}

#
# Get cpus
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes cpus (string) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_cpus() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'cpus'
}

#
# Set memory capacity in MB
#
#
# Arguments:
#   type       string   type (e.g. 'container|image')
#   vmobj_id   string   vmobj id
#   memory     integer  memory
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::set_memory() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -ri value="$3"

  vedv::vmobj_entity::__set_attribute \
    "$type" \
    "$vmobj_id" \
    'memory' \
    "$value"
}

#
# Get memory capacity in MB
#
# Arguments:
#   type      string  type (e.g. 'container|image')
#   vmobj_id  string  vmobj id
#
# Output:
#   Writes memory (integer) to the stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_entity::cache::get_memory() {
  local -r type="$1"
  local -r vmobj_id="$2"

  vedv::vmobj_entity::__get_attribute \
    "$type" \
    "$vmobj_id" \
    'memory'
}
