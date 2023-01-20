#
# API to manage virtualbox virtual machines
#

# REQUIRE
# . '../../utils.bash'

# FUNCTIONS

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

  VBoxManage import "$ova_file" --vsys 0 --vmname "$vm_name"
}

#
# List virtual machines with name that contains the partial name
#
# Arguments:
#   vm_partial_name         name of the exported VM
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

  VBoxManage snapshot "$vm_name" take "$snapshot_name"
}

# IMPL: Start one or more stopped containers
vedv::virtualbox::container::start() {
  echo 'vedv::virtualbox::container::start'
}

#  IMPL: Stop one or more running containers
vedv::virtualbox::container::stop() {
  echo 'vedv::virtualbox::container::stop'
}

# IMPL: Remove one or more containers
vedv::virtualbox::container::rm() {
  echo 'vedv::virtualbox::container::rm'
}

# IMPL: Create and run a container from an image
vedv::virtualbox::container::run() {
  echo 'vedv::virtualbox::container::run'
}
