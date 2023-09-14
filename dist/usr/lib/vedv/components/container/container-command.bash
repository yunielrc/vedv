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
# Show help for __create command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__create_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container create [FLAGS] [OPTIONS] IMAGE_NAME|URL|FILE|FQN

Create a new container

Flags:
  -h, --help                                 show help
  -s, --standalone                           create a standalone container
  -P, --publish-all                          publish all exposed ports to random ports

Options:
  -n, --name <name>                          assign a name to the container
  -p, --publish <host-port>:<port>[/proto]   publish a container's port(s) to the host.
                                             proto is tcp or udp (default tcp)
  -c, --cpus <cpus>                          number of CPUs
  -m, --memory <memory>                      memory capacity
HELPMSG
}

#
# Create a new container
#
# Flags:
#   -h, --help                        Show help
#   -s, --standalone                  Create a standalone container
#
# Options:
#   [-n, --name]                      Container name
#
# Arguments:
#   IMAGE_NAME|URL|FILE|FQN   Image name, url, file or fully qualified name
#
# Output:
#  Writes container ID to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__create() {
  local standalone=false
  local name=''
  local image=''
  local -a publish_ports=()
  local publish_all=false
  local cpus=''
  local memory=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do

    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__create_help
      return 0
      ;;
    -s | --standalone)
      readonly standalone=true
      shift
      ;;
    -P | --publish-all)
      readonly publish_all=true
      shift
      ;;
    # options
    -n | --name)
      readonly name="${2:-}"
      # validate argument
      if [[ -z "$name" ]]; then
        err "No container name specified\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    -p | --publish)
      local new_publish_port="${2:-}"
      # validate argument
      if [[ -z "$new_publish_port" ]]; then
        err "No publish port specified\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      publish_ports+=("$new_publish_port")
      shift 2
      ;;
    -c | --cpus)
      readonly cpus="${2:-}"
      # validate argument
      if [[ -z "$cpus" ]]; then
        err "No cpus specified\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    -m | --memory)
      readonly memory="${2:-}"
      # validate argument
      if [[ -z "$memory" ]]; then
        err "No memory specified\n"
        vedv::container_command::__create_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly image="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image" ]]; then
    err "Missing argument 'IMAGE'\n"
    vedv::container_command::__create_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::create \
    "$image" \
    "$name" \
    "$standalone" \
    "${publish_ports[*]}" \
    "$publish_all" \
    "$cpus" \
    "$memory"
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help    show help
  -w, --wait    wait for SSH
  --show        show container gui on supported desktop platforms
HELPMSG
}

#
# Start one or more stopped containers
#
# Flags:
#   -h, --help          show help
#   -w, --wait          wait for SSH
#   --show              show container gui on supported desktop platforms
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
  local container_names_or_ids=''
  local wait_for_ssh=false
  local show=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__start_help
      return 0
      ;;
    -w | --wait)
      readonly wait_for_ssh=true
      shift
      ;;
    --show)
      readonly show=true
      shift
      ;;
    # arguments
    *)
      readonly container_names_or_ids="$*"
      break
      ;;
    esac
  done

  if [[ -z "$container_names_or_ids" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__start_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::start \
    "$container_names_or_ids" \
    "$wait_for_ssh" \
    "$show"
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
  local container_names_or_ids=''
  local force=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__rm_help
      return 0
      ;;
    --force)
      readonly force=true
      shift
      ;;
    *)
      readonly container_names_or_ids="$*"
      break
      ;;
    esac
  done

  if [[ -z "$container_names_or_ids" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__rm_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::remove "$container_names_or_ids" "$force"
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container rm [FLAGS] CONTAINER [CONTAINER...]

Remove one or more running containers

Aliases:
  rm, remove

Flags:
  -h, --help    show help
  --force       force remove
HELPMSG
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container stop [FLAGS] CONTAINER [CONTAINER...]

Stop one or more running containers

Flags:
  -h, --help    show help
  --no-save     do not save state
HELPMSG
}

#
# Stop one or more running containers
#
# Flags:
#   -h, --help    show help
#   --no-save     do not save state
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
#
# Output:
#   writes stopped container name or id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__stop() {
  local container_names_or_ids=''
  local save_state=true

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__stop_help
      return 0
      ;;
    --no-save)
      readonly save_state=false
      shift
      ;;
    # arguments
    *)
      readonly container_names_or_ids="$*"
      break
      ;;
    esac
  done

  if [[ -z "$container_names_or_ids" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__stop_help
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$save_state" == true ]]; then
    vedv::container_service::save_state "$container_names_or_ids"
  else
    vedv::container_service::stop "$container_names_or_ids"
  fi
}

#
# Show help for __restart command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__restart_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container restart [FLAGS] CONTAINER [CONTAINER...]

Restart one or more started containers

Flags:
  -h, --help    show help
  -w, --wait    wait for SSH
HELPMSG
}

#
# Restart one or more started containers
#
# Flags:
#   -h, --help          show help
#   -w, --wait          wait for SSH
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
# Output:
#   writes container id and name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__restart() {

  if [[ $# == 0 ]]; then set -- '-h'; fi

  if [[ "$1" == @(-h|--help) ]]; then
    vedv::container_command::__restart_help
    return 0
  fi

  set -o noglob
  local -r args_str="${*/--wait/}"
  # shellcheck disable=SC2206
  local -r args=(--no-save ${args_str/-w/})
  set +o noglob

  vedv::container_command::__stop "${args[@]}" >/dev/null ||
    return $?

  vedv::container_command::__start "$@" ||
    return $?
}

#
# Show help for __kill command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__kill_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container kill [FLAGS] CONTAINER [CONTAINER...]

Kill one or more running containers

Flags:
  -h, --help    show help
HELPMSG
}

#
# Kill one or more running containers
#
# Flags:
#   -h, --help    show help
#
# Arguments:
#   CONTAINER  [CONTAINER...]     one or more container name or id
#
#
# Output:
#   writes killed container name or id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__kill() {
  local container_names_or_ids=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__kill_help
      return 0
      ;;
    # arguments
    *)
      readonly container_names_or_ids="$*"
      break
      ;;
    esac
  done

  if [[ -z "$container_names_or_ids" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__kill_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::kill "$container_names_or_ids"
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
      readonly list_all=true
      ;;
    *)
      readonly partial_name="$1"
      break
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container ls [FLAGS] [CONTAINER PARTIAL NAME]

List containers

Aliases:
  ls, ps, list

Flags:
  -h, --help    show help
  -a, --all     show all containers (default shows just running)
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
  local user=''
  local container_name_or_id=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__connect_help
      return 0
      ;;
    -r | --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    # options
    -u | --user)
      shift
      readonly user="${1:-}"
      # validate argument
      if [[ -z "$user" ]]; then
        err "No user specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      shift
      ;;
    # arguments
    *)
      readonly container_name_or_id="$1"
      break
      ;;
    esac
  done

  if [[ -z "$container_name_or_id" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__connect_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::connect "$container_name_or_id" "$user"
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container login [FLAGS] [OPTIONS] CONTAINER

Login to a container

Aliases:
  login, connect

Flags:
  -h, --help          show help
  -r, --root          login as root

Options:
  -u, --user  <user>  login as user
HELPMSG
}

#
# Execute cmd in a container
#
# Flags:
#   -h, --help                    show help
#   -r, --root                    execute command as root user
#
# Options:
#   -u, --user    <user>  string  user to execute command
#   -w, --workdir <dir>   string  working directory for command
#   -e, --env     <env>   string  environment variable for command
#   -s, --shell   <shell> string  shell to use for command
#
# Arguments:
#   CONTAINER             string  container name or id
#   CMD                   string  command to execute
#
# Output:
#   writes any error to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__execute_cmd() {
  local user=''
  local workdir=''
  local env=''
  local shell=''
  local container_name_or_id=''
  local cmd=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__execute_cmd_help
      return 0
      ;;
    -r | --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    # options
    -u | --user)
      readonly user="${2:-}"
      # validate argument
      if [[ -z "$user" ]]; then
        err "No user specified\n"
        vedv::container_command::__execute_cmd
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    -w | --workdir)
      readonly workdir="${2:-}"
      # validate argument
      if [[ -z "$workdir" ]]; then
        err "No workdir specified\n"
        vedv::container_command::__execute_cmd
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    -e | --env)
      local new_env="${2:-}"
      # validate argument
      if [[ -z "$new_env" ]]; then
        err "No environment specified\n"
        vedv::container_command::__execute_cmd
        return "$ERR_INVAL_ARG"
      fi
      env+="${new_env} "
      shift 2
      ;;
    -s | --shell)
      readonly shell="${2:-}"
      # validate argument
      if [[ -z "$shell" ]]; then
        err "No shell specified\n"
        vedv::container_command::__execute_cmd
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly container_name_or_id="$1"
      shift

      if [[ "$#" -ne 0 ]]; then
        readonly cmd="$*"
      elif [[ ! -t 0 ]]; then
        # if stdin FD is not opened on a terminal its because there is input data,
        readonly cmd="$(cat -)"
      fi
      break
      ;;
    esac
  done
  # validate arguments
  if [[ -z "$container_name_or_id" ]]; then
    err "No container specified\n"
    vedv::container_command::__execute_cmd_help
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "No command specified\n"
    vedv::container_command::__execute_cmd_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::execute_cmd \
    "$container_name_or_id" \
    "$cmd" \
    "$user" \
    "$workdir" \
    "$env" \
    "$shell"
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container exec [FLAGS] [OPTIONS] CONTAINER COMMAND1 [COMMAND2] ...
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container exec [FLAGS] [OPTIONS] CONTAINER <<EOF
COMMAND1
[COMMAND2]
...
EOF

Execute a command in a container

Flags:
  -h, --help            show help
  -r, --root            execute command as root user

Options:
  -u, --user    <user>  execute command as specific user
  -w, --workdir <dir>   working directory for command
  -e, --env     <env>   environment variable for command
  -s, --shell   <shell> shell to use for command
HELPMSG
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
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container copy [FLAGS] [OPTIONS] CONTAINER LOCAL_SRC CONTAINER_DEST

Copy files from local filesystem to a container

Aliases:
  cp, copy

Flags:
  -h, --help              show help
  -r, --root              copy as root user
  --no-vedvfileignore     ignore vedvfileignore files

Options:
  -u, --user <user>       copy as specific user
  --chown <user:group>    change owner of copied files
  --chmod <mode>          change mode of copied files
HELPMSG
}

#
# Copy files from local filesystem to a container
#
# Flags:
#   -h | --help               show help
#   --root                    use root user for copy
#   --no-vedvfileignore       ignore vedvfileignore files
#
# Options:
#   -u, --user <user>       copy as specific user
#   --chown <user:group>    change owner of copied files
#   --chmod <mode>          change mode of copied files
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
  local chown=''
  local chmod=''
  local container_name_or_id=''
  local src=''
  local dest=''
  local no_vedvfileignore=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::container_command::__copy_help
      return 0
      ;;
    -r | --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    --no-vedvfileignore)
      readonly no_vedvfileignore=true
      shift
      ;;
    # options
    -u | --user)
      readonly user="${2:-}"
      # validate argument
      if [[ -z "$user" ]]; then
        err "No user specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --chown)
      readonly chown="${2:-}"
      # validate argument
      if [[ -z "$chown" ]]; then
        err "No chown value specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --chmod)
      readonly chmod="${2:-}"
      # validate argument
      if [[ -z "$chmod" ]]; then
        err "No chmod value specified\n"
        vedv::container_command::__copy_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly container_name_or_id="$1"
      readonly src="${2:-}"
      readonly dest="${3:-}"
      break
      ;;
    esac
  done
  # validate arguments
  if [[ -z "$container_name_or_id" ]]; then
    err "No container specified\n"
    vedv::container_command::__copy_help
    return "$ERR_INVAL_ARG"
  fi
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

  vedv::container_service::copy \
    "$container_name_or_id" \
    "$src" \
    "$dest" \
    "$user" \
    "$chown" \
    "$chmod" \
    "$no_vedvfileignore"
}

#
# List port mappings for the container
#
# Flags:
#   [-h | --help]		show help
#
# Arguments:
#   CONTAINER			container name or id
#
# Output:
#   writes port mappings (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__list_ports() {
  local container_name_or_id=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__list_ports_help
      return 0
      ;;
    *)
      readonly container_name_or_id="$1"
      break
      ;;
    esac
  done

  if [[ -z "$container_name_or_id" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__list_ports_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::list_ports "$container_name_or_id"
}

#
# Show help for __list_ports command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__list_ports_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container ports CONTAINER

List port mappings for the container

Aliases:
  ports, list-ports

Flags:
  -h, --help          show help
HELPMSG
}

#
# List exposed ports
#
# Flags:
#   [-h | --help]		show help
#
# Arguments:
#   CONTAINER string    container name or id
#
# Output:
#   writes port mappings (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_command::__list_exposed_ports() {
  local container_name_or_id=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::container_command::__list_exposed_ports_help
      return 0
      ;;
    *)
      readonly container_name_or_id="$1"
      break
      ;;
    esac
  done

  if [[ -z "$container_name_or_id" ]]; then
    err "Missing argument 'CONTAINER'\n"
    vedv::container_command::__list_exposed_ports_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::container_service::cache::list_exposed_ports "$container_name_or_id"
}

#
# Show help for __list_exposed_ports command
#
# Output:
#  Writes the help to the stdout
#
vedv::container_command::__list_exposed_ports_help() {
  cat <<-HELPMSG
Usage:
${__VED_CONTAINER_COMMAND_SCRIPT_NAME} container list-exposed-ports CONTAINER

List exposed ports for the container

Aliases:
  eports, list-exposed-ports

Flags:
  -h, --help          show help
HELPMSG
}

#
# Show help
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

Flags:
  -h, --help    show this help

Commands:
  create        create a new container
  start         start one or more containers
  remove        remove one or more containers
  stop          stop one or more containers
  restart       restart one or more containers
  kill          kill one or more running containers
  list          list containers
  login         login to a container
  exec          execute a command in a container
  copy          copy files from local filesystem to a container
  ports         list port mappings for the container
  eports        list exposed ports for the container

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
    restart)
      shift
      vedv::container_command::__restart "$@"
      return $?
      ;;
    kill)
      shift
      vedv::container_command::__kill "$@"
      return $?
      ;;
    rm | remove)
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
    copy | cp)
      shift
      vedv::container_command::__copy "$@"
      return $?
      ;;
    ports | list-ports)
      shift
      vedv::container_command::__list_ports "$@"
      return $?
      ;;
    eports | list-exposed-ports)
      shift
      vedv::container_command::__list_exposed_ports "$@"
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
