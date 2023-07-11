#
# ssh client
#

# FOR CODE COMPLETION
if false; then
  . './utils.bash'
fi

#
# Run commands inside vm
#
# Arguments:
#   user        string    user
#   ip          string    ip
#   password    string    password
#   cmd         string    command
#   [port]      int       ssh port
#   [workdir]   string    workdir
#   [env]       string    environment variable for command
#   [shell]     string    shell to use for command
#
# Output:
#  Writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::ssh_client::run_cmd() {
  local -r user="$1"
  local -r ip="$2"
  local -r password="$3"
  local -r cmd="$4"
  local -ri port=${5:-22}
  local -r workdir="${6:-}"
  local -r env="${7:-}"
  local -r shell="${8:-}"

  if [[ -z "$user" ]]; then
    err "Argument 'user' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::valid_ip "$ip"; then
    err "Invalid Argument 'ip': '${ip}'"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -z "$password" ]]; then
    err "Argument 'password' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::validate_port "$port"; then
    err "Argument 'port' must be a value between 0-65535"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$cmd" ]]; then
    err "Argument 'cmd' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  readonly cmd

  local decoded_cmd
  decoded_cmd="$(utils::str_decode "$cmd")"
  decoded_cmd="$(utils::str_decode_vars "$decoded_cmd")"
  decoded_cmd="${decoded_cmd//\\\$/\$}"
  readonly decoded_cmd

  local set_workdir_cmd=''

  if [[ -n "$workdir" ]]; then
    set_workdir_cmd="cd '${workdir}' || exit 1"
  fi
  readonly set_workdir_cmd

  local set_env=''

  if [[ -n "$env" ]]; then
    local decoded_env
    decoded_env="$(utils::str_decode "$env")"
    readonly decoded_env
    set_env="export ${decoded_env}"
  fi
  readonly set_env

  local begin_shell=''
  local end_shell=''

  if [[ -n "$shell" ]]; then
    begin_shell="${shell} <<'SHELL_EOF'"
    end_shell='SHELL_EOF'
  fi
  readonly begin_shell end_shell

  {
    sshpass -p "$password" \
      ssh -T -o 'ConnectTimeout=2' \
      -o 'UserKnownHostsFile=/dev/null' \
      -o 'PubkeyAuthentication=no' \
      -o 'StrictHostKeyChecking=no' \
      -o 'LogLevel=ERROR' \
      -p "$port" \
      "${user}@${ip}" <<SSHEOF
        ${begin_shell}
        ${set_workdir_cmd}
        ${set_env}
        ${decoded_cmd}
${end_shell}
SSHEOF
  } || {
    err "Error on '${user}@${ip}', exit code: $?"
    return "$ERR_SSH_OPERATION"
  }

  return 0
}

#
# Copy files to a vm
#
# Arguments:
#   user                string  user
#   ip                  string  ip
#   password            string  password
#   port                int     ssh port
#   source              string  source file
#   dest                string  destination file
#   [exclude_file_path] string  exclude file path
#   [workdir]           string  workdir
#   [chown]             string  chown files to user
#   [chmod]             string  chmod files to mode
#
# Output:
#  Writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::ssh_client::copy() {
  local -r user="$1"
  local -r ip="$2"
  local -r password="$3"
  local -ri port=${4:-22}
  local -r source="$5"
  local -r dest="$6"
  local -r exclude_file_path="${7:-}"
  local -r workdir="${8:-}"
  local -r chown="${9:-}"
  local -r chmod="${10:-}"

  if [[ -z "$user" ]]; then
    err "Argument 'user' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::valid_ip "$ip"; then
    err "Invalid Argument 'ip': '${ip}'"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -z "$password" ]]; then
    err "Argument 'password' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::validate_port "$port"; then
    err "Argument 'port' must be a value between 0-65535"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$source" ]]; then
    err "Argument 'source' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$dest" ]]; then
    err "Argument 'dest' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local dest_wd
  dest_wd="$(utils::get_file_path_on_working_dir "$dest" "$workdir")"
  readonly dest_wd

  local rsync_options=''

  if [[ -n "$chown" ]]; then
    rsync_options+="--chown='${chown}'"
  fi
  if [[ -n "$chmod" ]]; then
    rsync_options+=" --chmod='${chmod}'"
  fi

  {
    # with eval and quoting decoded_source its posible to copy files with spaces and wildcards
    # shellcheck disable=SC2086
    eval IFS='' rsync -az --no-owner --no-group "$rsync_options" \
      --exclude-from="'${exclude_file_path}'" \
      -e "'sshpass -p ${password} ssh -o ConnectTimeout=2 -o UserKnownHostsFile=/dev/null  -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o LogLevel=ERROR -p ${port}'" \
      "'${source}'" "'${user}@${ip}:${dest_wd}'"
  } || {
    err "Error on '${user}@${ip}', rsync exit code: $?"
    return "$ERR_SSH_OPERATION"
  }
  return 0
}

#
# Wait for ssh service to be available
#
# Arguments:
#   ip        string  ip
#   port      int     ssh port
#   [timeout] int     timeout in seconds (default: 35)
#
# Output:
#  Writes error message to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::ssh_client::wait_for_ssh_service() {
  local -r ip="$1"
  local -ri port=$2
  local -ri timeout=${3:-40}

  if ! utils::valid_ip "$ip"; then
    err "Invalid Argument 'ip': '${ip}'"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::validate_port "$port"; then
    err "Argument 'port' must be a value between 0-65535"
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$timeout" -le 0 || "$timeout" -gt 60 ]]; then
    err "Argument 'timeout' must be a value between 1-60"
    return "$ERR_INVAL_ARG"
  fi

  local -i i=0
  local -i max="$timeout"

  while ! ssh -T -o 'ConnectTimeout=2' \
    -o 'UserKnownHostsFile=/dev/null' \
    -o 'PubkeyAuthentication=no' \
    -o 'StrictHostKeyChecking=no' \
    -o 'PasswordAuthentication=no' \
    -p "$port" \
    "vedv@${ip}" 2>&1 | grep -q 'Permission denied'; do

    if [[ $i -ge $max ]]; then
      err "Timeout waiting for ssh service on '${ip}'"
      return 1
    fi

    sleep 1
    ((i += 1))
  done
  return 0
}

#
# Connecto to a vm
#
# Arguments:
#   user      string  user name
#   ip        string  ip
#   password  string  password
#   port      int     ssh port
#
# Output:
#  Writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::ssh_client::connect() {
  local -r user="$1"
  local -r ip="$2"
  local -r password="$3"
  local -ri port=${4:-22}

  if [[ -z "$user" ]]; then
    err "Argument 'user' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::valid_ip "$ip"; then
    err "Invalid Argument 'ip': '${ip}'"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -z "$password" ]]; then
    err "Argument 'password' must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  if ! utils::validate_port "$port"; then
    err "Argument 'port' must be a value between 0-65535"
    return "$ERR_INVAL_ARG"
  fi

  {
    sshpass -p "$password" \
      ssh -o 'ConnectTimeout=2' \
      -o 'UserKnownHostsFile=/dev/null' \
      -o 'PubkeyAuthentication=no' \
      -o 'StrictHostKeyChecking=no' \
      -o 'LogLevel=ERROR' \
      -p "$port" \
      "${user}@${ip}"
  } || {
    err "Error on '${user}@${ip}', exit code: $?"
    return "$ERR_SSH_OPERATION"
  }
  return 0
}
