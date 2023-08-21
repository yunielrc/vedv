#
# Build the image
#
# It takes a vedvfile and creates an image from it.
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './../../ssh-client.bash'
  . './../../hypervisors/virtualbox.bash'
  . '../image/image-service.bash'
  . '../image/image-entity.bash'
  . './builder-vedvfile-service.bash'
fi

# CONSTANTS

# Constructor
#
# Arguments:
#  memory_cache_dir     string  memory cache dir
#  no_wait_after_build  bool    if true, it will not wait for the
#                                                    image to save data cache and stopping
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::constructor() {
  __VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR="$1"
  readonly __VEDV_BUILDER_SERVICE_NO_WAIT_AFTER_BUILD="${2:-false}"

  # validate arguments
  if [[ -z "$__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR" ]]; then
    err "Argument 'memory_cache_dir' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -d "$__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR" ]]; then
    err "Argument 'memory_cache_dir' must be a directory"
    return "$ERR_INVAL_ARG"
  fi

  readonly __VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR="${__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR%/}/builder_service"

  if [[ ! -d "$__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR" ]]; then
    mkdir "$__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR" || {
      err "Failed to create memory cache dir"
      return "$ERR_FAILED_CREATE_DIR"
    }
  fi
  # a file is used because the variable is modified in a subshell
  # shellcheck disable=SC2119
  readonly __VEDV_BUILDER_SERVICE_ENV_VARS_FILE="${__VEDV_BUILDER_SERVICE_MEMORY_CACHE_DIR}/env_vars_$(utils::random_string)"
  : >"$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}

vedv::builder_service::__get_env_vars() {
  cat "$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}

vedv::builder_service::__get_env_vars_file() {
  echo "$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}

vedv::builder_service::__add_env_vars() {
  local -r env_vars="$1"
  echo "$env_vars" >>"$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}
vedv::builder_service::__set_env_vars() {
  local -r env_vars="$1"
  echo "$env_vars" >"$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}

vedv::builder_service::on_exit() {
  rm -f "$__VEDV_BUILDER_SERVICE_ENV_VARS_FILE"
}

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
vedv::builder_service::__create_layer() {
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
  cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_INVAL_VALUE"
  }
  readonly cmd_name

  local layer_id
  layer_id="$(vedv::builder_service::__layer_"${cmd_name,,}"_calc_id "$cmd")" || {
    err "Failed to calculate layer id for cmd: '$cmd'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly layer_id

  if [[ -z "$layer_id" ]]; then
    err "'layer_id' must not be empty"
    return "$ERR_INVAL_VALUE"
  fi

  vedv::image_service::create_layer "$image_id" "$cmd_name" "$layer_id" || {
    err "Failed to create layer '${cmd_name}' for image '${image_id}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

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
vedv::builder_service::__calc_command_layer_id() {
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
  cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly cmd_name

  if [[ -z "$cmd_name" ]]; then
    err "'cmd_name' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local calc_layer_id
  calc_layer_id="$(vedv::builder_service::__layer_"${cmd_name,,}"_calc_id "$cmd")" || {
    err "Failed to calculate layer id for cmd: '$cmd'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
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
vedv::builder_service::__layer_execute_cmd() {
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
  cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly cmd_name

  if [[ "$cmd_name" != "$caller_command" ]]; then
    err "Invalid command name '${cmd_name}', it must be '${caller_command}'"
    return "$ERR_INVAL_ARG"
  fi

  __restore_last_layer() {
    vedv::image_service::restore_last_layer "$image_id" || {
      err "Failed to restore last layer for image '${image_id}'"
      return "$ERR_BUILDER_SERVICE_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL"
    }
    echo 'Previous layer restored'
  }
  # eval "$exec_func" --> THIS IS WHERE THE NEW DATA IS WRITEN ON TO THE IMAGE
  # IF THIS FAILS AND THE LAYER RESTORATION FAILS TOO, THE IMAGE IS CORRUPTED
  # AND IT MUST BE DELETED.

  eval "$exec_func" || {
    err "Failed to execute command '${cmd}'"
    __restore_last_layer || return $? # OO: exit code 100
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  # create layer
  local layer_id
  layer_id="$(vedv::builder_service::__create_layer "$image_id" "$cmd")" || {
    err "Failed to create layer for image '${image_id}'"
    __restore_last_layer || return $? # OO: exit code 100
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly layer_id

  echo "$layer_id"
  return 0
}

#
# Create the layer from
#
# Preconditions:
#  The image must be started and running
#
# Arguments:
#   image_id  string       image where the files will be copy
#   cmd       string       FROM command (e.g. "1 FROM admin@alpine/alpine-13")
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::__layer_from() {
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

  vedv::builder_service::__create_layer "$image_id" "$cmd" || {
    err "Failed to create layer for image '${image_id}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
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
#
vedv::builder_service::__layer_from_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" 'FROM'
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
vedv::builder_service::__layer_copy_calc_id() {
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
  cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
    err "Failed to get cmd name from cmd: '$cmd'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
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
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

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
    -u | --user | --chown | --chmod)
      shift
      if [[ -n "${1:-}" ]]; then
        shift # option argument
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

  if [[ ! -e "$src" ]]; then
    err "File '${src}': does not exist"
    return "$ERR_INVAL_ARG"
  fi

  local vedvfileignore
  vedvfileignore="$(vedv:builder_vedvfile_service::get_joined_vedvfileignore)" || {
    err "Failed to get joined vedvfileignore"
    return "$ERR_VMOBJ_OPERATION"
  }
  readonly vedvfileignore

  crc_sum_source="$(utils::crc_file_sum "$src" "$vedvfileignore")" || {
    err "Failed getting 'crc_sum_source' for src: '${src}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  readonly crc_sum_source

  local -r base_vedvfileignore_path="$(vedv:builder_vedvfile_service::get_base_vedvfileignore_path)"
  local -r vedvfileignore_path="$(vedv:builder_vedvfile_service::get_vedvfileignore_path)"

  if [[ ! -f "$base_vedvfileignore_path" ]]; then
    err "File ${base_vedvfileignore_path} does not exist"
    return "$ERR_INVAL_VALUE"
  fi

  local crc_sum_base_vedvfileignore
  crc_sum_base_vedvfileignore="$(utils::crc_sum "$base_vedvfileignore_path")" || {
    err "Failed to calc 'crc_sum_base_vedvfileignore'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly crc_sum_base_vedvfileignore

  local crc_sum_vedvfileignore=''

  if [[ -f "$vedvfileignore_path" ]]; then
    crc_sum_vedvfileignore="$(utils::crc_sum "$vedvfileignore_path")" || {
      err "Failed to calc 'crc_sum_vedvfileignore'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
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
vedv::builder_service::__layer_copy() {
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
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

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
  if [[ ! -e "$src" ]]; then
    err "File '${src}': does not exist"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$dest" ]]; then
    err "Argument 'dest' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::copy '${image_id}' '${src}' '${dest}' '${user}' '${chown}' '${chmod}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "COPY" "$exec_func"
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
vedv::builder_service::__simple_layer_command_calc_id() {
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
  cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
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
vedv::builder_service::__expand_cmd_parameters() {
  local -r cmd="$1"
  # validate arguments
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' is required"
    return "$ERR_INVAL_ARG"
  fi

  local escaped_cmd
  escaped_cmd="$(utils::str_escape_double_quotes "$cmd")" || {
    err "Failed to escape command '${cmd}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly escaped_cmd

  source "$(vedv::builder_service::__get_env_vars_file)"

  local evaluated_cmd
  evaluated_cmd="$(eval "echo \"${escaped_cmd}\"")" || {
    err "Failed to evaluate command '${cmd}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  echo "$evaluated_cmd"
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
vedv::builder_service::__layer_run_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "RUN"
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
vedv::builder_service::__layer_run() {
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
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly exec_cmd_encoded

  local -r exec_func="vedv::image_service::execute_cmd '${image_id}' '${exec_cmd_encoded}' '${user}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "RUN" "$exec_func"
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
vedv::builder_service::__layer_user_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "USER"
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
vedv::builder_service::__layer_user() {
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
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r user_name="$1"
  local -r exec_func="vedv::image_service::fs::set_user '${image_id}' '${user_name}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "USER" "$exec_func"
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
vedv::builder_service::__layer_shell_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "SHELL"
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
vedv::builder_service::__layer_shell() {
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
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r shell="$1"
  local -r exec_func="vedv::image_service::fs::set_shell '${image_id}' '${shell}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "SHELL" "$exec_func"
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
vedv::builder_service::__layer_workdir_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "WORKDIR"
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
vedv::builder_service::__layer_workdir() {
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
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

  if [[ $# -ne 3 ]]; then
    err "Invalid number of arguments, expected 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r workdir="$1"
  local -r exec_func="vedv::image_service::fs::set_workdir '${image_id}' '${workdir}' >/dev/null"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "WORKDIR" "$exec_func"
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
vedv::builder_service::__layer_env_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "ENV"
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
vedv::builder_service::__layer_env() {
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
  env="$(vedv::builder_vedvfile_service::get_cmd_body "$cmd")" || {
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
  vedv::builder_service::__add_env_vars "local -r ${UTILS_ENCODED_VAR_PREFIX}${env}"

  local -r env_escaped="$(utils::str_escape_quotes "$env")"

  local env_encoded
  env_encoded="$(utils::str_encode "$env_escaped")" || {
    err "Failed to encode command '${env_escaped}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly env_encoded

  local -r exec_func="vedv::image_service::fs::add_environment_var '${image_id}' '${env_encoded}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "ENV" "$exec_func"
}

#
# Calculates the layer id for the expose command
#
# Arguments:
#   cmd		string    expose command (e.g. "1 EXPOSE bash")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::builder_service::__layer_expose_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" "EXPOSE"
}

#
# Add expose ports
#
# Arguments:
#   image_id  string       image where the expose will be set
#   cmd 	  string       expose command (e.g. "1 EXPOSE 8080/tcp")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::__layer_expose() {
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
  # This works like expose on the terminal, it split the string on spaces
  # ignoring those inside quotes, then it removes the quotes and finally
  # it set the arguments to the positional parameters ($1, $2, $3, ...)
  # cmd: "1 EXPOSE 8080/tcp"
  #
  # also eval do variable substitution
  #
  set -o noglob
  eval set -- "$cmd"
  set +o noglob

  if [[ $# -lt 3 ]]; then
    err "Invalid number of arguments, expected at least 3, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local -r ports="$*"
  local -r exec_func="vedv::image_service::fs::add_exposed_ports '${image_id}' '${ports}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "EXPOSE" "$exec_func"
}

#
# Calculates the layer id for the SYSTEM command
#
# Arguments:
#   cmd   string    system command (e.g. "1 SYSTEM --cpus 2 --memory 128")
#
# Output:
#  Writes layer_id (string) to the stdout
#
# Returns:
#  0 on success, non-zero on error.
#
vedv::builder_service::__layer_system_calc_id() {
  local -r cmd="$1"
  vedv::builder_service::__simple_layer_command_calc_id "$cmd" 'SYSTEM'
}

#
# Set the system cpus and memory
#
# Arguments:
#   image_id  string    image id
#   cmd       string    system command (e.g. "1 SYSTEM --cpus 2 --memory 128")
#
# Output:
#  Writes command_output (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::__layer_system() {
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

  set -o noglob
  eval set -- "$cmd"
  set +o noglob

  if [[ $# -lt 4 ]]; then
    err "Invalid number of arguments, expected at least 4, got $#"
    return "$ERR_INVAL_ARG"
  fi
  shift 2 # skip command id and name

  local cpus=''
  local memory=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    # options
    -c | --cpus)
      readonly cpus="${2:-}"
      # validate argument
      if [[ -z "$cpus" ]]; then
        err "Argument 'cpus' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    -m | --memory)
      readonly memory="${2:-}"
      # validate argument
      if [[ -z "$memory" ]]; then
        err "Argument 'memory' no specified"
        return "$ERR_INVAL_ARG"
      fi
      shift 2
      ;;
    esac
  done
  # validate command arguments
  if [[ -z "$cpus" && -z "$memory" ]]; then
    err "At least one of the arguments 'cpus' or 'memory' is required"
    return "$ERR_INVAL_ARG"
  fi

  local -r exec_func="vedv::image_service::fs::set_system '${image_id}' '${cpus}' '${memory}'"

  vedv::builder_service::__layer_execute_cmd "$image_id" "$cmd" "SYSTEM" "$exec_func"
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
vedv::builder_service::__delete_invalid_layers() {
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
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  local -a layers_ids
  # shellcheck disable=SC2207
  layers_ids=($(vedv::image_entity::get_layers_ids "$image_id")) || {
    err "Failed to get layers ids for image '${image_id}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly layers_ids

  local -a arr_cmds
  readarray -t arr_cmds <<<"$cmds"
  # shellcheck disable=SC2034
  readonly arr_cmds

  # The function ...::__expand_cmd_parameters() needs
  # the environment variables to be in the file
  # __VEDV_BUILDER_SERVICE_ENV_VARS_FILE to work properly.
  vedv::builder_service::__load_env_vars "$image_id" || {
    err "Failed to save environment variables for image '${image_id}' on the local file"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  __calc_item_id_from_arr_cmds() {
    # shellcheck disable=SC2317
    local -r cmd="$1"
    # shellcheck disable=SC2317
    local evaluated_cmd
    # shellcheck disable=SC2317
    evaluated_cmd="$(vedv::builder_service::__expand_cmd_parameters "$cmd")" || {
      err "Failed to evaluate command '${cmd}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    # shellcheck disable=SC2317
    vedv::builder_service::__calc_command_layer_id "$evaluated_cmd"
  }
  # shellcheck disable=SC2317
  __calc_item_id_from_arr_layer_ids() { echo "$1"; }

  local first_invalid_positions
  first_invalid_positions="$(utils::get_first_invalid_positions_between_two_arrays arr_cmds __calc_item_id_from_arr_cmds layers_ids __calc_item_id_from_arr_layer_ids)" || {
    err "Failed to get first invalid positions between two arrays"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly first_invalid_positions

  local -i first_invalid_cmd_pos first_invalid_layer_pos
  IFS='|' read -r \
    first_invalid_cmd_pos \
    first_invalid_layer_pos \
    <<<"$first_invalid_positions"
  readonly first_invalid_cmd_pos first_invalid_layer_pos

  if [[ "$first_invalid_cmd_pos" -eq 0 ]]; then
    echo 0
    return 0
  fi

  local last_valid_layer_id=''

  if [[ "$first_invalid_layer_pos" -ne -1 ]]; then

    local -r layers_length="${#layers_ids[@]}"
    # delete invalid layers
    for ((i = first_invalid_layer_pos; i < layers_length; i++)); do
      local layer_id="${layers_ids[$i]}"
      vedv::image_service::delete_layer "$image_id" "$layer_id" || {
        err "Failed to delete layer '${layer_id}' for image '${image_id}'"
        return "$ERR_BUILDER_SERVICE_OPERATION"
      }
    done

    local -r last_valid_layer_id="${layers_ids[$((first_invalid_layer_pos - 1))]}"

    vedv::image_service::restore_layer "$image_id" "$last_valid_layer_id" || {
      err "Failed to restore last valid layer '${last_valid_layer_id}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
  fi

  echo "$first_invalid_cmd_pos"
  return 0
}

vedv::builder_service::__load_env_vars() {
  local -r image_id="$1"
  # validate arguments
  if [[ -z "$image_id" ]]; then
    err "Argument 'image_id' is required"
    return "$ERR_INVAL_ARG"
  fi
  # create a new temporary file to store the environment variables for the substitution
  local env_vars
  env_vars="$(vedv::image_service::fs::list_environment_vars "$image_id")" || {
    err "Failed to get environment variables for image '${image_id}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  # add 'local -r' prefix to each environment variable in env_vars text
  env_vars="$(sed -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//' -e "s/^/local -r ${UTILS_ENCODED_VAR_PREFIX}/" <<<"$env_vars")"
  readonly env_vars

  vedv::builder_service::__set_env_vars "$env_vars"
}

#
# Create an image from the FROM command
#
# Arguments:
#   from_cmd    string     FROM command (e.g. "1 FROM hello-world")
#   image_name  string     name of the image
#
# Output:
#   Writes image_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::__create_image_by_from_cmd() {
  local from_cmd="$1"
  local image_name="$2"
  # validate arguments
  if [[ -z "$from_cmd" ]]; then
    err "Argument 'from_cmd' is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$image_name" ]]; then
    err "Argument 'image_name' is required"
    return "$ERR_INVAL_ARG"
  fi

  local image
  image="$(vedv::builder_vedvfile_service::get_cmd_body "$from_cmd")" || {
    err "Failed to get cmd body from Vedvfile '${from_cmd}'"
    return "$ERR_VEDV_FILE"
  }
  readonly image

  # create the image
  local image_id_name
  image_id_name="$(vedv::image_service::import_from_any "$image" "$image_name")" || {
    err "Failed to pull image '${image}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly image_id_name

  image_id="${image_id_name%%' '*}"
  readonly image_id

  local layer_from_id
  layer_from_id="$(vedv::image_entity::get_layer_at "$image_id" 0)" || {
    err "Failed to get layer '0' for image '${image_id_name}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }
  readonly layer_from_id

  # delete default FROM layer which id is based on image file hash and not
  # on the FROM command
  vedv::image_service::delete_layer "$image_id" "$layer_from_id" 2>/dev/null || {
    err "Failed to delete layer '1' for image '${image_id_name}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  echo "$image_id"
}

#
# Build image from Vedvfile
#
# Arguments:
#   vedvfile    string     path to Vedvfile
#   image_name  string     name of the image
#   no_cache    bool       delete all layers except the FROM layer
#
# Output:
#   Writes image_id (string) image_name (string) and build proccess #  output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::__build() {
  local -r vedvfile="$1"
  local image_name="${2:-}"
  local -r no_cache="${3:-false}"
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
    image_name="$(petname)" || return $?
  fi
  readonly image_name

  local commands
  commands="$(vedv::builder_vedvfile_service::get_commands "$vedvfile")" || {
    err "Failed to get commands from Vedvfile '${vedvfile}'"
    return "$ERR_VEDV_FILE"
  }
  readonly commands
  # prepare commands for env and arg variable substitution. e.g.
  # VAR_PREFIX_ can be any random string characters like '01b9622e23'
  # VAR_ENCODED_ can be any random string characters like '8027d5b963'
  #
  # 2 RUN echo $NAME -> 1 RUN echo $VAR_PREFIX_NAME
  # 3 COPY . \$HOME -> 1 COPY . VAR_ENCODED_HOME
  local commands_encvars
  commands_encvars="$(utils::str_encode_vars "$commands")" || {
    err "Failed to prepare commands from Vedvfile '${vedvfile}'"
    return "$ERR_VEDV_FILE"
  }
  readonly commands_encvars

  local -a commands_arr
  readarray -t commands_arr <<<"$commands_encvars"
  readonly commands_arr

  local image_id
  image_id="$(vedv::image_entity::get_id_by_image_name "$image_name" 2>/dev/null)" || {
    if [[ $? != "$ERR_NOT_FOUND" ]]; then
      err "Failed to get image id for image '${image_name}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    fi
  }

  __print_build_success_msg() {
    echo
    echo 'Build finished'
    echo "${image_id} ${image_name}"
  }

  local -i first_cmd_to_exec_pos=0

  if [[ -z "$image_id" ]]; then
    # there is no image and must be created
    local -r from_cmd="${commands_arr[0]}"

    image_id="$(vedv::builder_service::__create_image_by_from_cmd "$from_cmd" "$image_name")" || {
      err "Failed to create image '${image_name}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
  else
    vedv::image_service::stop "$image_id" >/dev/null || {
      err "Failed to stop image '${image_name}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    # there is an image, so layers must be validated and the cached data
    # must be updated if any layer is deleted
    local -i initial_layer_count
    initial_layer_count="$(vedv::image_entity::get_layer_count "$image_id")" || {
      err "Failed to get layer count for image '${image_name}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    readonly initial_layer_count

    if [[ "$no_cache" == true ]]; then
      vedv::image_service::delete_layer_cache "$image_id" >/dev/null || {
        err "Failed to delete layer cache for image: '${image_name}'"
        return "$ERR_BUILDER_SERVICE_OPERATION"
      }
    fi

    # first_invalid_layer_pos` is the command position where the build start,
    # all previous commands of this position are ignored because their layers are valid
    local -i first_invalid_cmd_pos
    first_invalid_cmd_pos="$(vedv::builder_service::__delete_invalid_layers "$image_id" "$commands_encvars")" || {
      err "Failed deleting invalid layers for image '${image_name}'. Try build the image again with --no-cache."
      # 2 - A layer deletion fails
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    readonly first_invalid_cmd_pos

    local -ri commands_length="${#commands_arr[@]}"

    if [[ $first_invalid_cmd_pos -lt -1 || $first_invalid_cmd_pos -ge $commands_length ]]; then
      err "Invalid first invalid layer position '${first_invalid_cmd_pos}'"
      return "$ERR_INVAL_VALUE"
    fi

    if [[ "$first_invalid_cmd_pos" -eq 0 ]]; then
      # the layer FROM is invalid, so the image needs to be recreated
      vedv::image_service::remove "$image_id" 'true' >/dev/null || {
        err "Failed to remove image '${image_name}'"
        return "$ERR_BUILDER_SERVICE_OPERATION"
      }

      vedv::builder_service::__build "$vedvfile" "$image_name"
      return $?
    fi

    local -i current_layer_count
    current_layer_count="$(vedv::image_entity::get_layer_count "$image_id")" || {
      err "Failed to get layer count for image '${image_name}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    readonly current_layer_count

    # If any layer was deleted the cached data is obsolete and must be updated
    if [[ "$initial_layer_count" != "$current_layer_count" ]]; then
      # start=$(date +%s%N)
      vedv::image_service::cache_data "$image_id" || {
        err "Failed to cache data for image '${image_name}'"
        return "$ERR_BUILDER_SERVICE_OPERATION"
      }
      # end=$(date +%s%N)
      # echo "time vedv::image_service::cache_data: $(((end - start) / 1000000)) ms."
    fi

    # If no command need to be executed, the build is finished
    if [[ $first_invalid_cmd_pos -eq -1 ]]; then
      __print_build_success_msg
      return 0
    fi

    first_cmd_to_exec_pos=$first_invalid_cmd_pos
  fi

  readonly image_id
  readonly first_cmd_to_exec_pos

  if [[ -z "${commands_arr[*]:$first_cmd_to_exec_pos}" ]]; then
    err "There is no command to run"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  fi

  # Load environment variables from the image
  #
  # The function ...::__expand_cmd_parameters() needs
  # the environment variables to be in the file
  # __VEDV_BUILDER_SERVICE_ENV_VARS_FILE to work properly.
  #
  vedv::builder_service::__load_env_vars "$image_id" || {
    err "Failed to save environment variables for image '${image_id}'"
    return "$ERR_BUILDER_SERVICE_OPERATION"
  }

  for cmd in "${commands_arr[@]:$first_cmd_to_exec_pos}"; do
    local layer_id cmd_name evaluated_cmd

    cmd_name="$(vedv::builder_vedvfile_service::get_cmd_name "$cmd")" || {
      err "Failed to get command name from command '${cmd}'"
      return "$ERR_VEDV_FILE"
    }

    evaluated_cmd="$(vedv::builder_service::__expand_cmd_parameters "$cmd")" || {
      err "Failed to evaluate command '${cmd}'"
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }

    layer_id="$(vedv::builder_service::__layer_"${cmd_name,,}" "$image_id" "$evaluated_cmd")" || {
      local -ri ecode=$?
      err "Failed to create layer for command '${evaluated_cmd}'"

      if [[ $ecode -eq "$ERR_BUILDER_SERVICE_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL" ]]; then
        err "The previous layer to the failure could not be restored. Try build the image again with --no-cache."
        # 3 - A layer creation fails and the previous layer restoration fails too.
        return $ecode
      fi
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }

    echo "created layer '${layer_id}' for command '${cmd_name}'"
  done

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
#   [no_wait_after_build] bool    if true, it will not wait for the
#                                 image to save data cache and stopping
#
# Output:
#  Writes image_id (string) image_name (string) and build proccess #  output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::builder_service::build() {
  local -r vedvfile="$1"
  local image_name="${2:-}"
  local -r force="${3:-false}"
  local -r no_cache="${4:-false}"
  local -r no_wait_after_build="${5:-"$__VEDV_BUILDER_SERVICE_NO_WAIT_AFTER_BUILD"}"
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
      image_id="$(vedv::image_entity::get_id_by_image_name "$image_name" 2>/dev/null)" || {
        if [[ $? != "$ERR_NOT_FOUND" ]]; then
          err "Failed to get image id for image '${image_name}'"
          return "$ERR_BUILDER_SERVICE_OPERATION"
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
      return "$ERR_BUILDER_SERVICE_OPERATION"
    }
    readonly has_containers

    if [[ "$has_containers" == true ]]; then
      err "The image '${image_name}' has containers, you need to force the build, the containers will be removed."
      return "$ERR_BUILDER_SERVICE_OPERATION"
    fi
  fi

  if [[ -z "$image_name" ]]; then
    image_name="$(petname)"
  fi

  vedv::image_service::set_use_cache 'true'

  vedv::builder_service::__build "$vedvfile" "$image_name" "$no_cache" || {
    err "The build proccess has failed."
  }

  if [[ -z "$image_id" ]]; then
    ___set_image_id_64695 || return $?
  fi

  if [[ -n "$image_id" ]]; then
    ___on_build_ends_64695() {
      vedv::image_service::stop "$image_id" >/dev/null || {
        err "Failed to stop the image '${image_name}'.You must stop it."
        return "$ERR_BUILDER_SERVICE_OPERATION"
      }
    }

    if [[ "$no_wait_after_build" == true ]]; then
      ___on_build_ends_64695 &
    else
      ___on_build_ends_64695 || return $?
    fi
  fi

  return 0
}
