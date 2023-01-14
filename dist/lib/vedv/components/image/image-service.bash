#
# Manage images
#
#

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

# IMPL: Pull an image or a repository from a registry
vedv::image_service::pull() {
  echo 'vedv:image:pull'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::pull
}

# IMPL: Build an image from a Vedvfile
vedv::image_service::build() {
  echo 'vedv:image:build'
  vedv::"$__VEDV_IMAGE_SERVICE_HYPERVISOR"::image::build
}
