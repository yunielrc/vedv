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
#   IMAGE_FQN           string  scheme: [domain/]user@collection/name
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
# Show help for __push_link command
#
# Output:
#  Writes the help to the stdout
#
vedv::registry_command::__push_link_help() {
  cat <<-HELPMSG
Usage:
${__VED_REGISTRY_COMMAND_SCRIPT_NAME} registry push-link [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME

Upload an image link to a registry

Address format:
  http download:
    e.g.: http=http://example.com/alpine.ova | http=https://example.com/alpine.ova
  gdrive download >100mb:
    e.g.: gdrive-big=https://drive.google.com/file/d/1iya7JW_-anYYYzfQqitb_RDHJVAngzBQ/view?usp=drive_link
  gdrive download <=100mb:
    e.g.: gdrive-small=https://drive.google.com/file/d/11-Ss7b-M3ieg9x42TQoJvTv_NlzU90I2/view?usp=drive_link
  onedrive download:
    e.g.: onedrive=https://onedrive.live.com/embed?resid=DBC0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg

Aliases:
  ${__VED_REGISTRY_COMMAND_SCRIPT_NAME} image push-link

Flags:
  -h, --help                          show help

Mandatory Options:
  --image-address <address>           image address that will be used as a link
  --checksum-address  <file|address>  checksum address of the image

HELPMSG
}

#
# Upload an image link to a registry
#
# Flags:
#   -h, --help                            show help
#
# Mandatory Options:
#   --image-address <address>             image address that will be used as a link
#   --checksum-address  <file|address>    checksum address of the image
#
# Arguments:
#   IMAGE_FQN                     string  scheme: [domain/]user@collection/name
#
# Output:
#   Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_command::__push_link() {
  local image_address=''
  local checksum_address=''
  local image_fqn=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::registry_command::__push_link_help
      return 0
      ;;
    # mandatory options
    --image-address)
      readonly image_address="${2:-}"
      # validate argument
      if [[ -z "$image_address" ]]; then
        err "No image_address argument\n"
        vedv::registry_command::__push_link_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --checksum-address)
      readonly checksum_address="${2:-}"
      # validate argument
      if [[ -z "$checksum_address" ]]; then
        err "No checksum_address argument\n"
        vedv::registry_command::__push_link_help
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

  # validate parameters
  if [[ -z "$image_address" ]]; then
    err "No image_address specified\n"
    vedv::registry_command::__push_link_help
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$checksum_address" ]]; then
    err "No checksum_address specified\n"
    vedv::registry_command::__push_link_help
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$image_fqn" ]]; then
    err "Missing argument 'IMAGE_FQN'\n"
    vedv::registry_command::__push_link_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::registry_service::push_link \
    "$image_address" \
    "$checksum_address" \
    "$image_fqn"
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
  push-link     upload an image link to a registry
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
    push-link)
      shift
      vedv::registry_command::__push_link "$@"
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
