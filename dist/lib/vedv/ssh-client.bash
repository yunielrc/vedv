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
      -p "$port" \
      "${user}@${ip}" 2>/dev/null <<SSHEOF
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
    IFS='' sshpass -p "$password" \
      scp -r -T -o 'ConnectTimeout=1' \
      -o 'UserKnownHostsFile=/dev/null' \
      -o 'PubkeyAuthentication=no' \
      -o 'StrictHostKeyChecking=no' \
      -P "$port" \
      $source "${user}@${ip}:${dest}" 2>/dev/null
  } || {
    err "Error on '${user}@${ip}', scp exit code: $?"
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
