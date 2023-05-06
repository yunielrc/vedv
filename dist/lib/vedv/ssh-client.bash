#
# Run commands inside vm
#
# Arguments:
#   user          virtual machine ip
#   ip            ip
#   password      password
#   cmd           command
#   port          ssh port
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

  {
    sshpass -p "$password" \
      ssh -T -o 'ConnectTimeout=1' \
      -o 'UserKnownHostsFile=/dev/null' \
      -o 'PubkeyAuthentication=no' \
      -o 'StrictHostKeyChecking=no' \
      -o 'LogLevel=ERROR' \
      -p "$port" \
      "${user}@${ip}" <<SSHEOF
         eval "$cmd"
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
#   user          virtual machine ip
#   ip            ip
#   password      password
#   port          ssh port
#   source        source file
#   dest          destination file
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

  {
    # shellcheck disable=SC2086
    IFS='' rsync -az \
      --exclude-from="$exclude_file_path" \
      -e "sshpass -p ${password} ssh -o 'ConnectTimeout=1' -o 'UserKnownHostsFile=/dev/null'  -o 'PubkeyAuthentication=no' -o 'StrictHostKeyChecking=no' -o 'LogLevel=ERROR' -p ${port}" \
      $source "${user}@${ip}:${dest}"
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
#   ip  string        ip
#   port  int         ssh port
#   [timeout] int     timeout in seconds (default: 25)
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::ssh_client::wait_for_ssh_service() {
  local -r ip="$1"
  local -ri port=$2
  local -ri timeout=${3:-35}

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

  while ! ssh -T -o 'ConnectTimeout=1' \
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
#   user          virtual machine ip
#   ip            ip
#   password      password
#   port          ssh port
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
      ssh -o 'ConnectTimeout=1' \
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
