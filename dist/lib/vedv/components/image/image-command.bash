#
# Manage images
#
# Process command line and call service
#

# REQUIRE
# . '../../utils.bash'
# . '../image/image-service.bash'

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

  [[ $# == 0 ]] && set -- '-h'

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
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

# IMPL: Build an image from a Vedvfile
vedv::image_command::__build() {
  echo 'vedv:image:build_run_cmd'
  vedv::image_service::build
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
  #   echo "${__VED_CONTAINER_COMMAND_SCRIPT_NAME} image        Manage images"
  #   return 0
  # fi
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image COMMAND

Manage images

Commands:
  pull           Pull an image from a registry or file

Run '${__VED_IMAGE_COMMAND_SCRIPT_NAME} image COMMAND --help' for more information on a command.
HELPMSG
}

vedv::image_command::run_cmd() {

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
