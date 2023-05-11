#
# Container Entity
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../__base/vmobj-entity.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# +----------------------------+
# |    container               |
# +----------------------------+
# | - id: string               |
# | - name: string             |
# +----------------------------+

# VARIABLES

readonly VEDV_CONTAINER_ENTITY_TYPE='container'
# shellcheck disable=SC2034
readonly VEDV_CONTAINER_ENTITY_VALID_ATTRIBUTES='parent_image_id|ssh_port|user_name'

# FUNCTIONS

#
# Generate container vm name
#
# Arguments:
#   [container_name string]       container name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::gen_vm_name() {
  vedv::vmobj_entity::gen_vm_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Get the vm name of a container
#
# Arguments:
#   container_id string     container id
#
# Output:
#  writes container vm name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_vm_name() {
  vedv::vmobj_entity::get_vm_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Get the vm name of a container if exists
#
# Arguments:
#   container_name string     container name
#
# Output:
#  writes container vm_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_vm_name_by_container_name() {
  vedv::vmobj_entity::get_vm_name_by_vmobj_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Get container name from vm name
#
# Arguments:
#   container_vm_name string       container vm name
#
# Output:
#  Writes container_name string to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_container_name_by_vm_name() {
  vedv::vmobj_entity::get_vmobj_name_by_vm_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Get container id from container vm name
#
# Arguments:
#   container_vm_name string       container vm name
#
# Output:
#  Writes container_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_id_by_vm_name() {
  vedv::vmobj_entity::get_vmobj_id_by_vm_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Get container id by container name
#
# Arguments:
#   container_name string       container name
#
# Output:
#  Writes container_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_id_by_container_name() {
  vedv::vmobj_entity::get_id_by_vmobj_name "$VEDV_CONTAINER_ENTITY_TYPE" "$@"
}

#
# Set ssh_port value
#
# Arguments:
#   container_id  string       container id
#   ssh_port      int          ssh port
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::set_ssh_port() {
  local -r container_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::set_ssh_port "$VEDV_CONTAINER_ENTITY_TYPE" "$container_id" "$value"
}

#
# Get ssh_port value
#
# Arguments:
#   container_id string       container id
#
# Output:
#  Writes ssh_port (int) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_ssh_port() {
  local -r container_id="$1"

  vedv::vmobj_entity::get_ssh_port "$VEDV_CONTAINER_ENTITY_TYPE" "$container_id"
}

#
# Set parent image id value
#
# Arguments:
#   container_id  string       container id
#   image      int             image
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::set_parent_image_id() {
  local -r container_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::__set_attribute \
    "$VEDV_CONTAINER_ENTITY_TYPE" \
    "$container_id" \
    'parent_image_id' \
    "$value"
}

#
# Get parent image id value
#
# Arguments:
#   container_id string       container_id id
#
# Output:
#  Writes image (int) value
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_parent_image_id() {
  local -r container_id="$1"

  vedv::vmobj_entity::__get_attribute \
    "$VEDV_CONTAINER_ENTITY_TYPE" \
    "$container_id" \
    'parent_image_id'
}

#
# Get user_name value
#
# Arguments:
#   container_id  string  container id
#
# Output:
#  Writes user_name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::get_user_name() {
  local -r container_id="$1"

  vedv::vmobj_entity::get_user_name "$VEDV_CONTAINER_ENTITY_TYPE" "$container_id"
}

#
# Set user_name value
#
# Arguments:
#   container_id  string  container id
#   user_name     string  user name
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_entity::set_user_name() {
  local -r container_id="$1"
  local -r value="$2"

  vedv::vmobj_entity::set_user_name "$VEDV_CONTAINER_ENTITY_TYPE" "$container_id" "$value"
}
