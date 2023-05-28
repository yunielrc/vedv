#
# WMObj service
#
# Its provide a common base for VMObj Services
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../ssh-client.bash'
  . '../__base/vmobj-entity.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#  ssh_ip            string           ssh ip address
#  ssh_user          string           ssh user
#  ssh_password      string           ssh password
#  [use_cache_dict]  <string, bool>   default: false, not use cache
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::constructor() {
  readonly __VEDV_VMOBJ_SERVICE_SSH_IP="$1"
  readonly __VEDV_VMOBJ_SERVICE_SSH_USER="$2"
  readonly __VEDV_VMOBJ_SERVICE_SSH_PASSWORD="$3"
  readonly __VEDV_VMOBJ_SERVICE_USE_CACHE_DICT="${4:-}"
}

#
# Return if use cache for a given vmobj type
#
# Arguments:
#  type string   type (e.g. 'container|image')
#
# Output:
#  writes true if use cache otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
vedv::vmobj_service::use_cache() {
  local -r type="$1"
  # validate argument
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$__VEDV_VMOBJ_SERVICE_USE_CACHE_DICT" ]]; then
    echo false
    return 0
  fi

  eval local -rA use_cache_dict="$__VEDV_VMOBJ_SERVICE_USE_CACHE_DICT"

  if [[ -v use_cache_dict["$type"] ]]; then
    echo "${use_cache_dict["$type"]}"
  else
    echo false
  fi
}

#
# Get ssh user
#
# Output:
#  Writes ssh_user (string) to the stdout
#
vedv::vmobj_service::get_ssh_user() {
  echo "$__VEDV_VMOBJ_SERVICE_SSH_USER"
}

#
# Tell if a vmobj is started
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_id string       vmobj id
#
# Output:
#  Writes true if started otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::is_started() {
  local -r type="$1"
  local -r vmobj_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Argument 'vmobj_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name
  vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Failed to get vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vm_name

  if [[ -z "$vm_name" ]]; then
    err "There is no vm for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  fi

  vedv::hypervisor::is_running "$vm_name" || {
    err "Failed to check if is running vm: '${vm_name}'"
    return "$ERR_HYPERVISOR_OPERATION"
  }
}

#
# Get ids from a list with vmobj names or ids
#
# Arguments:
#   type string   type (e.g. 'container|image')
#   vmobj_ids_or_names string    vmobj ids or names
#
# Output:
#  writes vmobj_ids (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::get_ids_from_vmobj_names_or_ids() {
  local -r type="$1"
  shift
  local -ra vmobj_ids_or_names=("$@")
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "${vmobj_ids_or_names[*]}" ]]; then
    err "At least one ${type} is required"
    return "$ERR_INVAL_ARG"
  fi

  local -a vmobj_ids
  local -A err_messages=()

  for _vmobj_id_or_name in "${vmobj_ids_or_names[@]}"; do
    local vmobj_id
    vmobj_id="$(vedv::vmobj_entity::get_id_by_vmobj_name "$type" "$_vmobj_id_or_name" 2>/dev/null)" || {
      if [[ $? != "$ERR_NOT_FOUND" ]]; then
        err_messages["Error getting vmobj id for ${type}s"]+="'${_vmobj_id_or_name}' "
      fi
      vmobj_ids+=("$_vmobj_id_or_name")
      continue
    }
    vmobj_ids+=("$vmobj_id")
  done

  echo "${vmobj_ids[@]}"

  for err_msg in "${!err_messages[@]}"; do
    err "${err_msg}: ${err_messages["$err_msg"]}"
  done

  if [[ "${#err_messages[@]}" -ne 0 ]]; then
    return "$ERR_VMOBJ_OPERATION"
  fi
}

#
#  Execute a function on many vmobj by name or id
#
# Arguments:
#   type                string   type (e.g. 'container|image')
#   exec_func           string   function name to execute
#   vmobj_names_or_ids  string   vmobj name or id
#
# Output:
#  writes the processed vmobj ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::exec_func_on_many_vmobj() {
  local -r type="$1"
  local -r exec_func="$2"
  shift 2
  local -ra names_or_ids=("$@")
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$exec_func" ]]; then
    err "Invalid argument 'exec_func': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local -a vmobj_ids
  # shellcheck disable=SC2207
  vmobj_ids=($(vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "${names_or_ids[@]}")) || {
    err 'Error getting vmobj ids'
    return "$ERR_VMOBJ_OPERATION"
  }
  local -A err_messages=()

  for vmobj_id in "${vmobj_ids[@]}"; do
    eval "${exec_func} '${vmobj_id}'" || {
      err_messages["Failed to execute function on ${type}s"]+="'${vmobj_id}'"
    }
  done

  for err_msg in "${!err_messages[@]}"; do
    err "${err_msg}: ${err_messages["$err_msg"]}"
  done

  if [[ "${#err_messages[@]}" -ne 0 ]]; then
    return "$ERR_VMOBJ_OPERATION"
  fi
}

#
#  Start a vmobj
#
# Arguments:
#   type         string   type (e.g. 'container|image')
#   wait_for_ssh bool     wait for ssh (true|false)
#   vmobj_id     string   vmobj id
#
# Output:
#  writes started vmobj id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::start_one() {
  local -r type="$1"
  local -r wait_for_ssh="$2"
  local -r vmobj_id="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local exists
  exists="$(vedv::vmobj_service::exists_with_id "$type" "$vmobj_id")" || {
    err "Failed to check if exists ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly exists

  if [[ "$exists" == false ]]; then
    err "There is no ${type} with id '${vmobj_id}'"
    return "$ERR_INVAL_ARG"
  fi

  local is_started
  is_started="$(vedv::vmobj_service::is_started "$type" "$vmobj_id")" || {
    err "Failed to get start status for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly is_started

  if [[ "$is_started" == true ]]; then
    echo "$vmobj_id"
    return 0
  fi

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Failed to get vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "There is no vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  fi

  local _ssh_port
  _ssh_port="$(vedv::hypervisor::assign_random_host_forwarding_port "$vmobj_vm_name" 'ssh' 22)" || {
    err "Failed to assign random host forwarding port to ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly _ssh_port

  if [[ -z "$_ssh_port" ]]; then
    err "Empty ssh port for ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  fi

  vedv::vmobj_entity::set_ssh_port "$type" "$vmobj_id" "$_ssh_port" || {
    err "Failed to set ssh port ${_ssh_port} to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }

  vedv::hypervisor::start "$vmobj_vm_name" &>/dev/null || {
    err "Failed to start ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }

  echo "$vmobj_id"

  if [[ "$wait_for_ssh" == false ]]; then
    return 0
  fi

  vedv::ssh_client::wait_for_ssh_service "$__VEDV_VMOBJ_SERVICE_SSH_IP" "$_ssh_port" || {
    err "Failed to wait for ssh service on port ${_ssh_port}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
#  Start one or more vmobj by name or id
#
# Arguments:
#   type                string    type (e.g. 'container|image')
#   wait_for_ssh        bool      wait for ssh (true|false)
#   vmobj_names_or_ids  string    vmobj name or id
#
# Output:
#  writes started vmobj ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::start() {
  local -r type="$1"
  local -r wait_for_ssh="$2"
  shift 2

  vedv::vmobj_service::exec_func_on_many_vmobj \
    "$type" \
    "vedv::vmobj_service::start_one '${type}' ${wait_for_ssh}" \
    "$@"
}

#
#  Stop a running vmobj
#  Warning: stopping vmobj without saving the state may lead to data loss
#
# Arguments:
#   type        string    type (e.g. 'container|image')
#   save_state  bool      save state before stopping (true|false)
#   vmobj_id    string    vmobj id
#
# Output:
#  writes stopped vmobj id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::stop_one() {
  local -r type="$1"
  local -r save_state="$2"
  local -r vmobj_id="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local hypervisor_cmd='stop'

  if [[ "$save_state" == true ]]; then
    hypervisor_cmd='save_state_stop'
  fi
  readonly hypervisor_cmd

  local exists
  exists="$(vedv::vmobj_service::exists_with_id "$type" "$vmobj_id")" || {
    err "Failed to check if exists ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly exists

  if [[ "$exists" == false ]]; then
    err "There is no ${type} with id '${vmobj_id}'"
    return "$ERR_INVAL_ARG"
  fi

  local is_started
  is_started="$(vedv::vmobj_service::is_started "$type" "$vmobj_id")" || {
    err "Failed to get start status for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly is_started

  if [[ "$is_started" == false ]]; then
    echo "$vmobj_id"
    return 0
  fi

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Failed to get vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "There is no vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  fi

  vedv::hypervisor::"$hypervisor_cmd" "$vmobj_vm_name" &>/dev/null || {
    err "Failed to stop ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }

  echo "$vmobj_id"
}

#
#  Stop one or more running vmobj by name or id
#  Warning: stopping vmobj without saving state may lead to data loss
#
# Arguments:
#   type                string    type (e.g. 'container|image')
#   save_state          bool      save state before stop
#   vmobj_names_or_ids  string    vmobj name or id
#
# Output:
#  writes stopped vmobj ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::stop() {
  local -r type="$1"
  local -r save_state="$2"
  shift 2

  vedv::vmobj_service::exec_func_on_many_vmobj \
    "$type" \
    "vedv::vmobj_service::stop_one '${type}' ${save_state}" \
    "$@"
}

#
#  Stop one wmobj
#
# Arguments:
#   type string          type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#
# Output:
#  writes stopped vmobj id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::secure_stop_one() {
  local -r type="$1"
  local -r vmobj_id="$2"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local exists
  exists="$(vedv::vmobj_service::exists_with_id "$type" "$vmobj_id")" || {
    err "Failed to check if exists ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly exists

  if [[ "$exists" == false ]]; then
    err "There is no ${type} with id '${vmobj_id}'"
    return "$ERR_INVAL_ARG"
  fi

  local is_started
  is_started="$(vedv::vmobj_service::is_started "$type" "$vmobj_id")" || {
    err "Failed to get start status for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly is_started

  if [[ "$is_started" == false ]]; then
    echo "$vmobj_id"
    return 0
  fi

  local vmobj_vm_name
  vmobj_vm_name="$(vedv::vmobj_entity::get_vm_name "$type" "$vmobj_id")" || {
    err "Failed to get vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vmobj_vm_name

  if [[ -z "$vmobj_vm_name" ]]; then
    err "There is no vm name for ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  fi

  vedv::hypervisor::shutdown "$vmobj_vm_name" &>/dev/null || {
    err "Failed to stop ${type}: '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }

  local is_running=true
  local -i attemps=10

  while [[ "$is_running" == true && "$attemps" -gt 0 ]]; do
    utils::sleep 1
    ((attemps -= 1))
    is_running="$(vedv::hypervisor::is_running "$vmobj_vm_name")" || {
      err "Failed to check if ${type}: ${vmobj_id} is running"
      return "$ERR_HYPERVISOR_OPERATION"
    }
  done
  readonly is_running

  if [[ "$is_running" == true ]]; then
    err "Failed to stop ${type}: ${vmobj_id}, trying to poweroff it..."

    vedv::hypervisor::poweroff "$vmobj_vm_name" || {
      err "Failed to poweroff ${type}: ${vmobj_id}"
    }
    return "$ERR_HYPERVISOR_OPERATION"
  fi

  echo "$vmobj_id"
}

#
#  Stop securely one or more running vmobj by name or id
#
# Arguments:
#   type                string    type (e.g. 'container|image')
#   vmobj_names_or_ids  string    vmobj name or id
#
# Output:
#  writes stopped vmobj ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::secure_stop() {
  local -r type="$1"
  shift
  vedv::vmobj_service::exec_func_on_many_vmobj \
    "$type" \
    "vedv::vmobj_service::secure_stop_one '${type}'" \
    "$@"
}

#
#  Exists vmobj with id
#
# Arguments:
#  type     string    type (e.g. 'container|image')
#  vmobj_id string    vmobj id
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::exists_with_id() {
  local -r type="$1"
  local vmobj_id="$2"
  # validate argument
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Argument 'vmobj_id' is required"
    return "$ERR_INVAL_ARG"
  fi

  local output
  output="$(vedv::hypervisor::exists_vm_with_partial_name "|crc:${vmobj_id}|")" || {
    err "Hypervisor failed to check if ${type} with id '${vmobj_id}' exists"
    return "$ERR_VMOBJ_OPERATION"
  }

  echo "$output"
}

#
#  Exists vmobj with name
#
# Arguments:
#  type        string   type (e.g. 'container|image')
#  vmobj_name  string   vmobj name
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::exists_with_name() {
  local -r type="$1"
  local -r vmobj_name="$2"
  # validate argument
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_name" ]]; then
    err "Argument 'vmobj_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  local output
  output="$(vedv::hypervisor::exists_vm_with_partial_name "${type}:${vmobj_name}|")" || {
    err "Hypervisor failed to check if ${type} with name '${vmobj_name}' exists"
    return "$ERR_VMOBJ_OPERATION"
  }

  echo "$output"
}

#
#  List vmobj
#
# Arguments:
#   type                     string    type (e.g. 'container|image')
#   [list_all]               default: false, list running vmobj
#   [partial_name]           name of the vmobj
#
# Output:
#  writes 'vmobj_id vmobj_name' to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::list() {
  local -r type="$1"
  local -r list_all="${2:-false}"
  local -r partial_name="${3:-}"
  # validate argument
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  local hypervisor_cmd='list_running'

  if [[ "$list_all" == true ]]; then
    hypervisor_cmd='list'
  fi
  readonly hypervisor_cmd

  local vm_names
  vm_names="$(vedv::hypervisor::"$hypervisor_cmd")" || {
    err "Error getting virtual machines names"
    return "$ERR_VMOBJ_OPERATION"
  }
  vm_names="$(grep "${type}:${partial_name}.*|" <<<"$vm_names" || :)"
  readonly vm_names

  if [[ -z "$vm_names" ]]; then
    return 0
  fi

  local -a vm_names_arr
  readarray -t vm_names_arr <<<"$vm_names"
  readonly vm_names_arr

  for vm_name in "${vm_names_arr[@]}"; do
    local vmobj_id vmobj_name

    vmobj_id="$(vedv::vmobj_entity::get_vmobj_id_by_vm_name "$type" "$vm_name")" || {
      err "Failed to get ${type} id for vm: '${vm_name}'"
      return "$ERR_VMOBJ_OPERATION"
    }
    vmobj_name="$(vedv::vmobj_entity::get_vmobj_name_by_vm_name "$type" "$vm_name")" || {
      err "Failed to get ${type} name for vm: '${vm_name}'"
      return "$ERR_VMOBJ_OPERATION"
    }
    echo "${vmobj_id} ${vmobj_name}"
  done
}

#
# Execute a ssh function
#
# The exec_func should has the variables: $user, $ip, $password, $port
# as plain string, this function will replace them with the values
#
# Arguments:
#   type          string     type (e.g. 'container|image')
#   vmobj_id      string     vmobj id or name
#   exec_func     string     function to execute
#   [user]        string     vmobj user
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::__exec_ssh_func() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r exec_func="$3"
  local user="${4:-}"

  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$exec_func" ]]; then
    err "Invalid argument 'exec_func': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$user" ]]; then
    user="$(vedv::vmobj_service::get_user "$type" "$vmobj_id")" || {
      err "Failed to get default user for ${type}"
      return "$ERR_VMOBJ_OPERATION"
    }
  fi
  readonly user

  if [[ -z "$user" ]]; then
    err "Invalid argument 'user': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  vedv::vmobj_service::start_one "$type" 'true' "$vmobj_id" >/dev/null || {
    err "Failed to start ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
  # shellcheck disable=SC2034
  local -r ip="$__VEDV_VMOBJ_SERVICE_SSH_IP"
  # shellcheck disable=SC2034
  local -r password="$__VEDV_VMOBJ_SERVICE_SSH_PASSWORD"

  local port
  port="$(vedv::vmobj_entity::get_ssh_port "$type" "$vmobj_id")" || {
    err "Failed to get ssh port for ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
  # shellcheck disable=SC2034
  readonly port

  eval "$exec_func" || {
    err "Failed to execute function on ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Execute cmd in a vmobj
#
# Arguments:
#   type        string    type (e.g. 'container|image')
#   vmobj_id    string    vmobj id
#   cmd         string    command to execute
#   [user]      string    user name
#   [workdir]   string    working directory for command,
#                         if <none> is set no workdir will be used,
#                         if empty, the default workdir will be used.
#   [env]       string    environment variable for command
#   [shell]     string    shell to use for command
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::execute_cmd_by_id() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r cmd="$3"
  local -r user="${4:-}"
  local -r workdir="${5:-}"
  local -r env="${6:-}"
  local -r shell="${7:-}"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Invalid argument 'cmd': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local _workdir=''

  if [[ "$workdir" != '<none>' ]]; then
    if [[ -n "$workdir" ]]; then
      _workdir="$workdir"
    else
      _workdir="$(vedv::vmobj_service::get_workdir "$type" "$vmobj_id")" || {
        err "Failed to get default workdir for ${type}"
        return "$ERR_VMOBJ_OPERATION"
      }
    fi
  fi
  readonly _workdir

  local cmd_encoded
  cmd_encoded="$(utils::str_encode "$cmd")" || {
    err "Failed to encode command: ${cmd}"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly cmd_encoded

  local env_encoded
  env_encoded="$(utils::str_encode "$env")" || {
    err "Failed to encode env: ${env}"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly env_encoded

  local -r exec_func="vedv::ssh_client::run_cmd \"\$user\" \"\$ip\" \"\$password\" '${cmd_encoded}' \"\$port\" '${_workdir}' '${env_encoded}' '${shell}'"

  vedv::vmobj_service::__exec_ssh_func \
    "$type" \
    "$vmobj_id" \
    "$exec_func" \
    "$user" || {
    err "Failed to execute command in ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Execute cmd in a vmobj
#
# Arguments:
#   type              string    type (e.g. 'container|image')
#   vmobj_id_or_name  string    vmobj id or name
#   cmd               string    command to execute
#   [user]            string    user name
#   [workdir]         string    working directory for command
#   [env]             string    environment variable for command
#   [shell]           string    shell to use for command
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::execute_cmd() {
  local -r type="$1"
  local -r vmobj_id_or_name="$2"
  local -r cmd="$3"
  local -r user="${4:-}"
  local -r workdir="${5:-}"
  local -r env="${6:-}"
  local -r shell="${7:-}"

  local vmobj_id
  vmobj_id="$(vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_id_or_name")" || {
    err "Failed to get ${type} id by name or id: ${vmobj_id_or_name}"
    return "$ERR_VMOBJ_OPERATION"
  }
  vedv::vmobj_service::execute_cmd_by_id \
    "$type" \
    "$vmobj_id" \
    "$cmd" \
    "$user" \
    "$workdir" \
    "$env" \
    "$shell"
}

#
# Establish a ssh connection to a vmobj
#
# Arguments:
#   type      string     type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#   [user]    string     user name
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::connect_by_id() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r user="${3:-}"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::ssh_client::connect \"\$user\" \"\$ip\"  \"\$password\" \"\$port\""

  vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func" "$user" || {
    err "Failed to connect to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Establish a ssh connection to a vmobj
#
# Arguments:
#   type              string     type (e.g. 'container|image')
#   vmobj_id_or_name  string     vmobj id or name
#   [user]            string     user name
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::connect() {
  local -r type="$1"
  local -r vmobj_id_or_name="$2"
  local -r user="${3:-}"

  local vmobj_id
  vmobj_id="$(vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_id_or_name")" || {
    err "Failed to get ${type} id by name or id: ${vmobj_id_or_name}"
    return "$ERR_VMOBJ_OPERATION"
  }
  vedv::vmobj_service::connect_by_id "$type" "$vmobj_id" "$user"
}

#
# Copy files from local filesystem to a container
#
# Arguments:
#   type          string     type (e.g. 'container|image')
#   vmobj_id      string     vmobj id
#   src           string     local source path
#   dest          string     vmobj destination path
#   [user]        string     user name
#   [workdir]     string     vmobj workdir
#   [chown]       string     chown files to user
#   [chmod]       string     chmod files to mode
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::copy_by_id() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r src="$3"
  local -r dest="$4"
  local -r user="${5:-}"
  local -r workdir="${6:-}"
  local -r chown="${7:-}"
  local -r chmod="${8:-}"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"
  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$src" ]]; then
    err "Invalid argument 'src': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$dest" ]]; then
    err "Invalid argument 'dest': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local _workdir=''

  if [[ "$workdir" != '<none>' ]]; then
    if [[ -n "$workdir" ]]; then
      _workdir="$workdir"
    else
      _workdir="$(vedv::vmobj_service::get_workdir "$type" "$vmobj_id")" || {
        err "Failed to get default workdir for ${type}"
        return "$ERR_VMOBJ_OPERATION"
      }
    fi
  fi
  readonly _workdir

  local vedvfileignore
  vedvfileignore="$(vedv:image_vedvfile_service::get_joined_vedvfileignore)" || {
    err "Failed to get joined vedvfileignore"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vedvfileignore

  local -r exec_func="vedv::ssh_client::copy \"\$user\" \"\$ip\"  \"\$password\" \"\$port\" '${src}' '${dest}' '${vedvfileignore}' '${_workdir}' '${chown}' '${chmod}'"

  vedv::vmobj_service::__exec_ssh_func "$type" "$vmobj_id" "$exec_func" "$user" || {
    err "Failed to copy to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Copy files from local filesystem to a container
#
# Arguments:
#   type              string     type (e.g. 'container|image')
#   vmobj_id_or_name  string     vmobj id or name
#   src               string     local source path
#   dest              string     vmobj destination path
#   [user]            string     user name
#   [workdir]         string     vmobj workdir
#   [chown]           string     chown files to user
#   [chmod]           string     chmod files to mode
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::copy() {
  local -r type="$1"
  local -r vmobj_id_or_name="$2"
  local -r src="$3"
  local -r dest="$4"
  local -r user="${5:-}"
  local -r workdir="${6:-}"
  local -r chown="${7:-}"
  local -r chmod="${8:-}"

  local vmobj_id
  vmobj_id="$(vedv::vmobj_service::get_ids_from_vmobj_names_or_ids "$type" "$vmobj_id_or_name")" || {
    err "Failed to get ${type} id by name or id: ${vmobj_id_or_name}"
    return "$ERR_VMOBJ_OPERATION"
  }
  vedv::vmobj_service::copy_by_id \
    "$type" \
    "$vmobj_id" \
    "$src" \
    "$dest" \
    "$user" \
    "$workdir" \
    "$chown" \
    "$chmod"
}

#
# Create an user if it doesn't exist and set it as default vedv user
#
# Arguments:
#   type       string     type (e.g. 'container|image')
#   vmobj_id   string     vmobj id
#   user_name  string     user name
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::set_user() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r user_name="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$user_name" ]]; then
    err "Invalid argument 'user_name': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local cur_user_name
  cur_user_name="$(vedv::vmobj_service::get_user "$type" "$vmobj_id")" || {
    err "Error getting attribute user name from the ${type} '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly cur_user_name

  if [[ "$cur_user_name" == "$user_name" ]]; then
    return 0
  fi
  # create user if it doesn't exist
  local -r cmd="vedv-adduser '${user_name}' '${__VEDV_VMOBJ_SERVICE_SSH_PASSWORD}' && vedv-setuser '${user_name}'"

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' &>/dev/null || {
    err "Failed to set user '${user_name}' to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }

  local use_cache
  use_cache="$(vedv::vmobj_service::use_cache "$type")"
  readonly use_cache

  if [[ "$use_cache" == true ]]; then
    vedv::vmobj_entity::cache::set_user_name "$type" "$vmobj_id" "$user_name" || {
      err "Failed to make user cache for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }
  fi
}

#
# Get default vedv user
#
# Arguments:
#   type            string    type (e.g. 'container|image')
#   vmobj_id        string    vmobj id
#   [force_nocache] bool      force no cache, default: false
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::get_user() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r force_nocache="${3:-false}"

  local use_cache
  use_cache="$(vedv::vmobj_service::use_cache "$type")"
  readonly use_cache

  if [[ "$force_nocache" == false && "$use_cache" == true ]]; then

    local cached_user=''

    cached_user="$(vedv::vmobj_entity::cache::get_user_name "$type" "$vmobj_id")" || {
      err "Failed to get cached user for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }

    if [[ -n "$cached_user" ]]; then
      echo "$cached_user"
      return 0
    fi

    cached_user="$(vedv::vmobj_service::get_user "$type" "$vmobj_id" 'true')" || {
      err "Failed to get default user for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }
    vedv::vmobj_entity::cache::set_user_name "$type" "$vmobj_id" "$cached_user" || {
      err "Failed to make user cache for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }
    echo "$cached_user"
    return 0
  fi

  local -r cmd='vedv-getuser'

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to get user of ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Creates and set the default workdir for the vmobj_service
#
# Arguments:
#   type      string     type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#   workdir   string     workdir
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::set_workdir() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r workdir="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$workdir" ]]; then
    err "Invalid argument 'workdir': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local cur_workdir
  cur_workdir="$(vedv::vmobj_service::get_workdir "$type" "$vmobj_id")" || {
    err "Error getting attribute workdir name from the ${type} '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly cur_workdir

  if [[ "$cur_workdir" == "$workdir" ]]; then
    return 0
  fi

  local user_name
  user_name="$(vedv::vmobj_service::get_user "$type" "$vmobj_id")" || {
    err "Error getting attribute user name from the ${type} '${vmobj_id}'"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly user_name

  local -r cmd="vedv-setworkdir '${workdir}' '${user_name}'"

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to set workdir '${workdir}' to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }

  local use_cache
  use_cache="$(vedv::vmobj_service::use_cache "$type")"
  readonly use_cache

  if [[ "$use_cache" == true ]]; then
    vedv::vmobj_entity::cache::set_workdir "$type" "$vmobj_id" "$workdir" || {
      err "Failed to make workdir cache for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }
  fi

}

#
# Get workdir
#
# Arguments:
#   type       string     type (e.g. 'container|image')
#   vmobj_id   string     vmobj id
#   [force_nocache] bool      force no cache, default: false
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::get_workdir() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r force_nocache="${3:-false}"

  local use_cache
  use_cache="$(vedv::vmobj_service::use_cache "$type")"
  readonly use_cache

  if [[ "$force_nocache" == false && "$use_cache" == true ]]; then

    local cached_workdir=''

    cached_workdir="$(vedv::vmobj_entity::cache::get_workdir "$type" "$vmobj_id")" || {
      err "Failed to get cached workdir for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }

    if [[ -n "$cached_workdir" ]]; then
      echo "$cached_workdir"
      return 0
    fi

    cached_workdir="$(vedv::vmobj_service::get_workdir "$type" "$vmobj_id" 'true')" || {
      err "Failed to get default workdir for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }

    if [[ -z "$cached_workdir" ]]; then
      cached_workdir='.'
    fi

    vedv::vmobj_entity::cache::set_workdir "$type" "$vmobj_id" "$cached_workdir" || {
      err "Failed to make workdir cache for ${type}: ${vmobj_id}"
      return "$ERR_VMOBJ_OPERATION"
    }
    echo "$cached_workdir"
    return 0
  fi

  local -r cmd='vedv-getworkdir'

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to get workdir of ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Set the default shell for all users on the vmobj
#
# Arguments:
#   type      string     type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#   shell     string     shell
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::set_shell() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r shell="$3"

  local -r cmd="vedv-setshell '${shell}'"

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to set shell '${shell}' to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Get shell
#
# Arguments:
#   type       string     type (e.g. 'container|image')
#   vmobj_id   string     vmobj id
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::get_shell() {
  local -r type="$1"
  local -r vmobj_id="$2"

  local -r cmd='vedv-getshell'

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to get shell of ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Add environment variable to vmobj filesystem
#
# Arguments:
#   type      string     type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#   env_var   string     env_var (e.g. NAME=nalyd)
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::add_environment_var() {
  local -r type="$1"
  local -r vmobj_id="$2"
  local -r env_var="$3"
  # validate arguments
  vedv::vmobj_entity::validate_type "$type" ||
    return "$?"

  if [[ -z "$vmobj_id" ]]; then
    err "Invalid argument 'vmobj_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$env_var" ]]; then
    err "Invalid argument 'env_var': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r cmd="vedv-addenv_var $'${env_var}'"

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to add environment variable '${env_var}' to ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}

#
# Get environment variables from vmobj filesystem
#
# Arguments:
#   type      string     type (e.g. 'container|image')
#   vmobj_id  string     vmobj id
#
# Output:
#  writes environment variables (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::vmobj_service::get_environment_vars() {
  local -r type="$1"
  local -r vmobj_id="$2"

  local -r cmd='vedv-getenv_vars'

  vedv::vmobj_service::execute_cmd_by_id "$type" "$vmobj_id" "$cmd" 'root' '<none>' || {
    err "Failed to get environment variables of ${type}: ${vmobj_id}"
    return "$ERR_VMOBJ_OPERATION"
  }
}
