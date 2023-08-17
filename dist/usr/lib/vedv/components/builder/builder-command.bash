#
# Build an image
#
# Process command line and call service
#

# this is only for code completion
if false; then
  . './builder-service.bash'
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
vedv::builder_command::constructor() {
  readonly __VED_BUILDER_COMMAND_SCRIPT_NAME="$1"
}

#
# Show help for __rm command
#
# Output:
#  Writes the help to the stdout
#
vedv::builder_command::__build_help() {
  cat <<-HELPMSG
Usage:
${__VED_BUILDER_COMMAND_SCRIPT_NAME} builder build [FLAGS] [OPTIONS] VEDVFILE

Build an image from a Vedvfile

Aliases:
  ${__VED_BUILDER_COMMAND_SCRIPT_NAME} image build

Flags:
  -h, --help    show the help
  --force       force the build removing the image containers
  --no-cache    do not use cache when building the image
  --no-wait     it will not wait for the image to save data cache
                and stopping.

Options:
  -n, --name <name>   image name
HELPMSG
}

#
# Build an image from a Vedvfile
#
# Flags:
# -h, --help                  show the help
# --force                     force the build removing the image containers
# --no-cache                  do not use cache when building the image
# --no-wait                   it will not wait for the image to save data cache
#                             and stopping.
#
# Options:
#  -n, --name <name>  string  image name
#
# Arguments:
#   [VEDV_FILE]               Vedvfile (default is 'Vedvfile')
#
# Output:
#   writes process result
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_command::__build() {
  local vedvfile='Vedvfile'
  local image_name=''
  local force=false
  local no_cache=false
  local no_wait_after_build=''

  while [[ $# -gt 0 ]]; do

    case "$1" in
    # Flags
    -h | --help)
      vedv::builder_command::__build_help
      return 0
      ;;
    --force)
      readonly force=true
      shift
      ;;
    --no-cache)
      readonly no_cache=true
      shift
      ;;
    --no-wait)
      readonly no_wait_after_build=true
      shift
      ;;
    # Options
    -n | --name | -t)
      image_name="${2:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "No image name specified\n"
        vedv::builder_command::__build_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # Arguments
    *)
      readonly vedvfile="${1:-}"
      break
      ;;
    esac
  done

  if [[ -z "$vedvfile" ]]; then
    err "Missing argument 'VEDVFILE'\n"
    vedv::builder_command::__build_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::builder_service::build \
    "$vedvfile" \
    "$image_name" \
    "$force" \
    "$no_cache" \
    "$no_wait_after_build"
}

#
# Show help
#
# Output:
#  Writes the help to the stdout
#
vedv::builder_command::__help() {
  # if [[ "${1:-}" == @(-s|--short) ]]; then
  #   echo "${__VED_BUILDER_COMMAND_SCRIPT_NAME} image        Manage images"
  #   return 0
  # fi
  cat <<-HELPMSG
Usage:
${__VED_BUILDER_COMMAND_SCRIPT_NAME} builder COMMAND

Build an image

Flags:
  -h, --help      show this help

Commands:
  build           build an image from a Vedvfile

Run '${__VED_BUILDER_COMMAND_SCRIPT_NAME} builder COMMAND --help' for more information on a command.
HELPMSG
}

vedv::builder_command::run_cmd() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help | help)
      vedv::builder_command::__help
      return 0
      ;;
    build)
      shift
      vedv::builder_command::__build "$@"
      return $?
      ;;
    *)
      err "Invalid parameter: ${1}\n"
      vedv::builder_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
