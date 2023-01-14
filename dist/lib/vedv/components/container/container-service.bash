#
# Manage containers
#
#

# VARIABLES

__VEDV_CONTAINER_SERVICE_HYPERVISOR=''

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
vedv::container_service::constructor() {
  readonly __VEDV_CONTAINER_SERVICE_HYPERVISOR="$1"
}

# IMPL: Create a new container
vedv::container_service::create() {
  echo 'vedv::container_service::create'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::create
}

# IMPL: Start one or more stopped containers
vedv::container_service::start() {
  echo 'vedv::container_service::start'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::start
}

#  IMPL: Stop one or more running containers
vedv::container_service::stop() {
  echo 'vedv::container_service::stop'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::stop
}

# IMPL: Remove one or more containers
vedv::container_service::rm() {
  echo 'vedv::container_service::rm'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::rm
}

# IMPL: Create and run a container from an image
vedv::container_service::run() {
  echo 'vedv::container_service::run'
  vedv::"$__VEDV_CONTAINER_SERVICE_HYPERVISOR"::container::run
}
