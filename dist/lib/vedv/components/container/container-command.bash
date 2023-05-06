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
#   [-h | --help ]      Show help
#
# Options:
#   [-n | --name]            Container name
#
# Arguments:
#   IMAGE               Image name or an OVF file
#
# Output:
#  Writes container ID to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__create() {
  local name=''
  local image=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    local arg="$1"

    case "$arg" in
    -h | --help)
      vedv::container_command::__create_help
      return 0
      ;;
    -n | --name)
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
        err "Invalid argument '${1}'\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  if [[ -z "$image" ]]; then
    err "Missing argument 'IMAGE'\n"
    vedv::container_command::__create_help
    return "$ERR_INVAL_ARG"
  fi

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
  -n, --name name         Assign a name to the container
HELPMSG
}

#
# Start one or more stopped containers
#
# Flags:
#   [-h | --help]          show help
#   [-w | --wait]          wait for SSH
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

  local wait_for_ssh=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__start_help
      return 0
      ;;
    -w | --wait)
      wait_for_ssh=true
      shift
      ;;
    *)
      if [[ "$wait_for_ssh" == false ]]; then
        vedv::container_service::start_no_wait_ssh "$@"
      else
        vedv::container_service::start "$@"
      fi
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

Flags:
  -w, --wait          Wait for SSH
HELPMSG
}

#
# Remove one or more running containers
#
# Flags:
#   [-h | --help]          show help
#   [-f | --force]         force remove
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
  local force=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__rm_help
      return 0
      ;;
    -f | --force)
      shift
      force=true
      ;;
    *)
      vedv::container_service::remove "$force" "$@"
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

Flags:
  -f, --force         Force remove
HELPMSG
}

#
# Stop one or more running containers
#
# Flags:
#   [-h | --help]          show help
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
      vedv::container_service::stop "$@"
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
#   [-h | --help]     show help
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
        err "Invalid argument: ${1}\n"
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

#
# Establish a ssh connection to a container
#
# Flags:
#   [-h | --help]       show help
#
# Arguments:
#   CONTAINER           container name or id
#
# Output:
#   writes any error to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__connect() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__connect_help
      return 0
      ;;
    *)
      vedv::container_service::connect "$1"
      return $?
      ;;
    esac
  done
}

#
# Show help for __connect command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__connect_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container login|connect CONTAINER

Login to a container
HELPMSG
}

#
# Execute cmd in a container
#
# Flags:
#   [-h | --help]       show help
#
# Arguments:
#   CONTAINER           container name or id
#   CMD                 command to execute
#
# Output:
#   writes any error to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__execute_cmd() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__execute_cmd_help
      return 0
      ;;
    *)
      local container_name_or_id="$1"
      shift
      local cmd

      if [[ "$#" -ne 0 ]]; then
        cmd="$*"
      elif [[ ! -t 0 ]]; then
        # if stdin FD is not opened on a terminal its because there is input data,
        cmd="$(cat -)"
      fi
      readonly cmd

      if [[ -z "$cmd" ]]; then
        err "No command specified\n"
        vedv::container_command::__execute_cmd_help
        return "$ERR_INVAL_ARG"
      fi

      vedv::container_service::execute_cmd "$container_name_or_id" "$cmd"
      return $?
      ;;
    esac
  done
}

#
# Show help for __execute_cmd command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__execute_cmd_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container exec CONTAINER COMMAND1 [COMMAND2] ...
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container exec CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container
HELPMSG
}

#
# Copy files from local filesystem to a container
#
# Flags:
#   -h | --help               show help
#   --root                    use root user for copy
#
# Options:
#   -u, --user <user> string    user to use for copy
#
# Arguments:
#   CONTAINER         string    container name or id
#   SRC               string    source file or directory
#   DEST              string    destination file or directory
#
# Output:
#   writes any error to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__copy() {
  local user=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__copy_help
      return 0
      ;;
    --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    -u | --user)
      shift
      user="${1:-}"
      # validate argument
      if [[ -z "$user" ]]; then
        err "No user specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      shift
      ;;
    *)
      local container_name_or_id="$1"
      local src="${2:-}"
      local dest="${3:-}"
      # validate arguments
      if [[ -z "$src" ]]; then
        err "No source file specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      if [[ -z "$dest" ]]; then
        err "No dest file specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi

      vedv::container_service::copy "$container_name_or_id" "$src" "$dest" "$user"
      return $?
      ;;
    esac
  done
}

#
# Show help for __copy command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__copy_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container copy CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container

Flags:
  -h, --help        show help
  --root            copy as root user

Options:
  -u, --user        copy as specific user
HELPMSG
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
  start            Start one or more containers
  rm               Remove one or more containers
  stop             Stop one or more containers
  list             List containers
  login            Login to a container
  exec             Execute a command in a container
  copy             Copy files from local filesystem to a container

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
    login | connect)
      shift
      vedv::container_command::__connect "$@"
      return $?
      ;;
    exec)
      shift
      vedv::container_command::__execute_cmd "$@"
      return $?
      ;;
    copy)
      shift
      vedv::container_command::__copy "$@"
      return $?
      ;;
    *)
      err "Invalid argument: ${1}\n"
      vedv::container_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
