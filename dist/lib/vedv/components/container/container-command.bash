#
# Manage containers
#
# Process command line and call service
#

# REQUIRE
# . '../../utils.bash'
# . './container-service.bash'

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
# Create a new container
#
# Flags:
#   [-h | --help | help]  Show help
#
# Options:
#   [--name]              Container name
#
# Arguments:
#   IMAGE                 Image name or an OVF file
#
# Output:
#  Writes container ID to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__create() {
  local image
  local name=''

  [[ $# == 0 ]] && set -- '-h'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::container_command::__create_help
      return 0
      ;;
    --name)
      shift
      name="$1"
      shift
      ;;
    *)
      if [[ -z "${image:-}" ]]; then
        image="$1"
        shift
      else
        echo -e "Invalid parameter: ${1}\n" >&2
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  vedv::container_service::create "$image" "${name:-}"
}

#
# Show help for __create command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__create_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container create [OPTIONS] IMAGE

Create a new container

Options:
  --name           Assign a name to the container
HELPMSG
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

#
# Show help
#
# Flags:
#   [-s| --short]   Print short description
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__help() {
  # if [[ "${1:-}" == @(-s|--short) ]]; then
  #   echo "${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container        Manage containers"
  #   return 0
  # fi
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container COMMAND

Manage containers

Commands:
  create           Create a new container

Run '${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container COMMAND --help' for more information on a command.
HELPMSG
}

vedv::container_command::run_cmd() {

  [[ $# == 0 ]] && set -- '-h'

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