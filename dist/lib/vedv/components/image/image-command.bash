#
# Manage images
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
vedv::image_command::constructor() {
  readonly __VED_IMAGE_COMMAND_SCRIPT_NAME="$1"
}

# IMPL: Pull an image or a repository from a registry
vedv::image_command::__pull() {
  echo 'vedv:image:pull_run_cmd'
  vedv::image_service::pull
}

# IMPL: Build an image from a Vedvfile
vedv::image_command::__build() {
  echo 'vedv:image:build_run_cmd'
  vedv::image_service::build
}

vedv::image_command::__help() {
  echo 'vedv::image_command::__help'
}

vedv::image_command::run_cmd() {

  [[ $# == 0 ]] && set -- '-h'

  if [[ "${1:-}" == @(-h|--help) ]]; then
    vedv::image_command::__help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
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
      return 10
      ;;
    esac
  done
}
