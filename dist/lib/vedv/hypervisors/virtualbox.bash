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

  if ! vedv::virtualbox::validate_vm_name "$vm_clone_name" 'clone_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi
  vedv::virtualbox::take_snapshot "$vm_name" "$vm_clone_name"

  VBoxManage clonevm "$vm_name" --name "$vm_clone_name" --register \
    --options 'link' --snapshot "$vm_clone_name"
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
vedv::virtualbox::take_snapshot() {
  local -r vm_name="$1"
  local -r snapshot_name="$2"

  if ! vedv::virtualbox::validate_vm_name "$snapshot_name" 'snapshot_vm_name'; then
    return "$ERR_INVAL_ARG"
  fi
  VBoxManage snapshot "$vm_name" take "$snapshot_name"
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

  VBoxManage controlvm "$vm_name" poweroff
}
vedv::virtualbox::stop() { vedv::virtualbox::poweroff "$@"; }

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

  VBoxManage controlvm "$vm_name" poweroff &>/dev/null || :
  sleep 2
  VBoxManage unregistervm "$vm_name" --delete
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

# IMPL: Create and run a container from an image
vedv::virtualbox::container::run() {
  echo 'vedv::virtualbox::container::run'
}
