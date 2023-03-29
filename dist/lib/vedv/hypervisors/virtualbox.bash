#
# API to manage virtualbox virtual machines
#

# REQUIRE
# . '../../utils.bash'

# FUNCTIONS

#
# Validate vm name
#
# Arguments:
#   vm_name             name of the exported VM
#   [type]              eg: vm, clone, snapshot
#
# Writes:
#   if name isn't valid print an info message
#
# Returns:
#   0 if name is valid or non-zero otherwise.
#
vedv::virtualbox::validate_vm_name() {
  local -r vm_name="$1"
  local -r type="${2:-vm}"

  local -ri min_length=5
  local -ri max_length=60

  if [[ "${#vm_name}" -lt $min_length ]]; then
    echo "The ${type} name cannot be shorter than ${min_length} characters" >&2
    return "$ERR_INVAL_ARG"
  fi

  if [[ "${#vm_name}" -gt $max_length ]]; then
    echo "The ${type} name cannot be longer than ${max_length} characters" >&2
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

# IMAGE

# IMPL: Pull an image or a repository from a registry or a file
vedv::virtualbox::image::pull() {

  echo 'vedv::virtualbox::image::pull'
}
# IMPL: Build an image
vedv::virtualbox::image::build() {
  echo 'vedv::virtualbox::image::build'
}

#
# Create a clone of an existing virtual machine
#
# Arguments:
#   vm_name             name of the exported VM
#   vm_clone_name       name of the exported VM
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::clonevm_link() {
  local -r vm_name="$1"
  local -r vm_clone_name="$2"
  local -r vm_snapshot="${3:-"$vm_clone_name"}"

  if ! vedv::virtualbox::validate_vm_name "$vm_clone_name" 'clone_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi
  vedv::virtualbox::take_snapshot "$vm_name" "$vm_clone_name"

  VBoxManage clonevm "$vm_name" --name "$vm_clone_name" --register \
    --options 'link' --snapshot "$vm_snapshot" || {
    vedv::virtualbox::delete_snapshot "$vm_name" "$vm_clone_name"
    err "Failed to clone VM '${vm_name}' to '${vm_clone_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
}

#
# Import a virtual appliance in OVA format
# and create virtual machines
#
# Arguments:
#   ova_file        ova file path
#   vm_name         name of the exported VM
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::import() {
  local -r ova_file="$1"
  local -r vm_name="$2"

  if [[ ! -f "$ova_file" ]]; then
    err "OVA file doesn't exist"
    return "$ERR_NOFILE"
  fi

  if ! vedv::virtualbox::validate_vm_name "$vm_name" 'import_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi
  VBoxManage import "$ova_file" --vsys 0 --vmname "$vm_name"
}

#
# List virtual machines with name that contains the partial name
#
# Arguments:
#   vm_partial_name         name of the exported VM
#
# Output:
#   writes vms names to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
# FIXME: fix typo wms with vms
vedv::virtualbox::list_wms_by_partial_name() {
  local -r vm_partial_name="$1"

  VBoxManage list vms | grep "$vm_partial_name" | cut -d' ' -f1 | sed 's/"//g' || :
}

#
# Takes a snapshot of the current state of the VM
#
# Arguments:
#   vm_name           name of the VM
#   snapshot_name     name of the snapshot
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::snapshot_restore_current() {
  local -r vm_name="$1"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  vedv::virtualbox::poweroff "$vm_name" || {
    err "Failed to poweroff VM ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  VBoxManage snapshot "$vm_name" restorecurrent || {
    err "Failed to restore current snapshot of VM ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
}

#
# Takes a snapshot of the current state of the VM
#
# Arguments:
#   vm_name           name of the VM
#   snapshot_name     name of the snapshot
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::take_snapshot() {
  local -r vm_name="$1"
  local -r snapshot_name="$2"

  if ! vedv::virtualbox::validate_vm_name "$snapshot_name" 'snapshot_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi

  local is_running
  is_running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if VM ${vm_name} is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly is_running

  if [[ "$is_running" == true ]]; then
    VBoxManage snapshot "$vm_name" take "$snapshot_name" --live
  else
    VBoxManage snapshot "$vm_name" take "$snapshot_name"
  fi
}

#
# Restore a snapshot
#
# Arguments:
#   vm_name           name of the VM
#   snapshot_name     name of the snapshot
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::restore_snapshot() {
  local -r vm_name="$1"
  local -r snapshot_name="$2"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$snapshot_name" ]]; then
    err "Argument 'snapshot_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  if ! vedv::virtualbox::validate_vm_name "$snapshot_name" 'snapshot_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi
  vedv::virtualbox::poweroff "$vm_name"
  VBoxManage snapshot "$vm_name" restore "$snapshot_name"
}

#
# Show snapshoots for a given vm
#
# Arguments:
#   vm_name           name of the VM
#
# Output:
#   writes snapshot vms names to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::show_snapshots() {
  local -r vm_name="$1"

  local output
  output="$(VBoxManage showvminfo "$vm_name" --machinereadable)"

  echo "$output" | grep -o '^SnapshotName.*' | grep -o '".*"' | tr -d '"' || :
}

#
# Delete a snapshot
#
# Arguments:
#   vm_name           name of the VM
#   snapshot_name     name of the snapshot
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::delete_snapshot() {
  local -r vm_name="$1"
  local -r snapshot_name="$2"

  VBoxManage snapshot "$vm_name" delete "$snapshot_name"
}

#
# Start a virtual machine
#
# Arguments:
#   vm_name        virtual machine name
#
# Output:
#   writes vm name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::start() {
  local -r vm_name="$1"

  VBoxManage startvm "$vm_name"
}

#
# Shutdown the virtual machine
#
# Arguments:
#   vm_name        virtual machine name
#
# Output:
#   writes vm name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::shutdown() {
  local -r vm_name="$1"

  local running
  running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if vm is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly running

  if [[ "$running" == true ]]; then
    VBoxManage controlvm "$vm_name" acpipowerbutton
    # VBoxManage controlvm "$vm_name" savestate
  fi
}

#
# Stop a virtual machine
#
# Arguments:
#   vm_name        virtual machine name
#
# Output:
#   writes vm name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::poweroff() {
  local -r vm_name="$1"

  local running
  running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if vm is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly running

  if [[ "$running" == true ]]; then
    VBoxManage controlvm "$vm_name" poweroff
  fi
}
vedv::virtualbox::stop() { vedv::virtualbox::poweroff "$@"; }

vedv::virtualbox::is_running() {
  local -r vm_name="$1"

  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  local running_vms
  running_vms="$(vedv::virtualbox::list_running)" || {
    err "Failed to get running vms"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly running_vms
  # VBoxManage showvminfo "image:close-cat|crc:3791933837|" --machinereadable | grep -o 'VMState=".*"' | grep -o '".*"' | tr -d '"'
  if grep --quiet "$vm_name" <<<"$running_vms"; then
    echo true
  else
    echo false
  fi
}

#
# Remove a virtual machine
#
# Arguments:
#   vm_name        virtual machine name
#
# Output:
#   writes vm name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::rm() {
  local -r vm_name="$1"

  vedv::virtualbox::poweroff "$vm_name"
  sleep 2

  local vm_info
  vm_info="$(VBoxManage showvminfo "$vm_name" --machinereadable)" || {
    err "Failed to get vm info for '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vm_info

  local -r vm_cfg="$(echo "$vm_info" | grep -o '^CfgFile=.*' | grep -o '".*"' | tr -d '"')"
  local -r vm_dir="${vm_cfg%/*}"

  local vbox_sysprops
  vbox_sysprops="$(VBoxManage list systemproperties)" || {
    err "Failed to get system properties for '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vbox_sysprops

  local -r all_vms_dir="$(echo "$vbox_sysprops" | grep -i 'Default machine folder:' | grep -o '/.*$')"

  if [[ "$vm_dir" != "$all_vms_dir"* ]]; then
    err "Vm dir '${vm_dir}' is not inside '${all_vms_dir}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  VBoxManage unregistervm "$vm_name" --delete || {
    err "Failed to unregister vm '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  if [[ -d "$vm_dir" ]]; then
    rm -rf "$vm_dir" || {
      err "Failed to remove vm dir '${vm_dir}'"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
  fi

  vedv::virtualbox::remove_inaccessible_hdds
}

#
# Remove all inaccessible virtual machines HDDs
#
# Returns:
#   0 on success, non-zero on error.
vedv::virtualbox::remove_inaccessible_hdds() {
  local -ri calls="${1:-0}"

  if [[ "$calls" -gt 10 ]]; then
    err "Failed to remove inaccessible hdds after 10 attempts"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  local hdds
  hdds="$(VBoxManage list hdds)" || {
    err "Failed to get hdds list"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly hdds

  local -r inaccessible_hdds="$(echo "$hdds" | pcregrep -M 'UUID:.*\nParent UUID:.*\nState:\s+inaccessible' | grep '^UUID:' | cut -d':' -f2 | sed 's/^\s\+//')"

  if [[ -n "$inaccessible_hdds" ]]; then
    local there_is_error=false

    while IFS= read -r hdd_uuid; do
      VBoxManage closemedium disk "$hdd_uuid" --delete &>/dev/null || {
        there_is_error=true
        err "Failed to remove inaccessible hdd '${hdd_uuid}'"
        continue
      }
      echo "$hdd_uuid"
    done <<<"$inaccessible_hdds"

    if [[ "$there_is_error" == true ]]; then
      vedv::virtualbox::remove_inaccessible_hdds "$((calls + 1))"
    fi
  fi
}

#
# List all virtual machines
#
# Output:
#   writes vms names to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::list() {
  VBoxManage list vms | cut -d' ' -f1 | sed 's/"//g' || :
}

#
# List running virtual machines
#
# Output:
#   writes vms names to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::list_running() {
  VBoxManage list runningvms | cut -d' ' -f1 | sed 's/"//g' || :
}

#
# Set description
#
# Arguments:
#   vm_name        virtual machine name
#   description    description
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::set_description() {
  local -r vm_name="$1"
  local -r description="$2"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [ -z "$description" ]; then
    err "Argument 'description' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! VBoxManage modifyvm "$vm_name" --description "$description" >/dev/null; then
    err "Error setting description, vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi
}

#
# Get description
#
# Arguments:
#   vm_name        virtual machine name
#
# Output:
#   writes the description text to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::get_description() {
  local -r vm_name="$1"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local vminfo
  vminfo="$(VBoxManage showvminfo "$vm_name" --machinereadable)" || {
    err "Error getting description of vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vminfo
  local vminfo_vars_fixed
  vminfo_vars_fixed="$(fix_var_names "$vminfo")"
  local -r output="$(echo "$vminfo_vars_fixed" | pcregrep -M 'description="[^"]*"')"
  # the subshell avoid loading global variables
  (
    eval "$output"
    echo "${description:-}"
  )
}

#
# Add forwarding port
#
# Arguments:
#   vm_name        virtual machine name
#   rule_name      rule name
#   host_port      host port
#   guest_port     guest port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::add_forwarding_port() {
  local -r vm_name="$1"
  local -r rule_name="$2"
  local -r host_port="$3"
  local -r guest_port="$4"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [ -z "$rule_name" ]; then
    err "Argument 'rule_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [ -z "$host_port" ]; then
    err "Argument 'host_port' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [ -z "$guest_port" ]; then
    err "Argument 'guest_port' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! VBoxManage modifyvm "$vm_name" --natpf1 \
    "${rule_name},tcp,,${host_port},,${guest_port}" >/dev/null; then
    err "Error adding forwarding port, rule name: ${rule_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  return 0
}

#
# Delete forwarding port
#
# Arguments:
#   vm_name        virtual machine name
#   rule_name      rule name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::delete_forwarding_port() {
  local -r vm_name="$1"
  local -r rule_name="$2"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [ -z "$rule_name" ]; then
    err "Argument 'rule_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! VBoxManage modifyvm "$vm_name" --natpf1 \
    delete "$rule_name" >/dev/null; then
    err "Error deleting forwarding port, rule name: ${rule_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  return 0
}

#
# Assign random host forwarding port to a vm
#
# Arguments:
#   vm_name        virtual machine name
#   rule_name      rule name
#   guest_port     guest_port
#
# Output:
#   writes assigned host port to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::assign_random_host_forwarding_port() {
  local -r vm_name="$1"
  local -r rule_name="$2"
  local -r guest_port="$3"

  local -ri host_port="$(get_a_dynamic_port)"
  vedv::virtualbox::delete_forwarding_port "$vm_name" "$rule_name" &>/dev/null || :
  # add_forwarding_port do all validations
  vedv::virtualbox::add_forwarding_port "$vm_name" "$rule_name" $host_port "$guest_port"

  echo "$host_port"
}

# IMPL: Create and run a container from an image
vedv::virtualbox::container::run() {
  echo 'vedv::virtualbox::container::run'
}
