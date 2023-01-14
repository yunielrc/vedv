#
# Manage containers
#
# Process command line and call service
#

# VARIABLES

# FUNCTIONS

#
# Constructor
#
# Arguments:
#   script_name       name of the script
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::constructor() {
  readonly __VED_CONTAINER_COMMAND_SCRIPT_NAME="$1"
}

#
# IMPL: Create a new container
vedv::container_command::__create() {
  echo 'vedv::container-command::__create'
  vedv::container_service::create
}

# IMPL: Start one or more stopped containers
vedv::container_command::__start() {
  echo 'vedv::container_command::__start'
  vedv::container_service::start
}

#  IMPL: Stop one or more running containers
vedv::container_command::__stop() {
  echo 'vedv::container_command::__stop'
  vedv::container_service::stop
}

# IMPL: Remove one or more containers
vedv::container_command::__rm() {
  echo 'vedv::container_command::__rm'
  vedv::container_service::rm
}

# IMPL: Create and run a container from an image
vedv::container_command::__run() {
  echo 'vedv::container_command::__run'
  vedv::container_service::run
}

vedv::container_command::__help() {
  echo 'vedv::container_command::__help'
}

vedv::container_command::run_cmd() {

  [[ $# == 0 ]] && set -- '-h'

  if [[ "${1:-}" == @(-h|--help) ]]; then
    vedv::container_command::__help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::container_command::__help
      return 0
      ;;
    create)
      shift
      vedv::container_command::__create "$@"
      return $?
      ;;
    start)
      shift
      vedv::container_command::__start "$@"
      return $?
      ;;
    stop)
      shift
      vedv::container_command::__stop "$@"
      return $?
      ;;
    rm)
      shift
      vedv::container_command::__rm "$@"
      return $?
      ;;
    run)
      shift
      vedv::container_command::__run "$@"
      return $?
      ;;

    *)
      echo -e "Invalid parameter: ${1}\n" >&2
      vedv::container_command::__help
      return 10
      ;;
    esac
  done
}
