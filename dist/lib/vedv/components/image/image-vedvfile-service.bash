#
# Manage Vedvfile
#

# this is only for code completion
if false; then
  . './../../utils.bash'
fi

# Variables:
readonly VEDVFILE_SUPPORTED_COMMANDS='FROM|RUN|COPY'

#
# Constructor
#
# Arguments:
#   config                    string    config file
#   enabled                   bool      Hadolint enabled
#   base_vedvfileignore_path  string    path to the base vedvfileignore
#   vedvfileignore_path       string    path to the .vedvfileignore
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_vedvfile_service::constructor() {
  readonly __VEDV_IMAGE_VEDVFILE_HADOLINT_CONFIG="$1"
  readonly __VEDV_IMAGE_VEDVFILE_HADOLINT_ENABLED="$2"
  readonly __VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH="$3"
  readonly __VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH="$4"
}

__vedvfile-parser() {
  local -r bin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/__bin"
  "${bin_dir}/vedvfile-parser" "$@"
}

#
# Validate commands
#
# Arguments:
#   commands    text with commands (list of commands, splitted by \n)
#
# Output:
#   writes error message on error
#
# Returns:
#   0 on success, 1 otherwise
#
vedv::image_vedvfile_service::__are_supported_commands() {
  local -r commands="$1"

  if [[ -z "$commands" ]]; then
    echo 'There are no commands for validation'
    return 0
  fi

  local -r clean_cmds="$(utils::string::trim "$commands")"

  while IFS= read -r cmd; do
    if ! grep -qP "^($VEDVFILE_SUPPORTED_COMMANDS)\s+" <<<"$cmd"; then
      err "Command '${cmd}' isn't supported, valid commands are: ${VEDVFILE_SUPPORTED_COMMANDS}"
      return 1
    fi
  done <<<"$clean_cmds"

  return 0
}

#
# Validate a Vedvfile
#
# Arguments:
#   vedvfile         Vedvfile full path
#
# Output:
#   writes error message on error
#
# Returns:
#   0 on success, 1 otherwise
#
vedv::image_vedvfile_service::__validate_file() {
  local -r vedvfile="$1"

  if [ ! -f "$vedvfile" ]; then
    err "Invalid argument 'vedvfile', file ${vedvfile} doesn't exist"
    return "$ERR_INVAL_ARG"
  fi

  local -r commands="$(cat "$vedvfile")"

  vedv::image_vedvfile_service::__are_supported_commands "$commands" ||
    return 1

  if [[ "$__VEDV_IMAGE_VEDVFILE_HADOLINT_ENABLED" == true ]] && ! hadolint --config "$__VEDV_IMAGE_VEDVFILE_HADOLINT_CONFIG" "$vedvfile" >/dev/null; then
    err "Hadolint validation fail"
    return 1
  fi

  return 0
}

#
# Build an image from a Vedvfile
#
# Arguments:
#   vedvfile string            Vedvfile full path
#
# Output:
#   writes commands (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_vedvfile_service::get_commands() {
  local -r vedvfile="$1"

  if [ ! -f "$vedvfile" ]; then
    err "Invalid argument 'vedvfile', file ${vedvfile} doesn't exist"
    return "$ERR_INVAL_ARG"
  fi

  local vedvfile_parsed
  vedvfile_parsed="$(__vedvfile-parser "$vedvfile")" || {
    err "Failed to parse Vedvfile: ${vedvfile}"
    return "$ERR_VEDV_FILE"
  }
  local -r vedvfile_parsed_file="$(mktemp)"
  echo "$vedvfile_parsed" >"$vedvfile_parsed_file"

  vedv::image_vedvfile_service::__validate_file "$vedvfile_parsed_file" ||
    return "$ERR_INVAL_ARG"

  nl -w 1 -s'  ' <<<"$vedvfile_parsed"
}

#
# Get the command name
#
# Arguments:
#   cmd     command
#
# Output:
#   writes the command name to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_vedvfile_service::get_cmd_name() {
  local -r cmd="$1"

  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(utils::string::trim "$cmd" | grep -Po "(\d+\s+)?($VEDVFILE_SUPPORTED_COMMANDS)\s+" |
    sed -e 's/^[[:digit:]]*\s*//' -e 's/[[:space:]]*$//')"

  if [[ -z "$cmd_name" ]]; then
    err "There isn't command name in '${cmd}'"
    return "$ERR_INVAL_ARG"
  fi

  echo "$cmd_name"
}

#
# Get the command body
#
# Arguments:
#   cmd text     command
#
# Output:
#   writes the command_body (text) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_vedvfile_service::get_cmd_body() {
  local -r cmd="$1"

  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  echo "$cmd" | sed -e 's/\s*\([[:digit:]]\+\s\+\)\?\(FROM\|RUN\|CMD\|LABEL\|EXPOSE\|ENV\|ADD\|COPY\|ENTRYPOINT\|VOLUME\|USER\|WORKDIR\|ARG\|ONBUILD\|STOPSIGNAL\|HEALTHCHECK\|SHELL\)\s\+//' -e 's/[[:space:]]*$//'
}

#
# Return the file path of joined vedvfileignore
#
# Output:
#  Writes the file path to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv:image_vedvfile_service::get_joined_vedvfileignore() {

  if [[ ! -f "$__VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH" ]]; then
    err "File ${__VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH} does not exist"
    return "$ERR_INVAL_VALUE"
  fi

  local vedvfileignore_path

  if [[ ! -f "$__VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH" ]]; then
    vedvfileignore_path="$__VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH"
  else
    vedvfileignore_path="$(mktemp)" || {
      err "Failed to create temporary file"
      return 1
    }
    cat "$__VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH" \
      "$__VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH" >"$vedvfileignore_path"
  fi

  echo "$vedvfileignore_path"
}

#
# Return the base vedvfileignore path
#
# Output:
#  Writes the file path to stdout
#
vedv:image_vedvfile_service::get_base_vedvfileignore_path() {
  echo "$__VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH"
}

#
# Return the vedvfileignore path
#
# Output:
#  Writes the file path to stdout
#
vedv:image_vedvfile_service::get_vedvfileignore_path() {
  echo "$__VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH"
}
