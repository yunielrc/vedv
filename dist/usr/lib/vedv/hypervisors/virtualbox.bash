#
# API to manage virtualbox virtual machines
#

# REQUIRE
if false; then
  . '../../utils.bash'
fi

# CONSTANTS
readonly VEDV_HYPERVISOR_FRONTEND_HEADLESS='headless'
readonly VEDV_HYPERVISOR_FRONTEND_GUI='gui'

# VARIABLES
__VEDV_HYPERVISOR_FRONTEND="$VEDV_HYPERVISOR_FRONTEND_HEADLESS"

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   [frontend]  string    hypervisor frontend
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::constructor() {
  readonly __VEDV_HYPERVISOR_FRONTEND="${1:-"$VEDV_HYPERVISOR_FRONTEND_HEADLESS"}"
  # validate arguments
  if [[ "$__VEDV_HYPERVISOR_FRONTEND" != "$VEDV_HYPERVISOR_FRONTEND_HEADLESS" &&
    "$__VEDV_HYPERVISOR_FRONTEND" != "$VEDV_HYPERVISOR_FRONTEND_GUI" ]]; then
    err "Invalid hypervisor frontend: '${__VEDV_HYPERVISOR_FRONTEND}'"
    return "$ERR_INVAL_ARG"
  fi
}
vedv::hypervisor::constructor() { vedv::virtualbox::constructor "$@"; }

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
vedv::hypervisor::validate_vm_name() { vedv::virtualbox::validate_vm_name "$@"; }

#
# Create a full clone of an existing virtual machine
#
# Arguments:
#   vm_name             name of the VM
#   vm_clone_name       name of the cloned VM
#   vm_snapshot         name of the snapshot that will be used to clone
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::clonevm() {
  local -r vm_name="$1"
  local -r vm_clone_name="$2"
  local -r vm_snapshot="${3:-}"

  vedv::virtualbox::validate_vm_name "$vm_name" 'vm_name' ||
    return $?
  if ! vedv::virtualbox::validate_vm_name "$vm_clone_name" 'clone_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi

  vedv::virtualbox::__remove_vm_existing_directory "$vm_clone_name" || {
    err "Failed to remove existing directory for vm '${vm_clone_name}' that is going to be created"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  if [[ -n "$vm_snapshot" ]]; then
    VBoxManage clonevm "$vm_name" --name "$vm_clone_name" --register \
      --snapshot "$vm_snapshot" || {
      err "Failed to clone VM '${vm_name}' to '${vm_clone_name}' from snapshot '${vm_snapshot}'"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
  else
    VBoxManage clonevm "$vm_name" --name "$vm_clone_name" --register || {
      err "Failed to clone VM '${vm_name}' to '${vm_clone_name}'"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
  fi

  return 0
}
vedv::hypervisor::clonevm() { vedv::virtualbox::clonevm "$@"; }

#
# Create a linked clone of an existing virtual machine
#
# Arguments:
#   vm_name             string    name of the VM
#   vm_clone_name       string    name of the cloned VM
#   vm_snapshot         string    name of the snapshot that will be used to clone
#   [create_snapshot]   bool      create a snapshot before cloning (default: true)
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::clonevm_link() {
  local -r vm_name="$1"
  local -r vm_clone_name="$2"
  local -r vm_snapshot="${3:-"$vm_clone_name"}"
  local -r create_snapshot="${4:-true}"

  vedv::virtualbox::validate_vm_name "$vm_name" 'vm_name' ||
    return $?
  vedv::virtualbox::validate_vm_name "$vm_clone_name" 'clone_vm_name' ||
    return $?

  vedv::virtualbox::__remove_vm_existing_directory "$vm_clone_name" || {
    err "Failed to remove existing directory for vm '${vm_clone_name}' that is going to be created"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  if [[ "$create_snapshot" == true ]]; then
    vedv::virtualbox::take_snapshot "$vm_name" "$vm_clone_name" || {
      err "Failed to create snapshot '${vm_clone_name}'"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
  fi

  VBoxManage clonevm "$vm_name" --name "$vm_clone_name" --register \
    --options 'link' --snapshot "$vm_snapshot" || {

    if [[ "$create_snapshot" == true ]]; then
      vedv::virtualbox::delete_snapshot "$vm_name" "$vm_clone_name" || {
        err "Failed to delete snapshot '${vm_clone_name}'"
      }
    fi
    err "Failed to clone VM '${vm_name}' to '${vm_clone_name}'"

    return "$ERR_VIRTUALBOX_OPERATION"
  }
}
vedv::hypervisor::clonevm_link() { vedv::virtualbox::clonevm_link "$@"; }

#
# Get virtualbox vms directory
#
# Output:
#   writes vbox vms directory (string) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
# shellcheck disable=SC2120
vedv::virtualbox::__get_vms_directory() {

  local -r vbox_vms_dir="$(VBoxManage list systemproperties 2>/dev/null | grep -Po 'Default machine folder:\s+\K/.*$')"

  if [[ -z "$vbox_vms_dir" ]]; then
    err "'vbox_vms_dir' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  if [[ ! -d "$vbox_vms_dir" ]]; then
    err "VirtualBox VMs directory '${vbox_vms_dir}' doesn't exist"
    return "$ERR_NOFILE"
  fi

  echo "$vbox_vms_dir"
}

#
# Get a vm directory name from vm name
#
# Arguments:
#   vm_name   string    name of the VM
#
# Output:
#   writes vm directory name (string) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::__vm_name_to_vm_dirname() {
  local -r vm_name="$1"

  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  # transfor this: "image-cache|crc:1980169285|" to this: "image_alpine_crc_764158514_"
  # and this: "image:alpine|crc:764158514|" to this: "image-cache_crc_1980169285_"
  local vm_directory_name="${vm_name//:/_}"
  vm_directory_name="${vm_directory_name//|/_}"
  readonly vm_directory_name

  echo "$vm_directory_name"
}

#
# Remove vm existing directory
#
# Before vm creation if doesn't exist a vm with the name of the vm that is going
# to be created and there is a directory for the vm, delete the directory.
#
# Arguments:
#   vm_name   string    name of the VM
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::__remove_vm_existing_directory() {
  local -r vm_name="$1"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  #

  # if exists vm show an error
  local vm_exists
  vm_exists="$(vedv::virtualbox::exists_vm_with_partial_name "$vm_name")" || {
    err "Failed to check if vm exists ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vm_exists

  if [[ "$vm_exists" == true ]]; then
    err "VM '${vm_name}' already exists"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  local vbox_vms_directory
  vbox_vms_directory="$(vedv::virtualbox::__get_vms_directory)" || {
    err "Failed to get vbox vms directory"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vbox_vms_directory

  if [[ -z "$vbox_vms_directory" ]]; then
    err "'vbox_vms_directory' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  if [[ ! -d "$vbox_vms_directory" ]]; then
    err "Virtualbox VMs '${vbox_vms_directory}' doesn't exist"
    return "$ERR_NOFILE"
  fi

  local vm_directory_name
  vm_directory_name="$(vedv::virtualbox::__vm_name_to_vm_dirname "$vm_name")" || {
    err "Failed to calc vm directory for vm '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vm_directory_name

  if [[ -z "$vm_directory_name" ]]; then
    err "'vm_directory_name' is empty"
    return "$ERR_INVAL_VALUE"
  fi

  local -r vm_directory="${vbox_vms_directory}/${vm_directory_name}"

  if [[ ! -d "$vm_directory" ]]; then
    return 0
  fi

  __rm -rf "$vm_directory" || {
    err "Failed to remove directory of VM '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  echo "removed: ${vm_directory}"
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

  vedv::virtualbox::__remove_vm_existing_directory "$vm_name" || {
    err "Failed to remove existing directory for vm '${vm_name}' that is going to be created"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  VBoxManage import "$ova_file" --vsys 0 --vmname "$vm_name"
  VBoxManage modifyvm "$vm_name" --usb-ohci=on --usb-ehci=off
}
vedv::hypervisor::import() { vedv::virtualbox::import "$@"; }

#
# Export a virtual appliance
#
# Arguments:
#   vm_name             string  name of the VM to export
#   ova_file            string  file to export to
#   [exported_vm_name]  string  exported vm name (default: vm_name)
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::export() {
  local -r vm_name="$1"
  local -r ova_file="$2"
  local -r exported_vm_name="${3:-"$vm_name"}"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$ova_file" ]]; then
    err "Argument 'ova_file' is required"
    return "$ERR_INVAL_ARG"
  fi

  local is_running
  is_running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if vm is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly is_running

  if [[ "$is_running" == true ]]; then
    VBoxManage controlvm "$vm_name" acpipowerbutton
    sleep 2
  fi

  VBoxManage modifyvm "$vm_name" --usb-ohci=on --usb-ehci=off

  VBoxManage export "$vm_name" \
    --output "$ova_file" --vsys 0 --ovf20 --vmname "$exported_vm_name" &>/dev/null
}
vedv::hypervisor::export() { vedv::virtualbox::export "$@"; }

#
# List virtual machines with name that contains the partial name
#
# Arguments:
#   vm_partial_name string     BRE pattern
#
# Output:
#   writes vm_names (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::list_vms_by_partial_name() {
  local -r vm_partial_name="$1"
  # validate arguments
  if [[ -z "$vm_partial_name" ]]; then
    err "Argument 'vm_partial_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  # while read -r __vm_name _; do
  #   if [[ "$__vm_name" =~ $vm_partial_name ]]; then
  #     eval echo "$__vm_name"
  #   fi
  # done < <(VBoxManage list vms)

  # Using hyperfine to run the benchmarks the code below is by average faster that the commented builtin version,
  # at least in a machine with:
  # i5-12400F, 32GB DDR4 3200MHz RAM, 970 EVO Plus 500GB NVMe SSD PCIe Gen 3.0 x 4
  #
  # The importance of the performance here is that this function is called so
  # many times during the execution of the script.
  VBoxManage list vms |
    grep "$vm_partial_name" |
    cut -d' ' -f1 |
    sed 's/"//g' || :

  return "${PIPESTATUS[0]}"
}
vedv::hypervisor::list_vms_by_partial_name() { vedv::virtualbox::list_vms_by_partial_name "$@"; }
#
# Returns if exists virtual machines with partial name
#
# Arguments:
#   vm_partial_name         BRE pattern
#
# Output:
#   writes true if exists or false otherwise to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::exists_vm_with_partial_name() {
  local -r vm_partial_name="$1"

  local vms
  vms=$(vedv::virtualbox::list_vms_by_partial_name "$vm_partial_name") || {
    err "Failed to get vms list"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vms

  if [[ -z "$vms" ]]; then
    echo false
  else
    echo true
  fi
}
vedv::hypervisor::exists_vm_with_partial_name() {
  vedv::virtualbox::exists_vm_with_partial_name "$@"
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
vedv::hypervisor::snapshot_restore_current() { vedv::virtualbox::snapshot_restore_current "$@"; }
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
vedv::hypervisor::take_snapshot() { vedv::virtualbox::take_snapshot "$@"; }

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
vedv::hypervisor::restore_snapshot() { vedv::virtualbox::restore_snapshot "$@"; }

#
# Show snapshoots for a given vm
#
# Arguments:
#   vm_name string           name of the VM
#
# Output:
#   writes snapshot vm_names (text) to stdout
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
vedv::hypervisor::show_snapshots() { vedv::virtualbox::show_snapshots "$@"; }
#
# Delete a snapshot
#
# Arguments:
#   vm_name         string      name of the VM
#   snapshot_name   string      name of the snapshot
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::delete_snapshot() {
  local -r vm_name="$1"
  local -r snapshot_name="$2"

  VBoxManage snapshot "$vm_name" delete "$snapshot_name"
}
vedv::hypervisor::delete_snapshot() { vedv::virtualbox::delete_snapshot "$@"; }

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
  local -r show_gui="${2:-false}"
  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local front_end="$__VEDV_HYPERVISOR_FRONTEND"

  if [[ "$show_gui" == true ]]; then
    front_end='gui'
  fi
  readonly front_end

  VBoxManage startvm "$vm_name" --type "$front_end" || {
    err "Failed to start VM ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
}
vedv::hypervisor::start() { vedv::virtualbox::start "$@"; }

#
#  Saves the current state of the VM to disk and then stops the VM
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
vedv::virtualbox::save_state_stop() {
  local -r vm_name="$1"

  local running
  running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if vm is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly running

  if [[ "$running" == true ]]; then
    VBoxManage controlvm "$vm_name" savestate
  fi
}
vedv::hypervisor::save_state_stop() { vedv::virtualbox::save_state_stop "$@"; }

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
vedv::hypervisor::shutdown() { vedv::virtualbox::shutdown "$@"; }

#
# Power off a virtual machine
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
vedv::hypervisor::poweroff() { vedv::virtualbox::poweroff "$@"; }

#
# Check if a virtual machine is running
#
# Arguments:
#   vm_name string      virtual machine name
#
# Output:
#   writes true or false to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
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
vedv::hypervisor::is_running() { vedv::virtualbox::is_running "$@"; }

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

  # validate arguments
  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  #

  local is_running
  is_running="$(vedv::virtualbox::is_running "$vm_name")" || {
    err "Failed to check if vm is running"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly is_running

  if [[ "$is_running" == true ]]; then
    VBoxManage controlvm "$vm_name" poweroff || {
      err "Failed to poweroff VM ${vm_name}"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
    sleep 2
  fi

  local vm_info
  vm_info="$(VBoxManage showvminfo "$vm_name" --machinereadable)" || {
    err "Failed to get vm info for '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vm_info

  local -r vm_cfg="$(echo "$vm_info" | grep -o '^CfgFile=.*' | grep -o '".*"' | tr -d '"')"
  local -r vm_dir="${vm_cfg%/*}"

  local all_vms_dir
  all_vms_dir="$(vedv::virtualbox::__get_vms_directory)" || {
    err "Failed to get vbox vms directory"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly all_vms_dir

  if [[ "$vm_dir" != "$all_vms_dir"* ]]; then
    err "VM dir '${vm_dir}' is not inside '${all_vms_dir}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  VBoxManage unregistervm "$vm_name" --delete || {
    err "Failed to unregister vm '${vm_name}'"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  if [[ -d "$vm_dir" ]]; then
    __rm -rf "$vm_dir" || {
      err "Failed to remove vm dir '${vm_dir}'"
      return "$ERR_VIRTUALBOX_OPERATION"
    }
  fi

  vedv::virtualbox::remove_inaccessible_hdds
}
vedv::hypervisor::rm() { vedv::virtualbox::rm "$@"; }

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
      VBoxManage closemedium disk "$hdd_uuid" &>/dev/null || {
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
vedv::hypervisor::remove_inaccessible_hdds() { vedv::virtualbox::remove_inaccessible_hdds "$@"; }

#
# List all virtual machines
#
# Output:
#   writes vms_names (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::list() {
  VBoxManage list vms | cut -d' ' -f1 | sed 's/"//g' || :
}
vedv::hypervisor::list() { vedv::virtualbox::list "$@"; }

#
# List running virtual machines
#
# Output:
#   writes vms_names (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::list_running() {
  VBoxManage list runningvms | cut -d' ' -f1 | sed 's/"//g' || :
}
vedv::hypervisor::list_running() { vedv::virtualbox::list_running "$@"; }

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

  if ! VBoxManage setextradata "$vm_name" user-data "$description" >/dev/null; then
    err "Error setting description, vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi
}
vedv::hypervisor::set_description() { vedv::virtualbox::set_description "$@"; }

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
  vminfo="$(VBoxManage getextradata "$vm_name" user-data)" || {
    err "Error getting description of vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vminfo

  if [[ "$vminfo" == "No value set!" ]]; then
    return 0
  fi

  echo "${vminfo#'Value:' }"
}
vedv::hypervisor::get_description() { vedv::virtualbox::get_description "$@"; }

#
# Get forwarding ports
#
# Arguments:
#   vm_name string  virtual machine name
#
# Output:
#   writes the forwarding ports (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::get_forwarding_ports() {
  local -r vm_name="$1"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local vminfo
  vminfo="$(VBoxManage showvminfo "$vm_name" --machinereadable)" || {
    err "Error getting forwarding ports of vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly vminfo

  echo "$vminfo" | grep -o '^Forwarding([[:digit:]]\+)=".*"' | grep -o '".*"' | tr -d '"'
}
vedv::hypervisor::get_forwarding_ports() { vedv::virtualbox::get_forwarding_ports "$@"; }

#
# Add forwarding port
#
# Arguments:
#   vm_name     string  virtual machine name
#   rule_name   string  rule name
#   host_port   string  host port
#   guest_port  string  guest port
#   protocol    string  protocol
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::add_forwarding_port() {
  local -r vm_name="$1"
  local -r rule_name="$2"
  local -r host_port="$3"
  local -r guest_port="$4"
  local -r protocol="${5:-tcp}"

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
  if [ -z "$protocol" ]; then
    err "Argument 'protocol' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! VBoxManage modifyvm "$vm_name" --natpf1 \
    "${rule_name},${protocol},,${host_port},,${guest_port}" >/dev/null; then
    err "Error adding forwarding port, rule name: ${rule_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  return 0
}
vedv::hypervisor::add_forwarding_port() { vedv::virtualbox::add_forwarding_port "$@"; }

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
vedv::hypervisor::delete_forwarding_port() { vedv::virtualbox::delete_forwarding_port "$@"; }

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
  vedv::virtualbox::add_forwarding_port "$vm_name" "$rule_name" "$host_port" "$guest_port"

  echo "$host_port"
}
vedv::hypervisor::assign_random_host_forwarding_port() { vedv::virtualbox::assign_random_host_forwarding_port "$@"; }

#
# Modify vm hardware.
# If cpus and memory are 0 or empty, it will not be modified.
#
# Arguments:
#   vm_name string  virtual machine name
#   cpus    integer number of cpus
#   memory  integer memory in MB
#
# Output:
#   Writes error message to stderr on error.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::modifyvm() {
  local -r vm_name="$1"
  local -ri cpus="$2"
  local -ri memory="${3:-}"

  if [[ -z "$vm_name" ]]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local options=''

  if [[ $cpus -gt 0 ]]; then
    options="--cpus ${cpus} "
  fi
  if [[ "$memory" -gt 0 ]]; then
    options="${options}--memory ${memory}"
  fi
  readonly options

  if [[ -z "$options" ]]; then
    return 0
  fi

  eval VBoxManage modifyvm "'${vm_name}'" "$options" &>/dev/null || {
    err "Error modifying vm: ${vm_name}"
    return "$ERR_VIRTUALBOX_OPERATION"
  }

  return 0
}
vedv::hypervisor::modifyvm() { vedv::virtualbox::modifyvm "$@"; }

#
# Show vm state
#
# Arguments:
#   vm_name string  virtual machine name
#
# Output:
#   Writes state (poweroff|running|saved|paused) to stdout.
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::virtualbox::get_state() {
  local -r vm_name="$1"

  if [ -z "$vm_name" ]; then
    err "Argument 'vm_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  VBoxManage showvminfo --machinereadable "$vm_name" |
    grep -Pom1 '^VMState="\K\w+(?=")' || :
}
vedv::hypervisor::get_state() { vedv::virtualbox::get_state "$@"; }
