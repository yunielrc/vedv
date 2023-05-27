#
# Build images
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../ssh-client.bash'
  . './../../hypervisors/virtualbox.bash'
  . './image-service.bash'
  . './image-entity.bash'
  . './image-vedvfile-service.bash'
fi

# CONSTANTS
readonly __VEDV_IMAGE_BUILDER_ENV_VARS_FILE="$(mktemp)"

#
# Constructor
#
# Arguments:
#
# Returns:
#   0 on success, non-zero on error.
#
# vedv::image_builder::constructor() {

# }

#
# Create layer
#
# Arguments:
#   image_id  string    image id
#   cmd text            cmd (e.g. "1 RUN echo hello")
#
# Output:
#  Writes layer_id (string) to stdout
#  Writes error messages to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__create_layer() {
  local -r image_id="$1"
  local -r cmd="$2"

  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: $'
    return "$ERR_INVAL_ARG"
  fi
  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_INVAL_VALUE"
  }
  readonly cmd_name

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name "$image_id")" || {
    err "Failed to get vm name for image with id '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "There is not vm for image with id '${image_id}'"
    return "$ERR_INVAL_VALUE"
  fi

  local layer_id
  layer_id="$(vedv::image_builder::__layer_"${cmd_name,,}"_calc_id "$cmd")" || {
    err "Failed to calculate layer id for cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly layer_id

  if [[ -z "$layer_id" ]]; then
    err "'layer_id' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  local -r full_layer_name="layer:${cmd_name}|id:${layer_id}|"

  vedv::hypervisor::take_snapshot "$image_vm_name" "$full_layer_name" &>/dev/null || {
    err "Failed to create layer '${full_layer_name}' for image '${image_id}', code: $?"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  echo "$layer_id"
  return 0
}

#
# Calculate layer id for a given command
#
# Arguments:
#   cmd string            command (e.g. "1 COPY source/ dest/")
#
# Output:
#  Writes error messages to the stderr
#
# Returns:
#   0 if valid, 1 otherwise
#
vedv::image_builder::__calc_command_layer_id() {
  local -r cmd="$1"
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly cmd_name

  if [[ -z "$cmd_name" ]]; then
    err "'cmd_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local calc_layer_id
  calc_layer_id="$(vedv::image_builder::__layer_"${cmd_name,,}"_calc_id "$cmd")" || {
    err "Failed to calculate layer id for cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly calc_layer_id

  if [[ -z "$calc_layer_id" ]]; then
    err "'calc_layer_id' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  echo "$calc_layer_id"
}

#
# Execute commands on an image layer
#
# THIS IS WHERE THE NEW DATA IS WRITEN ON TO THE IMAGE
# IF THIS FAILS AND THE LAYER RESTORATION FAILS TOO,
# THE IMAGE IS CORRUPTED AND IT MUST BE DELETED.
#
# Arguments:
#   image_id        string   image where the files will be copy
#   cmd             string   copy command (e.g. "1 COPY source/ dest/")
#   caller_command  string   caller command (e.g. "RUN" | "COPY" |...)
#   exec_func       string   function that will be executed to execute the command
#
# Output:
#  Writes layer_id (string) to the stdout
#  Writes error messages to the stderr
#
# Returns:
#   0 on success, non-zero on error
#   in case of error 100, the image is corrupted and it must be deleted
#
vedv::image_builder::__layer_execute_cmd() {
  local -r image_id="$1"
  local -r cmd="$2"
  local -r caller_command="$3"
  local -r exec_func="$4"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: $'
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$caller_command" ]]; then
    err "Argument 'caller_command' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$exec_func" ]]; then
    err "Argument 'exec_func' is required"
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly cmd_name

  if [[ "$cmd_name" != "$caller_command" ]]; then
    err "Invalid command name '${cmd_name}', it must be '${caller_command}'"
    return "$ERR_INVAL_ARG"
  fi

  __restore_last_layer() {
    vedv::image_service::restore_last_layer "$image_id" || {
      err "Failed to restore last layer for image '${image_id}'"
      return "$ERR_IMAGE_BUILDER_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL"
    }
    echo 'Previous layer restored'
  }
  # eval "$exec_func" --> THIS IS WHERE THE NEW DATA IS WRITEN ON TO THE IMAGE
  # IF THIS FAILS AND THE LAYER RESTORATION FAILS TOO, THE IMAGE IS CORRUPTED
  # AND IT MUST BE DELETED.

  eval "$exec_func" || {
    err "Failed to execute command '${cmd}'"
    __restore_last_layer || return $? # OO: exit code 100
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  # create layer
  local layer_id
  layer_id="$(vedv::image_builder::__create_layer "$image_id" "$cmd")" || {
    err "Failed to create layer for image '${image_id}'"
    __restore_last_layer || return $? # OO: exit code 100
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly layer_id

  echo "$layer_id"
  return 0
}

#
# Create an image
#
# Arguments:
#   image string          image name or an OVF file that will be pulled
#   image_name  string    image name (default: OVF file name)
#
# Output:
#  Writes image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_from() {
  local -r image="$1"
  local -r image_name="$2"
  # validate arguments
  if [[ -z "$image" ]]; then
    err "Argument 'image' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$image_name" ]]; then
    err "Argument 'image_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$image" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$image" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi

  local image_id
  image_id="$(vedv::image_service::pull "$image" "$image_name" true)" || {
    err "Failed to pull image '${image}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  local -r cmd="1 FROM ${image}"
  # create layer
  local layer_id
  layer_id="$(vedv::image_builder::__create_layer "$image_id" "$cmd")" || {
    err "Failed to create layer for image '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly layer_id

  if [[ -z "$layer_id" ]]; then
    err "'layer_id' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  echo "$image_id"
}

#
# Calculate crc sum for the from command body
#
# Arguments:
#   cmd_body text     command body
#
# Output:
#  Writes crc_sum (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
# TODO: test this function when its implementation is done
# IMPL: implementation to finish
#
vedv::image_builder::__layer_from_calc_id() {
  local -r cmd="$1"
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly cmd_name

  if [[ "$cmd_name" != "FROM" ]]; then
    err "Invalid command name '${cmd_name}', it must be 'FROM'"
    return "$ERR_INVAL_ARG"
  fi

  local cmd_body
  cmd_body="$(vedv::image_vedvfile_service::get_cmd_body "$cmd")" || {
    err "Failed to get cmd body from cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly cmd_body

  if [[ -z "$cmd_body" ]]; then
    err "Argument 'cmd_body' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -f "$cmd_body" ]]; then
    utils::crc_file_sum "$cmd_body"
  else
    err "Not implemented yet"
    return "$ERR_NOT_IMPLEMENTED"
  fi
  return 0
}

#
# Validate layer from
#
# Arguments:
#   image_id string      image id
#   from_cmd string      from cmd
#
# Returns:
#   0 if valid, 1 otherwise
#
vedv::image_builder::__validate_layer_from() {
  local -r image_id="$1"
  local -r from_cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$from_cmd" ]]; then
    err "Argument 'from_cmd' is required"
    return "$ERR_INVAL_ARG"
  fi

  local from_file_sum
  from_file_sum="$(vedv::image_builder::__layer_from_calc_id "$from_cmd")" || {
    err "Failed to cal id for: '${from_cmd}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly from_file_sum

  if [[ -z "$from_file_sum" ]]; then
    err "from_file_sum' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  local image_file_sum
  image_file_sum="$(vedv::image_entity::get_ova_file_sum "$image_id")" || {
    err "Failed to get ova file sum for image with id '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly image_file_sum

  if [[ -z "$image_file_sum" ]]; then
    err "image_file_sum' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  if [[ "$from_file_sum" != "$image_file_sum" ]]; then
    echo 'invalid'
  else
    echo 'valid'
  fi

  return 0
}

#
# Calculates the layer id for the copy command
#
# Arguments:
#   cmd string           copy command (e.g. "1 COPY source/ dest/")
#
# Output:
#  Writes layer id to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_copy_calc_id() {
  local -r cmd="$1"
  shift
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly cmd_name

  if [[ "$cmd_name" != "COPY" ]]; then
    err "Invalid command name '${cmd_name}', it must be 'COPY'"
    return "$ERR_INVAL_ARG"
  fi

  local crc_sum_cmd
  crc_sum_cmd="$(utils::crc_sum <<<"$cmd")"
  readonly crc_sum_cmd
  # This works like shell on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  # 1 COPY --root 'file space' ./file*
  #
  # also eval do variable substitution
  #
  eval set -- "$cmd"

  if [[ "$#" -lt 4 ]]; then
    err "Invalid number of arguments, expected at least 4, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local src=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    --root)
      shift
      ;;
    # options
    -u | --user)
      shift
      if [[ -n "${1:-}" ]]; then
        shift # user name
      fi
      ;;
    # arguments
    *)
      readonly src="$1"
      break
      ;;
    esac
  done

  local crc_sum_source=''

  if [[ -e "$src" ]]; then
    crc_sum_source="$(utils::crc_file_sum "$src")" || {
      err "Failed getting 'crc_sum_source' for src: '${src}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi
  readonly crc_sum_source

  local -r base_vedvfileignore_path="$(vedv:image_vedvfile_service::get_base_vedvfileignore_path)"
  local -r vedvfileignore_path="$(vedv:image_vedvfile_service::get_vedvfileignore_path)"

  if [[ ! -f "$base_vedvfileignore_path" ]]; then
    err "File ${base_vedvfileignore_path} does not exist"
    return "$ERR_INVAL_VALUE"
  fi

  local crc_sum_base_vedvfileignore
  crc_sum_base_vedvfileignore="$(utils::crc_file_sum "$base_vedvfileignore_path")" || {
    err "Failed to calc 'crc_sum_base_vedvfileignore'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly crc_sum_base_vedvfileignore

  local crc_sum_vedvfileignore=''

  if [[ -f "$vedvfileignore_path" ]]; then
    crc_sum_vedvfileignore="$(utils::crc_file_sum "$vedvfileignore_path")" || {
      err "Failed to calc 'crc_sum_vedvfileignore'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi
  readonly crc_sum_vedvfileignore

  local crc_sum_all
  crc_sum_all="$(utils::crc_sum <<<"${crc_sum_cmd}${crc_sum_source}${crc_sum_base_vedvfileignore}${crc_sum_vedvfileignore}")"
  readonly crc_sum_all

  echo "$crc_sum_all"
}

#
# Copy files to an image layer
#
# Preconditions:
#  The image must be started and running
#
# Arguments:
#   image_id  string       image where the files will be copy
#   cmd       string       copy command (e.g. "1 COPY --root source/ dest/")
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_copy() {
  local -r image_id="$1"
  local -r cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi
  # This works like shell on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  #
  # also eval do variable substitution
  #
  # 1 COPY --root 'file space' ./file*
  eval set -- "$cmd"

  if [[ "$#" -lt 4 ]]; then
    err "Invalid number of arguments, expected at least 4, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local user=''
  local src=''
  local dest=''
  local chown=''
  local chmod=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    # options
    -u | --user)
      readonly user="${2:-}"
      # validate argument
      if [[ -z "$user" ]]; then
        err "Argument 'user' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --chown)
      readonly chown="${2:-}"
      # validate argument
      if [[ -z "$chown" ]]; then
        err "Argument 'chown' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    --chmod)
      readonly chmod="${2:-}"
      # validate argument
      if [[ -z "$chmod" ]]; then
        err "Argument 'chmod' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    # arguments
    *)
      readonly src="$1"
      readonly dest="${2:-}"
      break
      ;;
    esac
  done
  # validate command arguments
  if [[ -z "$src" ]]; then
    err "Argument 'src' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$dest" ]]; then
    err "Argument 'dest' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::copy '${image_id}' '${src}' '${dest}' '${user}' '${chown}' '${chmod}'"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "COPY" "$exec_func"
}

#
# Calculates the layer id for simple commands
#
# Arguments:
#   cmd           string  command (e.g. "1 COPY source/ dest/")
#   command_name  string  command name (e.g. "COPY")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__simple_layer_command_calc_id() {
  local -r cmd="$1"
  local -r command_name="$2"
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$command_name" ]]; then
    err "Argument 'command_name' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: $'
    return "$ERR_INVAL_ARG"
  fi

  local cmd_name
  cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get command name from command '$cmd'"
    return "$ERR_INVAL_ARG"
  }
  readonly cmd_name

  if [[ "$cmd_name" != "$command_name" ]]; then
    err "Invalid command name '${cmd_name}', it must be '${command_name}'"
    return "$ERR_INVAL_ARG"
  fi

  utils::crc_sum <<<"$cmd"
}

#
# Calculates the layer id for the run command
#
# Arguments:
#   cmd string       run command (e.g. "1 COPY source/ dest/")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_run_calc_id() {
  local -r cmd="$1"
  vedv::image_builder::__simple_layer_command_calc_id "$cmd" "RUN"
}

#
# Expand command parameters
#
# Arguments:
#   cmd string  command (e.g. "1 RUN echo hello")
#
# Output:
#  Writes evaluated_cmd (text) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__expand_cmd_parameters() {
  local -r cmd="$1"
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi

  local escaped_cmd
  escaped_cmd="$(utils::str_escape_double_quotes "$cmd")" || {
    err "Failed to escape command '${cmd}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly escaped_cmd

  . "$__VEDV_IMAGE_BUILDER_ENV_VARS_FILE"

  local evaluated_cmd
  evaluated_cmd="$(eval "echo \"${escaped_cmd}\"")" || {
    err "Failed to evaluate command '${cmd}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  echo "$evaluated_cmd"
}

#
# Run commands inside the image
#
# Preconditions:
#  The image must be started and running
#
# Arguments:
#   image_id  string  image where the files will be copy
#   cmd       string  run command (e.g. "1 RUN echo hello")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_run() {
  local -r image_id="$1"
  local -r cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: $'
    return "$ERR_INVAL_ARG"
  fi
  # In this case we need to keep the quotes, so by this way we split
  # the command by spaces including those inside quotes, but the quotes
  # are not removed.
  local -a cmd_arr
  IFS=' ' read -r -a cmd_arr <<<"$cmd"
  # ...:2 skip the command id and name
  # 1 RUN --root ls -la -> --root ls -la
  set -- "${cmd_arr[@]:2}" # by this way it keeps quotes (" and ')
  local user=''
  local exec_cmd=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # flags
    --root)
      shift
      set -- '-u' 'root' "$@"
      ;;
    # options
    -u | --user)
      shift
      user="$(str_rm_quotes "$1")"
      readonly user
      # validate argument
      if [[ -z "$user" ]]; then
        err "Argument 'user' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift
      ;;
    # arguments
    *)
      # ls -la
      readonly exec_cmd="$*"
      break
      ;;
    esac
  done
  # validate command arguments
  if [[ -z "$exec_cmd" ]]; then
    err "Argument 'cmd_body' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  # replacing quotes (" and ') allow passing the command as a string (single argument)
  # avoiding the shell to split it on every evaluation (with eval)
  local exec_cmd_encoded
  exec_cmd_encoded="$(utils::str_encode "$exec_cmd")" || {
    err "Failed to encode command '${exec_cmd}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly exec_cmd_encoded

  local -r exec_func="vedv::image_service::execute_cmd '${image_id}' '${exec_cmd_encoded}' '${user}'"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "RUN" "$exec_func"
}

#
# Calculates the layer id for the user command
#
# Arguments:
#   cmd string       user command (e.g. "1 USER nalyd")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_user_calc_id() {
  local -r cmd="$1"
  vedv::image_builder::__simple_layer_command_calc_id "$cmd" "USER"
}

#
# Creates and set the default user for the image
#
# Arguments:
#   image_id  string       image where the user will be set
#   cmd string             user command (e.g. "1 USER nalyd")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_user() {
  local -r image_id="$1"
  local -r cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi
  # This works like shell on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  # cmd: "1 USER nalyd"
  #
  # also eval do variable substitution
  #
  eval set -- "$cmd"

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r user_name="${1:-}"

  if [[ -z "$user_name" ]]; then
    err "Argument 'user_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::set_user '${image_id}' '${user_name}'"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "USER" "$exec_func"
}

#
# Calculates the layer id for the shell command
#
# Arguments:
#   cmd string    shell command (e.g. "1 SHELL bash")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_shell_calc_id() {
  local -r cmd="$1"
  vedv::image_builder::__simple_layer_command_calc_id "$cmd" "SHELL"
}

#
# Set the shell for all users in the image
#
# Arguments:
#   image_id  string       image where the shell will be set
#   cmd string             shell command (e.g. "1 SHELL nalyd")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_shell() {
  local -r image_id="$1"
  local -r cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi
  # This works like shell on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  # cmd: "1 SHELL bash"
  #
  # also eval do variable substitution
  #
  eval set -- "$cmd"

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r shell="${1:-}"

  if [[ -z "$shell" ]]; then
    err "Argument 'shell' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::set_shell '${image_id}' '${shell}'"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "SHELL" "$exec_func"
}

#
# Calculates the layer id for the workdir command
#
# Arguments:
#   cmd string  workdir command (e.g. "1 workdir nalyd")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_workdir_calc_id() {
  local -r cmd="$1"
  vedv::image_builder::__simple_layer_command_calc_id "$cmd" "WORKDIR"
}

#
# Creates and set the default workdir for the image
#
# Preconditions:
#  The image must be started and running
#
# Arguments:
#   image_id  string  image where the workdir will be set
#   cmd       string  workdir command (e.g. "1 workdir nalyd")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_workdir() {
  local -r image_id="$1"
  local -r cmd="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi
  # This works like shell on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  # cmd: "1 WORDIR /home/nalyd"
  #
  # also eval do variable substitution
  #
  eval set -- "$cmd"

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r workdir="${1:-}"

  if [[ -z "$workdir" ]]; then
    err "Argument 'workdir' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::set_workdir '${image_id}' '${workdir}' >/dev/null"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "WORKDIR" "$exec_func"
}

#
# Calculates the layer id for the env command
#
# Arguments:
#   cmd string  env command (e.g. "1 ENV NAME=nalyd")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::image_builder::__layer_env_calc_id() {
  local -r cmd="$1"
  vedv::image_builder::__simple_layer_command_calc_id "$cmd" "ENV"
}

#
# Creates and set the default env for the image
#
# Preconditions:
#  The image must be started and running
#
# Arguments:
#   image_id  string  image where the env will be set
#   cmd       string  env command (e.g. "1 ENV NAME=nalyd")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__layer_env() {
  local -r image_id="$1"
  local -r cmd="$2"

  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  # do not allow escaped $ or $ in the command
  if [[ "$cmd" == *"$UTILS_ENCODED_ESCVAR_PREFIX"* || "$cmd" == *"$UTILS_ENCODED_VAR_PREFIX"* ]]; then
    err 'Invalid command, it must not contain: \$ or $'
    return "$ERR_INVAL_ARG"
  fi

  local env
  env="$(vedv::image_vedvfile_service::get_cmd_body "$cmd")" || {
    err "Failed to get env from command '${cmd}'"
    return "$ERR_INVAL_ARG"
  }
  readonly env

  if [[ -z "$env" ]]; then
    err "Argument 'env' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  # export environment variable with the prefix 'vedv_'
  # to avoid conflicts with other environment variables
  echo "local -r ${UTILS_ENCODED_VAR_PREFIX}${env}" >>"$__VEDV_IMAGE_BUILDER_ENV_VARS_FILE"

  local -r env_escaped="$(utils::str_escape_quotes "$env")"

  local env_encoded
  env_encoded="$(utils::str_encode "$env_escaped")" || {
    err "Failed to encode command '${env_escaped}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly env_encoded

  local -r exec_func="vedv::image_service::add_environment_var '${image_id}' '${env_encoded}'"

  vedv::image_builder::__layer_execute_cmd "$image_id" "$cmd" "ENV" "$exec_func"
}

#
# Delete invalid layers
#
# Arguments:
#   image_id                string  image where the files will be copy
#   cmds                    text    text with commands (e.g. "1 FROM hello-world")
#
# Output:
#  Writes first_invalid_cmd_pos (int) to the stdout,
#  or -1 if all commands are valid
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__delete_invalid_layers() {
  local -r image_id="$1"
  local -r cmds="$2"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmds" ]]; then
    err "Argument 'cmds' is required"
    return "$ERR_INVAL_ARG"
  fi
  # remove all child containers, to leave only the layers
  vedv::image_service::child_containers_remove_all "$image_id" || {
    err "Failed to remove child containers for image '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  local -a layers_ids
  # shellcheck disable=SC2207
  layers_ids=($(vedv::image_entity::get_layers_ids "$image_id")) || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly layers_ids

  local -a arr_cmds
  readarray -t arr_cmds <<<"$cmds"
  # shellcheck disable=SC2034
  readonly arr_cmds

  # The function ...::__expand_cmd_parameters() needs
  # the environment variables to be in the file
  # __VEDV_IMAGE_BUILDER_ENV_VARS_FILE to work properly.
  vedv::image_builder::__save_environment_vars_to_local_file "$image_id" || {
    err "Failed to save environment variables for image '${image_id}' on the local file"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  __calc_item_id_from_arr_cmds() {
    # shellcheck disable=SC2317
    local -r cmd="$1"
    # shellcheck disable=SC2317
    local evaluated_cmd
    # shellcheck disable=SC2317
    evaluated_cmd="$(vedv::image_builder::__expand_cmd_parameters "$cmd")" || {
      err "Failed to evaluate command '${cmd}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    # shellcheck disable=SC2317
    vedv::image_builder::__calc_command_layer_id "$evaluated_cmd"
  }
  # shellcheck disable=SC2317
  __calc_item_id_from_arr_layer_ids() { echo "$1"; }

  local first_invalid_positions
  first_invalid_positions="$(utils::get_first_invalid_positions_between_two_arrays arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids)" || {
    err "Failed to get first invalid positions between two arrays"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly first_invalid_positions

  local -i first_invalid_cmd_pos first_invalid_layer_pos
  IFS='|' read -r \
    first_invalid_cmd_pos \
    first_invalid_layer_pos \
    <<<"$first_invalid_positions"
  readonly first_invalid_cmd_pos first_invalid_layer_pos

  if [[ "$first_invalid_cmd_pos" -eq 0 ]]; then
    err "The first command must be valid because it's the command 'FROM'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  fi

  local last_valid_layer_id=''

  if [[ "$first_invalid_layer_pos" -ne -1 ]]; then

    local -r layers_length="${#layers_ids[@]}"
    # delete invalid layers
    for ((i = first_invalid_layer_pos; i < layers_length; i++)); do
      local layer_id="${layers_ids[$i]}"
      vedv::image_service::delete_layer "$image_id" "$layer_id" || {
        err "Failed to delete layer '${layer_id}' for image '${image_id}'"
        return "$ERR_IMAGE_BUILDER_OPERATION"
      }
    done

    local -r last_valid_layer_id="${layers_ids[$((first_invalid_layer_pos - 1))]}"

    vedv::image_service::restore_layer "$image_id" "$last_valid_layer_id" || {
      err "Failed to restore last valid layer '${last_valid_layer_id}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi

  echo "$first_invalid_cmd_pos"
  return 0
}

vedv::image_builder::__save_environment_vars_to_local_file() {
  local -r image_id="$1"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  # create a new temporary file to store the environment variables for the substitution
  local env_vars
  env_vars="$(vedv::image_service::get_environment_vars "$image_id")" || {
    err "Failed to get environment variables for image '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  # add 'local -r' prefix to each environment variable in env_vars text
  env_vars="$(sed -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//' -e "s/^/local -r ${UTILS_ENCODED_VAR_PREFIX}/" <<<"$env_vars")"
  readonly env_vars

  echo "$env_vars" >"$__VEDV_IMAGE_BUILDER_ENV_VARS_FILE"
}

#
# Build image from Vedvfile
#
# On build failure the image is corrupted and deleted if:
# 1 - The first layer creation fails. The FROM command
# 2 - A layer deletion fails
# 3 - A layer creation fails and the previous layer restoration fails too.
#
# An image is valid and it will not be deleted if:
# 1 - Every data is writed without errors and there is a layer for that data.
#
# Arguments:
#   vedvfile  string       path to Vedvfile
#   image_name  string     name of the image
#
# Output:
#  Writes image_id (string) image_name (string) and build proccess #  output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::__build() {
  local -r vedvfile="$1"
  local image_name="${2:-}"
  # validate arguments
  if [[ -z "$vedvfile" ]]; then
    err "Argument 'vedvfile' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -f "$vedvfile" ]]; then
    err "File '${vedvfile}' does not exist"
    return "$ERR_NOT_FOUND"
  fi
  if [[ -z "$image_name" ]]; then
    image_name="$(petname)" || {
      err 'Failed to generate a random name for the image'
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi
  readonly image_name

  local commands
  commands="$(vedv::image_vedvfile_service::get_commands "$vedvfile")" || {
    err "Failed to get commands from Vedvfile '${vedvfile}'"
    return "$ERR_VEDV_FILE"
  }
  # prepare commands for env and arg variable substitution. e.g.
  # VAR_PREFIX_ can be any random string characters like '01b9622e23'
  # VAR_ENCODED_ can be any random string characters like '8027d5b963'
  #
  # 2 RUN echo $NAME -> 1 RUN echo $VAR_PREFIX_NAME
  # 3 COPY . \$HOME -> 1 COPY . VAR_ENCODED_HOME
  commands="$(utils::str_encode_vars "$commands")" || {
    err "Failed to prepare commands from Vedvfile '${vedvfile}'"
    return "$ERR_VEDV_FILE"
  }
  readonly commands

  local -r from_cmd="$(echo "$commands" | head -n 1)"

  local image_id
  image_id="$(vedv::image_entity::get_id_by_image_name "$image_name")" || {
    if [[ $? != "$ERR_NOT_FOUND" ]]; then
      err "Failed to get image id for image '${image_name}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    fi
  }

  __delete_corrupted_image() {

    err "The image '${image_name}' is corrupted and its going to be deleted."

    vedv::image_service::remove 'true' "$image_name" >/dev/null || {
      err "Failed to remove the image '${image_name}'.\nIt must be deleted manually."
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    err "The image '${image_name}' was removed."
  }
  # `image_id` should be empty when there is no image with that name
  #  in that case it's no necessary to validate the from layer

  # otherwise, if there is an image with that name, it's necessary to validate
  __call__layer_from() {
    local from_body
    from_body="$(vedv::image_vedvfile_service::get_cmd_body "$from_cmd")" || {
      err "Failed to get from body from Vedvfile '${vedvfile}'"
      return "$ERR_VEDV_FILE"
    }
    image_id="$(vedv::image_builder::__layer_from "$from_body" "$image_name")" || {
      err "Failed to create the layer for command '${from_cmd}'"
      # 1 - The first layer creation fails. The FROM command
      __delete_corrupted_image
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }

    local -a arr_layer_ids
    # shellcheck disable=SC2207
    arr_layer_ids=($(vedv::image_entity::get_layers_ids "$image_id")) || {
      err "Failed to get layers ids for image '${image_name}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    echo "created layer '${arr_layer_ids[0]}' for command 'FROM'"
  }

  if [[ -n "$image_id" ]]; then

    local from_val_res
    from_val_res="$(vedv::image_builder::__validate_layer_from "$image_id" "$from_cmd")" || {
      err "Failed to validate layer from for image '${image_name}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    readonly from_val_res

    if [[ "$from_val_res" == 'invalid' ]]; then
      vedv::image_service::remove 'true' "$image_id" >/dev/null || {
        err "Failed to remove image '${image_name}'"
        return "$ERR_IMAGE_BUILDER_OPERATION"
      }
      __call__layer_from || return
    else
      # if there is an image with valid layer FROM, restoring the
      # last layer will get rid of any data created on an erroneous previous build
      vedv::image_service::restore_last_layer "$image_id" || {
        err "Failed to restore layer last layer for image '${image_id}'"
        __delete_corrupted_image || return $?
      }
    fi
  else
    __call__layer_from || return
  fi

  readonly image_id

  __print_build_success_msg() {
    echo
    echo 'Build finished'
    echo "${image_id} ${image_name}"
  }
  # first_invalid_layer_pos` is the command position where the build start,
  # all previous commands of this position are ignored because their layers are valid
  local -i first_invalid_cmd_pos
  first_invalid_cmd_pos="$(vedv::image_builder::__delete_invalid_layers "$image_id" "$commands")" || {
    err "Failed deleting invalid layers for image '${image_name}'"
    # 2 - A layer deletion fails
    __delete_corrupted_image
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  readonly first_invalid_cmd_pos

  local -ri commands_length="$(echo "$commands" | wc -l)"

  if [[ $first_invalid_cmd_pos -lt -1 || $first_invalid_cmd_pos -ge $commands_length ]]; then
    err "Invalid first invalid layer position '${first_invalid_cmd_pos}'"
    return "$ERR_INVAL_VALUE"
  fi
  if [[ "$first_invalid_cmd_pos" -eq 0 ]]; then
    err "The first command must be valid because it's the command 'FROM'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  fi
  if [[ $first_invalid_cmd_pos -eq -1 ]]; then
    __print_build_success_msg
    return 0
  fi
  # iterate over cmds_to_run and build the image

  # it get rid of commands with valid layers
  local -r cmds_to_run="$(echo "$commands" | tail -n +"$((first_invalid_cmd_pos + 1))")"

  if [[ -z "$cmds_to_run" ]]; then
    err "There is no command to run"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  fi

  vedv::image_service::start "$image_id" >/dev/null || {
    err "Failed to start image '${image_name}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  # The function ...::__expand_cmd_parameters() needs
  # the environment variables to be in the file
  # __VEDV_IMAGE_BUILDER_ENV_VARS_FILE to work properly.

  # if any layer was deleted, we need to load only the
  # environment variables for the current layers.
  vedv::image_builder::__save_environment_vars_to_local_file "$image_id" || {
    err "Failed to save environment variables for image '${image_id}'"
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }

  while IFS= read -r cmd; do
    local layer_id cmd_name evaluated_cmd
    cmd_name="$(vedv::image_vedvfile_service::get_cmd_name "$cmd")" || {
      err "Failed to get command name from command '${cmd}'"
      return "$ERR_VEDV_FILE"
    }

    evaluated_cmd="$(vedv::image_builder::__expand_cmd_parameters "$cmd")" || {
      err "Failed to evaluate command '${cmd}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }

    layer_id="$(vedv::image_builder::__layer_"${cmd_name,,}" "$image_id" "$evaluated_cmd")" || {
      local -ri ecode=$?
      err "Failed to create layer for command '${evaluated_cmd}'"

      if [[ $ecode -eq "$ERR_IMAGE_BUILDER_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL" ]]; then
        err "The previous layer to the failure could not be restored."
        # 3 - A layer creation fails and the previous layer restoration fails too.
        __delete_corrupted_image
        return $ecode
      fi
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }

    echo "created layer '${layer_id}' for command '${cmd_name}'"
  done <<<"$cmds_to_run"

  vedv::image_service::stop "$image_id" >/dev/null || {
    err "Failed to stop the image '${image_name}'.You must stop it."
    return "$ERR_IMAGE_BUILDER_OPERATION"
  }
  __print_build_success_msg
}

#
# Build image from Vedvfile
#
# __build function wrapper
#
# Arguments:
#   vedvfile      string  path to Vedvfile
#   [image_name]  string  name of the image
#   [force]       bool    force the build removing the image containers
#   [no_cache]    bool    do not use cache when building the image
#
# Output:
#  Writes image_id (string) image_name (string) and build proccess #  output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::image_builder::build() {
  local -r vedvfile="$1"
  local image_name="${2:-}"
  local -r force="${3:-false}"
  local -r no_cache="${4:-false}"
  # validate arguments
  if [[ -z "$vedvfile" ]]; then
    err "Argument 'vedvfile' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -f "$vedvfile" ]]; then
    err "File '${vedvfile}' does not exist"
    return "$ERR_NOT_FOUND"
  fi

  local image_id=''

  ___set_image_id_64695() {
    if [[ -n "$image_name" ]]; then
      image_id="$(vedv::image_entity::get_id_by_image_name "$image_name")" 2>/dev/null || {
        if [[ $? != "$ERR_NOT_FOUND" ]]; then
          err "Failed to get image id for image '${image_name}'"
          return "$ERR_IMAGE_BUILDER_OPERATION"
        fi
      }
    fi
    # readonly image_id
  }
  ___set_image_id_64695 || return $?
  # if the image has containers the force flag must be used to
  # run the build removing the containers, otherwise it will fail
  if [[ "$force" == false && -n "$image_id" ]]; then
    local has_containers
    has_containers="$(vedv::image_entity::has_containers "$image_id")" || {
      err "Failed to check if image '${image_name}' has containers"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    readonly has_containers

    if [[ "$has_containers" == true ]]; then
      err "The image '${image_name}' has containers, you need to force the build, the containers will be removed."
      return "$ERR_IMAGE_BUILDER_OPERATION"
    fi
  fi

  if [[ "$no_cache" == true && -n "$image_id" ]]; then
    vedv::image_service::remove 'true' "$image_id" >/dev/null || {
      err "Failed to remove image '${image_name}'"
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
    image_id=''
  fi

  if [[ -z "$image_name" ]]; then
    image_name="$(petname)" || {
      err 'Failed to generate a random name for the image'
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi

  vedv::image_builder::__build "$vedvfile" "$image_name" || {
    err "The build proccess has failed."
  }

  if [[ -z "$image_id" ]]; then
    ___set_image_id_64695 || return $?
  fi

  if [[ -n "$image_id" ]]; then
    vedv::image_service::stop "$image_id" >/dev/null || {
      err "Failed to stop the image '${image_name}'.You must stop it."
      return "$ERR_IMAGE_BUILDER_OPERATION"
    }
  fi

  return 0
}
