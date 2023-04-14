#
# Manage containers
#
# Process command line and call service
#

# this is only for code completion
if false; then
  . '../../utils.bash'
  . './container-service.bash'
fi

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
  local image=''
  local name=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    local arg="$1"

    case "$arg" in
    -h | --help)
      vedv::container_command::__create_help
      return 0
      ;;
    --name)
      shift
      name="${1:-}"
      # validate argument
      if [[ -z "$name" ]]; then
        err "Missing argument for option '${arg}'\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      shift
      ;;
    *)
      if [[ -z "$image" ]]; then
        image="$1"
        shift
      else
        err "Invalid parameter: ${1}\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  vedv::container_service::create "$image" "$name"
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

#
# Start one or more stopped containers
#
# Flags:
#   [-h | --help | help]          show help
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
# Output:
#   writes container name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__start() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__start_help
      return 0
      ;;
    *)
      vedv::container_service::start "${@}"
      return $?
      ;;
    esac
  done
}

#
# Show help for __start command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__start_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container start CONTAINER [CONTAINER...]

Start one or more stopped containers
HELPMSG
}

#
# Remove one or more running containers
#
# Flags:
#   [-h | --help | help]          show help
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
# Output:
#   writes container name or id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__rm() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__rm_help
      return 0
      ;;
    *)
      vedv::container_service::rm "${@}"
      return $?
      ;;
    esac
  done
}

#
# Show help for __rm command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__rm_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container rm CONTAINER [CONTAINER...]

Remove one or more running containers
HELPMSG
}

#
# Stop one or more running containers
#
# Flags:
#   [-h | --help | help]          show help
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
# Output:
#   writes container name or id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__stop() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__stop_help
      return 0
      ;;
    *)
      vedv::container_service::stop "${@}"
      return $?
      ;;
    esac
  done
}

#
# Show help for __stop command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__stop_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container stop CONTAINER [CONTAINER...]

Stop one or more running containers
HELPMSG
}

#
# List containers
#
# Flags:
#   [-h | --help | help]     show help
#   [-a, --all]              show all containers (default shows just running)
#
# Output:
#   writes container id, name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__list() {
  local list_all=false
  local partial_name=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__list_help
      return 0
      ;;
    -a | --all)
      shift
      list_all=true
      ;;
    *)
      if [[ -z "$partial_name" ]]; then
        partial_name="$1"
        shift
      else
        err "Invalid parameter: ${1}\n"
        vedv::container_command::__list_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  vedv::container_service::list "$list_all" "$partial_name"
}

#
# Show help for __list command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__list_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} docker container ls [OPTIONS] [CONTAINER PARTIAL NAME]

List containers

Aliases:
  ls, ps, list

Options:
  -a, --all        Show all containers (default shows just running)
HELPMSG
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
  start            Start one or more stopped containers
  rm               Remove one or more running containers
  stop             Stop one or more running containers
  list             List containers

Run '${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container COMMAND --help' for more information on a command.
HELPMSG
}

vedv::container_command::run_cmd() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

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
    ls | ps | list)
      shift
      vedv::container_command::__list "$@"
      return $?
      ;;

    run)
      shift
      vedv::container_command::__run "$@"
      return $?
      ;;

    *)
      err "Invalid parameter: ${1}\n"
      vedv::container_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
