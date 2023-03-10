#
# Manage images
#
#

# REQUIRE
# . '../../utils.bash'

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   hypervisor       name of the script
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::constructor() {
  readonly __VEDV_IMAGE_SERVICE_HYPERVISOR="$1"
}

#
# Get image name from image vm name
#
# Arguments:
#   image_vm_name       image vm name
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::_get_image_name() {
  local -r image_vm_name="$1"

  local image_name="${image_vm_name#'image:'}"
  image_name="${image_name%'|crc:'*}"
  echo "$image_name"
}

# Get image id from image vm name
#
# Arguments:
#   image_vm_name       image vm name
#
# Output:
#  Writes image id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::_get_image_id() {
  local -r image_vm_name="$1"

  local result="${image_vm_name#*'|crc:'}"
  echo "${result%'|'}"
}

#
# Generate a vm name from OVA image file
#
# Arguments:
#   image_file      OVA file image
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__gen_vm_name_from_file() {
  local -r image_file="$1"

  if [[ -z "$image_file" ]]; then
    err "Invalid argument 'image_file': ${image_file}"
    return "$ERR_INVAL_ARG"
  fi

  local vm_name="${image_file,,}"
  vm_name="${vm_name%.ova}"
  local -r crc_sum="$(cksum "$image_file" | cut -d' ' -f1)"
  vm_name="image:${vm_name##*/}|crc:${crc_sum}|"

  echo "$vm_name"
}

#
# Generate image vm name
#
# Arguments:
#   [image_name]       image name
#
# Output:
#  Writes generated name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__gen_vm_name() {
  local image_name="${1:-}"

  if [[ -z "$image_name" ]]; then
    image_name="$(petname)"
  fi

  local -r crc_sum="$(echo "$image_name" | cksum | cut -d' ' -f1)"

  echo "image:${image_name}|crc:${crc_sum}|"
}

#
# Import an OVA image from file
#
# Arguments:
#   image_file      OVF file image
#   [image_name]    image name (default: OVF file name)
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::__pull_from_file() {
  local -r image_file="$1"
  local -r custom_image_name="${2:-}"

  if [[ ! -f "$image_file" ]]; then
    err "OVA file image doesn't exist"
    return "$ERR_NOFILE"
  fi

  local vm_name="$(vedv::image_service::__gen_vm_name_from_file "$image_file")"
  local image_id="$(vedv::image_service::_get_image_id "$vm_name")"
  local image_name="$(vedv::image_service::_get_image_name "$vm_name")"
  local -r image_cache_vm_name="image-cache|crc:${image_id}0|"

  if [[ -n "$custom_image_name" ]]; then
    vm_name="$(vedv::image_service::__gen_vm_name "$custom_image_name")"
    image_id="$(vedv::image_service::_get_image_id "$vm_name")"
    image_name="$custom_image_name"
  fi

  if [[ -n "$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$vm_name")" ]]; then
    echo "$image_name"
    return 0
  fi

  # Import an OVF from a file
  local output
  local -i ecode=0

  if [[ -z "$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name "$image_cache_vm_name")" ]]; then
    output="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::import "$image_file" "$image_cache_vm_name" 2>&1)" || ecode=$?
  fi

  if [[ $ecode -ne 0 ]]; then
    err "$output"
    return $ecode
  fi

  output="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::clonevm_link "$image_cache_vm_name" "$vm_name" 2>&1)" || ecode=$?

  if [[ $ecode -eq 0 ]]; then
    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::set_description "$vm_name" "$image_cache_vm_name" 2>&1
    echo "$image_name"
  else
    err "$output"
  fi

  return $ecode
}

# Pull an OVF image from a registry or file
#
# Arguments:
#   image      image name or an OVF file
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::pull() {
  # IMPL: test this function
  local -r image="$1"

  if [[ -f "${image:-}" ]]; then
    vedv::image_service::__pull_from_file "$image"
  else
    # IMPL: Pull an OVF image from a registry
    err "Not implemented: 'vedv::image_service::__pull_from_registry'"
    return "$ERR_NOTIMPL"
  fi
}

#
#  List images
#
# Output:
#  writes  id, name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::list() {

  local vm_names
  vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list)"
  vm_names="$(echo "$vm_names" | grep "image:.*|" || :)"
  readonly vm_names

  for vm_name in $vm_names; do
    echo "$(vedv::image_service::_get_image_id "$vm_name") $(vedv::image_service::_get_image_name "$vm_name")"
  done
}

#
# Remove one or more images
#
# Arguments:
#   image_name_or_ids     image name or id
#
# Output:
#  writes image name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::rm() {
  local -ra image_name_or_ids=("$@")

  if [[ "${#image_name_or_ids[@]}" -eq 0 ]]; then
    err 'At least one image is required'
    return "$ERR_INVAL_ARG"
  fi

  local -A image_failed=()

  for image in "${image_name_or_ids[@]}"; do
    local vm_name="$(vedv::"${__VEDV_IMAGE_SERVICE_HYPERVISOR}"::list_wms_by_partial_name "image:${image}|" | head -n 1)"

    if [[ -z "$vm_name" ]]; then
      vm_name="$(vedv::"${__VEDV_IMAGE_SERVICE_HYPERVISOR}"::list_wms_by_partial_name "|crc:${image}|" | head -n 1)"

      if [[ -z "$vm_name" ]]; then
        image_failed['No such images']+="$image "
        continue
      fi
    fi

    local snapshots
    snapshots="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::show_snapshots "$vm_name")"
    snapshots="$(echo "$snapshots" | grep -o 'container:.*|' | grep -o ':.*|' | tr -d ':|' | tr '\n' ' ' || :)"

    if [[ -n "$snapshots" ]]; then
      image_failed["Failed to remove image ${image} because it has containers, remove them first"]="$snapshots"
      image_failed["Failed to remove images"]+="$image "
      continue
    fi

    local image_cache_vm_name="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::get_description "$vm_name")"

    if ! vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::rm "$vm_name" &>/dev/null; then
      image_failed["Failed to remove images"]+="$image "
      continue
    fi
    vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::delete_snapshot "$image_cache_vm_name" "$vm_name" &>/dev/null

    echo -n "$image "
  done

  echo
  for err_msg in "${!image_failed[@]}"; do
    err "${err_msg}: ${image_failed["$err_msg"]}"
  done

  if [[ "${#image_failed[@]}" -ne 0 ]]; then
    return "$ERR_IMAGE_OPERATION"
  fi

  return 0
}

#
# Remove unused images cache
#
# Output:
#  Writes deleted cache id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_service::remove_unused_cache() {
  local -r image_cache_vm_names="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::list_wms_by_partial_name 'image-cache|')"

  local failed_remove=''

  for vm_name in $image_cache_vm_names; do
    local snapshots
    snapshots="$(vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::show_snapshots "$vm_name")"

    if [[ -z "$snapshots" ]]; then
      local image_id="$(vedv::image_service::_get_image_id "$vm_name")"

      if ! vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::rm "$vm_name" &>/dev/null; then
        failed_remove+="$image_id "
        continue
      fi

      echo -n "$image_id "
    fi
  done
  echo

  if [[ -n "$failed_remove" ]]; then
    err "Failed to remove caches: ${failed_remove}"
    return "$ERR_IMAGE_OPERATION"
  fi
  return 0
}

# IMPL: Pull an image or a repository from a registry
vedv::image_service::import() {
  echo 'vedv:image:pull'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::pull
}

# IMPL: Build an image from a Vedvfile
vedv::image_service::build() {
  echo 'vedv:image:build'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::build
}
