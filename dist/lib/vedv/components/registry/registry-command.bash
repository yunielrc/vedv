#
# Registry Nextcloud Command
#
#

# this is only for code completion
if false; then
  . './../../../utils.bash'
  . './registry-service.bash'
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
vedv::registry_command::constructor() {
  readonly __VED_REGISTRY_COMMAND_SCRIPT_NAME="$1"
}

#
# Show help for __push command
#
# Output:
#  Writes the help to the stdout
#
vedv::registry_command::__push_help() {
  cat <<-HELPMSG
Usage:
${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry push [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME

Upload an image to a registry

Aliases:
  ${__VED_REGISTRY_COMMAND_SCRIPT_NAME} image pull

Flags:
  -h, --help          show help

Options:
  -n, --name <name>   name of the image that will be pushed to the registry,
                      if not specified, the name on fqn will be used

HELPMSG
}

#
# Upload an image to a registry
#
# Flags:
#   -h, --help          show help
#
# Options:
#   -n, --name <name>   name of the image that will be pushed to the registry,
#                       if not specified, the name on fqn will be used
#
# Arguments:
#   IMAGE_FQN               string  scheme: [domain/]user@collection/name
#
# Output:
#   Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_command::__push() {
  local image_fqn=''
  local image_name=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::registry_command::__push_help
      return 0
      ;;
    # options
    -n | --name)
      readonly image_name="${2:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "No image name specified\n"
        vedv::registry_command::__push_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly image_fqn="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image_fqn" ]]; then
    err "Missing argument 'IMAGE_FQN'\n"
    vedv::registry_command::__push_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::registry_service::push \
    "$image_fqn" \
    "$image_name"
}

#
# Show help for __pull command
#
# Output:
#  Writes the help to the stdout
#
vedv::registry_command::__pull_help() {
  cat <<-HELPMSG
Usage:
${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry pull [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME

Download an image from the registry

Aliases:
  ${__VED_REGISTRY_COMMAND_SCRIPT_NAME} image pull

Flags:
  -h, --help            show help
  --no-cache            do not use cache when downloading the image

Options:
  -n, --name <name>     image name

HELPMSG
}

#
# Download an image from the registry
#
# Flags:
#   -h, --help          show help
#   --no-cache          do not use cache when downloading the image
#
# Options:
#   -n, --name <name>   image name
#
# Arguments:
#   IMAGE_FQN           string  scheme: [domain/]user@collection/name
#
# Output:
#   Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_command::__pull() {
  local no_cache=false
  local image_name=''
  local image_fqn=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::registry_command::__pull_help
      return 0
      ;;
    --no-cache)
      readonly no_cache=true
      shift
      ;;
    # options
    -n | --name)
      readonly image_name="${2:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "No image name specified\n"
        vedv::registry_command::__pull_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly image_fqn="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image_fqn" ]]; then
    err "Missing argument 'IMAGE_FQN'\n"
    vedv::registry_command::__pull_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::registry_service::pull \
    "$image_fqn" \
    "$image_name" \
    "$no_cache"
}

#
# Show help for __cache_clean command
#
# Output:
#  Writes the help to the stdout
#
vedv::registry_command::__cache_clean_help() {
  cat <<-HELPMSG
Usage:
${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry cache-clean

clean the registry cache

Flags:
  -h, --help            show help

HELPMSG
}

#
# clean the registry cache
#
# Flags:
#   -h, --help          show help
#
# Output:
#   Writes the # of files removed and space freed to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_command::__cache_clean() {

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::registry_command::__cache_clean_help
      return 0
      ;;
    # arguments
    *)
      err "Invalid parameter: ${1}\n"
      vedv::registry_command::__cache_clean_help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done

  vedv::registry_service::cache_clean
}

#
# Show help
#
# Output:
#  Writes the help to the stdout
#
vedv::registry_command::__help() {
  cat <<-HELPMSG
Usage:
${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry COMMAND

Manage registry

Flags:
  -h, --help    show this help

Commands:
  pull          download an image from the registry
  push          upload an image to a registry
  cache-clean   clean the registry cache

Run '${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry COMMAND --help' for more information on a command.
HELPMSG
}

vedv::registry_command::run_cmd() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::registry_command::__help
      return 0
      ;;
    pull)
      shift
      vedv::registry_command::__pull "$@"
      return $?
      ;;
    push)
      shift
      vedv::registry_command::__push "$@"
      return $?
      ;;
    cache-clean)
      shift
      vedv::registry_command::__cache_clean "$@"
      return $?
      ;;
    *)
      err "Invalid parameter: ${1}\n"
      vedv::registry_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
