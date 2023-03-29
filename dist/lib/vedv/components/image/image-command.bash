#
# Manage images
#
# Process command line and call service
#

# this is only for code completion
if false; then
  . '../../utils.bash'
  . './image-service.bash'
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
vedv::image_command::constructor() {
  readonly __VED_IMAGE_COMMAND_SCRIPT_NAME="$1"
}

#
# Pull an image from a registry or file
#
# Flags:
#   [-h | --help | help]  Show help
#
# Arguments:
#   IMAGE          Image name or an OVF file
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__pull() {
  local image
  # TODO: change if [[ $# == 0 ]]; then; set -- '-h'; fi
  [[ $# == 0 ]] && set -- '-h'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__pull_help
      return 0
      ;;
    *)
      if [[ -z "${image:-}" ]]; then
        image="$1"
        shift
      else
        echo -e "Invalid parameter: ${1}\n" >&2
        vedv::image_command::__pull_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  vedv::image_service::pull "$image"
}

#
# Show help for __pull command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__pull_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image pull IMAGE

Pull an image or a repository from a registry
HELPMSG
}

#
# List images
#
# Flags:
#   [-h | --help | help]        show help
#
# Output:
#   writes container id and name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__list() {

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__list_help
      return 0
      ;;
    *)
      err "Invalid parameter: ${1}\n"
      vedv::image_command::__list_help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done

  vedv::image_service::list
}

#
# Show help for list command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__list_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} docker image ls

List images

Aliases:
  ls, list
HELPMSG
}

#
# Remove one or more images
#
# Flags:
#   [-h | --help | help]     show help
#
# Arguments:
#   IMAGE  [IMAGE...]        one or more image name or id
#
# Output:
#   writes container name or id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__rm() {
  # TODO: change if [[ $# == 0 ]]; then; set -- '-h'; fi
  [[ $# == 0 ]] && set -- '-h'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__rm_help
      return 0
      ;;
    *)
      vedv::image_service::rm "$@"
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
vedv::image_command::__rm_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image rm IMAGE [IMAGE...]

Remove one or more images
HELPMSG
}

#
# Remove unused cache images
#
# Flags:
#   [-h | --help]     show help
#
# Output:
#   writes removed image caches id to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__remove_unused_cache() {

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__remove_unused_cache_help
      return 0
      ;;
    esac
  done

  vedv::image_service::remove_unused_cache
}

#
# Show help for __remove_unused_cache command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__remove_unused_cache_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image remove-cache

Remove unused cache images
HELPMSG
}

#
# Build an image from a Vedvfile
#
# Flags:
#   [-h | --help]       show help
#
# Options:
#   [-n | --name | -t]  image name
#
# Arguments:
#   [VEDV_FILE]              Vedvfile (default is 'Vedvfile')
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__build() {
  local image_name=''
  local vedvfile=''

  while [[ $# -gt 0 ]]; do
    local arg="$1"

    case "$arg" in
    -h | --help)
      vedv::image_command::__build_help
      return 0
      ;;
    -n | --name | -t)
      shift
      image_name="${1:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "Missing argument for option '${arg}'"
        vedv::image_command::__build_help
        return "$ERR_INVAL_ARG"
      fi
      shift
      ;;
    *)
      if [[ -z "$vedvfile" ]]; then
        vedvfile="$1"
        shift
      else
        err "Invalid parameter: ${1}\n"
        vedv::image_command::__build_help
        return "$ERR_INVAL_ARG"
      fi
      ;;
    esac
  done

  vedv::image_service::build "${vedvfile:-Vedvfile}" "$image_name"
}

#
# Show help for __rm command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__build_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image build [OPTIONS] [PATH]

Build an image from a Vedvfile

Options:
  -n, --name, -t   image name
HELPMSG
}

#
# Show help
#
# Options:
#   [-s| --short]   Print short description
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__help() {
  # if [[ "${1:-}" == @(-s|--short) ]]; then
  #   echo "${__VED_IMAGE_COMMAND_SCRIPT_NAME} image        Manage images"
  #   return 0
  # fi
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image COMMAND

Manage images

Commands:
  build            Build an image from a Vedvfile
  pull             Pull an image from a registry or file
  list             List images
  remove           Remove one or more images
  remove-cache     Remove unused cache images

Run '${__VED_IMAGE_COMMAND_SCRIPT_NAME} image COMMAND --help' for more information on a command.
HELPMSG
}

vedv::image_command::run_cmd() {
  # TODO: change if [[ $# == 0 ]]; then; set -- '-h'; fi
  [[ $# == 0 ]] && set -- '-h'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::image_command::__help
      return 0
      ;;
    pull)
      shift
      vedv::image_command::__pull "$@"
      return $?
      ;;
    ls | list)
      shift
      vedv::image_command::__list "$@"
      return $?
      ;;
    rm | remove)
      shift
      vedv::image_command::__rm "$@"
      return $?
      ;;
    rm-cache | remove-cache)
      shift
      vedv::image_command::__remove_unused_cache "$@"
      return $?
      ;;
    build)
      shift
      vedv::image_command::__build "$@"
      return $?
      ;;
    *)
      echo -e "Invalid parameter: ${1}\n" >&2
      vedv::image_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
