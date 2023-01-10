#
# Manage containers
#
# Process command line and call hypervisors
#

# VARIABLES

__VEDV_CONTAINER_HYPERVISOR=''

# FUNCTIONS

# IMPL: Create a new container
vedv::container::create() {
  echo 'vedv::container::create'
  vedv::"$__VEDV_CONTAINER_HYPERVISOR"::container::create
}
#
vedv::container::__create_run_cmd() {
  echo 'vedv::container::__create_run_cmd'
  vedv::container::create
}

# IMPL: Start one or more stopped containers
vedv::container::start() {
  echo 'vedv::container::start'
  vedv::"$__VEDV_CONTAINER_HYPERVISOR"::container::start
}
#
vedv::container::__start_run_cmd() {
  echo 'vedv::container::__start_run_cmd'
  vedv::container::start
}

#  IMPL: Stop one or more running containers
vedv::container::stop() {
  echo 'vedv::container::stop'
  vedv::"$__VEDV_CONTAINER_HYPERVISOR"::container::stop
}
#
vedv::container::__stop_run_cmd() {
  echo 'vedv::container::__stop_run_cmd'
  vedv::container::stop
}

# IMPL: Remove one or more containers
vedv::container::rm() {
  echo 'vedv::container::rm'
  vedv::"$__VEDV_CONTAINER_HYPERVISOR"::container::rm
}
#
vedv::container::__rm_run_cmd() {
  echo 'vedv::container::__rm_run_cmd'
  vedv::container::rm
}

# IMPL: Create and run a container from an image
vedv::container::run() {
  echo 'vedv::container::run'
  vedv::"$__VEDV_CONTAINER_HYPERVISOR"::container::run
}
#
vedv::container::__run_run_cmd() {
  echo 'vedv::container::__run_run_cmd'
  vedv::container::run
}

vedv::container::__help() {
  echo 'vedv::container::__help'
}

vedv::container::run_cmd() {

  case "${1:-}" in
  virtualbox)
    shift
    readonly __VEDV_CONTAINER_HYPERVISOR='virtualbox'
    ;;
  qemu)
    shift
    readonly __VEDV_CONTAINER_HYPERVISOR='qemu'
    ;;
  *)
    readonly __VEDV_CONTAINER_HYPERVISOR='virtualbox'
    ;;
  esac

  [[ $# == 0 ]] && set -- '-h'

  if [[ "${1:-}" == @(-h|--help) ]]; then
    vedv::container::__help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::container::__help
      return 0
      ;;
    create)
      shift
      vedv::container::__create_run_cmd "$@"
      return $?
      ;;
    start)
      shift
      vedv::container::__start_run_cmd "$@"
      return $?
      ;;
    stop)
      shift
      vedv::container::__stop_run_cmd "$@"
      return $?
      ;;
    rm)
      shift
      vedv::container::__rm_run_cmd "$@"
      return $?
      ;;
    run)
      shift
      vedv::container::__run_run_cmd "$@"
      return $?
      ;;

    *)
      echo -e "Invalid parameter: ${1}\n" >&2
      vedv::container::__help
      return 10
      ;;
    esac
  done
}
