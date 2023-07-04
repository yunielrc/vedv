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
# Import an image from a file
#
# Flags:
#   -h, --help                  show help
#   --check                     the checksum is readed from a file with the same name
#                               as the image file and the extension .sha256sum.
#
# Options:
#   -n, --name  <name>  string  image name
#   --check-file <file> string  read the checksum from the FILE and check it using
#                               sha256sum algorithm.
#
# Arguments:
#   IMAGE_FILE    string  image file
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__import() {
  local image_file=''
  local image_name=''
  local check=false
  local checksum_file=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__import_help
      return 0
      ;;
    -n | --name)
      readonly image_name="${2:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "No image name specified\n"
        vedv::image_command::__import_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --check)
      readonly check=true
      shift
      ;;
    --check-file)
      readonly checksum_file="${2:-}"
      # validate argument
      if [[ -z "$checksum_file" ]]; then
        err "No checksum file specified\n"
        vedv::image_command::__import_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    *)
      readonly image_file="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image_file" ]]; then
    err "Missing argument 'IMAGE_FILE'\n"
    vedv::image_command::__import_help
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$check" == true && -z "$checksum_file" ]]; then
    checksum_file="${image_file}.sha256sum"
  fi

  vedv::image_service::import \
    "$image_file" \
    "$image_name" \
    "$checksum_file"
}

#
# Show help for __import command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__import_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image import IMAGE_FILE

Import an image from a file

Aliases:
  import, from-file

Flags:
  -h, --help            show help
  --check               the checksum is readed from a file with the same name
                        as the image file and the extension .sha256sum.

Options:
  -n, --name <name>     image name
  --check-file <file>   read the checksum from the FILE and check it using
                        sha256sum algorithm.
HELPMSG
}

#
# Import an image from a url
#
# Flags:
#   -h, --help          show help
#   --check             the checksum is downloaded from the same url as the image
#                       suffixed with .sha256sum
#   --no-cache          do not use cache when downloading the image
#
# Options:
#   -n, --name <name>   image name
#   --checksum-url <url>   download the checksum from the URL and check it using
#                       sha256sum algorithm.
#
#
# Arguments:
#   IMAGE_URL         string  image url
#
# Output:
#  Writes image name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__import_from_url() {
  local image_url=''
  local image_name=''
  local check=false
  local checksum_url=''
  local no_cache=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    -h | --help)
      vedv::image_command::__import_from_url_help
      return 0
      ;;
    -n | --name)
      readonly image_name="${2:-}"
      # validate argument
      if [[ -z "$image_name" ]]; then
        err "No image name specified\n"
        vedv::image_command::__import_from_url_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --check)
      readonly check=true
      shift
      ;;
    --no-cache)
      readonly no_cache=true
      shift
      ;;
    # options
    --checksum-url)
      readonly checksum_url="${2:-}"
      # validate argument
      if [[ -z "$checksum_url" ]]; then
        err "No checksum url specified\n"
        vedv::image_command::__import_help
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly image_url="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image_url" ]]; then
    err "Missing argument 'IMAGE_URL'\n"
    vedv::image_command::__import_from_url_help
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$check" == true && -z "$checksum_url" ]]; then
    checksum_url="${image_url}.sha256sum"
  fi

  vedv::image_service::import_from_url \
    "$image_url" \
    "$image_name" \
    "$checksum_url" \
    "$no_cache"
}

#
# Show help for __pull command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__import_from_url_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image from-url URL

Import an image from a url

Flags:
  -h, --help            show help
  --check               the checksum is downloaded from the same url as the image
                        suffixed with .sha256sum
  --no-cache            do not use cache when downloading the image

Options:
  -n, --name <name>     image name
  --checksum-url <url>  download the checksum from the URL and check it using
                        sha256sum algorithm.
HELPMSG
}

#
# Pull an image from a registry or file
#
# Flags:
#   [-h | --help]  Show help
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
  local image=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__pull_help
      return 0
      ;;
    *)
      if [[ -z "$image" ]]; then
        image="$1"
        shift
      else
        err "Invalid argument: ${1}\n"
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
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image pull IMAGE_FILE

Pull an image from a file
HELPMSG
}

#
# List images
#
# Flags:
#   [-h | --help]        show help
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
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image ls

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
  local image_names_or_ids=''
  local force=false

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__rm_help
      return 0
      ;;
    --force)
      readonly force=true
      shift
      ;;
    *)
      readonly image_names_or_ids="$*"
      break
      ;;
    esac
  done

  if [[ -z "$image_names_or_ids" ]]; then
    err "Missing argument 'IMAGE'\n"
    vedv::image_command::__rm_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::image_service::remove "$image_names_or_ids" "$force"
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
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image rm [FLAGS] IMAGE [IMAGE...]

Remove one or more images

Aliases:
  rm, remove

Flags:
  -h, --help    show help
  --force       force remove
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
vedv::image_command::__build() {
  local vedvfile='Vedvfile'
  local image_name=''
  local force=false
  local no_cache=false
  local no_wait_after_build=''

  while [[ $# -gt 0 ]]; do

    case "$1" in
    # Flags
    -h | --help)
      vedv::image_command::__build_help
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
        vedv::image_command::__build_help
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
    vedv::image_command::__build_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::image_service::build \
    "$vedvfile" \
    "$image_name" \
    "$force" \
    "$no_cache" \
    "$no_wait_after_build"
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
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image build [FLAGS] [OPTIONS] VEDVFILE

Build an image from a Vedvfile

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
# List exposed ports
#
# Flags:
#   [-h | --help]		show help
#
# Arguments:
#   IMAGE			image name or id
#
# Output:
#   writes port mappings (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_command::__list_exposed_ports() {
  local image_name_or_id=''

  if [[ $# == 0 ]]; then set -- '-h'; fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      vedv::image_command::__list_exposed_ports_help
      return 0
      ;;
    *)
      readonly image_name_or_id="$1"
      break
      ;;
    esac
  done

  if [[ -z "$image_name_or_id" ]]; then
    err "Missing argument 'IMAGE'\n"
    vedv::image_command::__list_exposed_ports_help
    return "$ERR_INVAL_ARG"
  fi

  vedv::image_service::cache::list_exposed_ports "$image_name_or_id"
}

#
# Show help for __list_exposed_ports command
#
# Output:
#  Writes the help to the stdout
#
vedv::image_command::__list_exposed_ports_help() {
  cat <<-HELPMSG
Usage:
${__VED_IMAGE_COMMAND_SCRIPT_NAME} image list-exposed-ports IMAGE

List exposed ports for the image

Aliases:
  eports, list-exposed-ports

Flags:
  -h, --help    show help
HELPMSG
}

#
# Show help
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

Flags:
  -h, --help      show this help

Commands:
  import          import an image from a file
  from-url        import an image from a url
  build           build an image from a Vedvfile
  pull            pull an image from a registry or file
  list            list images
  remove          remove one or more images
  remove-cache    remove unused cache images
  eports          list exposed ports for the image

Run '${__VED_IMAGE_COMMAND_SCRIPT_NAME} image COMMAND --help' for more information on a command.
HELPMSG
}

vedv::image_command::run_cmd() {
  if [[ $# == 0 ]]; then set -- '-h'; fi

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
    eports | list-exposed-ports)
      shift
      vedv::image_command::__list_exposed_ports "$@"
      return $?
      ;;
    import | from-file)
      shift
      vedv::image_command::__import "$@"
      return $?
      ;;
    from-url)
      shift
      vedv::image_command::__import_from_url "$@"
      return $?
      ;;
    *)
      err "Invalid parameter: ${1}\n"
      vedv::image_command::__help
      return "$ERR_INVAL_ARG"
      ;;
    esac
  done
}
