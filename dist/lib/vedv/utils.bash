# shellcheck disable=SC2034

# ERROR CODES
readonly ERR_NOFILE=64              # file doesn't exist
readonly ERR_NOT_FOUND=65           # not found
readonly ERR_INVAL_VALUE=66         # not supported
readonly ERR_INVAL_INPUT=68         # invalid input
readonly ERR_INVAL_ARG=69           # invalid argument
readonly ERR_NOTIMPL=70             # function not implemented
readonly ERR_VM_EXIST=80            # vm exist
readonly ERR_CONTAINER_OPERATION=81 # error starting container vm
readonly ERR_IMAGE_OPERATION=82
readonly ERR_VEDV_FILE=83
readonly ERR_LAYER_OPERATION=84
readonly ERR_SSH_OPERATION=85
readonly ERR_VIRTUALBOX_OPERATION=86
readonly ERR_QEMU_OPERATION=87
readonly ERR_HYPERVISOR_OPERATION=88
readonly ERR_IMAGE_BUILDER_OPERATION=88
readonly ERR_IMAGE_ENTITY=89
readonly ERR_CONTAINER_ENTITY=90

# REGEX
UTILS_REGEX_NAME='[[:alnum:]]+((-|_)[[:alnum:]]+)*'

err() {
  echo -e "$*" >&2
}

dierr() {
  err "$1"
  exit "$2"
}

inf() {
  echo "$*"
}

utils::gen_id() {
  uuidgen | cksum | cut -d' ' -f1
}

#
# Compute crc sum of a given text or file
#
# Arguments:
#  file          file or directory
#
# Output:
#  writes file crc sum to stdout
#
# Returns:
#  0 on success, non-zero on error.
#
utils::crc_sum() {

  cksum "$@" | cut -d' ' -f1
  return "${PIPESTATUS[0]}"
}
crc_sum() { utils::crc_sum "${1:-}"; }

utils::crc_file_sum() {
  # shellcheck disable=SC2086
  IFS='' find $1 -type f -exec cksum {} + | LC_ALL=C sort | cksum | cut -d' ' -f1
  return "${PIPESTATUS[0]}"
}
crc_file_sum() { utils::crc_file_sum "$1"; }

utils::valid_ip() {
  [[ "$1" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]
}

#
# Fix invalid variable names in a given text
#
# Arguments
# Output:
#   writes text with fixed variable names to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
utils::fix_var_names() {
  local -r vars="$1"

  while read -r line; do
    if echo "$line" | grep -qP '^[^=]+='; then
      local name="$(echo "$line" | cut -d'=' -f1 | tr -d '"' | tr -d ' ' | tr '-' '_')"
      local value="$(echo "$line" | sed -e 's/^[^=]\+=//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      echo "${name}=${value}"
    elif echo "$line" | grep -qP '^[^:]+:'; then
      local name="$(echo "$line" | cut -d':' -f1 | tr -d '"' | tr -d ' ' | tr '-' '_')"
      local value="$(echo "$line" | sed -e 's/^[^:]\+://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      echo "${name}=${value}"
    else
      echo "$line"
    fi
  done <<<"$vars"
}
fix_var_names() { utils::fix_var_names "$@"; }

#
# Return an available dynamic port (49152-65535)
#
# In Unix ports 0 to 1023 are reserved for privileged
# services and designated as "Well Known Ports." Ports
# 1024 to 49151 are designated as "Registered Ports" and
# are used for common, registered services.
# Ports 49152 to 65535 are designated as "Dynamic Ports"
# and are typically used for client applications that
# do not have a need for a registered port number.
#
# Output:
#   writes an available port to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
utils::get_a_dynamic_port() {
  __random_port() { shuf -i 49152-65535 -n 1; }
  local -i port="$(__random_port)"

  while nc -z localhost $port &>/dev/null; do
    port="$(__random_port)"
  done

  echo $port
}
get_a_dynamic_port() { utils::get_a_dynamic_port "$@"; }

#
# Trim text spaces, delete empty lines
#
# Arguments:
#   text     text to trim
#
# Input:
#   read text to trim from stdin
#
# Output:
#   writes trimmed text to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
utils::string::trim() {
  local -r text="$*"
  {
    if [[ -n "$text" ]]; then
      echo "$text"
    elif [[ ! -t 0 ]]; then
      cat -
    fi
  } | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^\s*$/d'
}

#
# Validate unix port
#
# Arguments:
#   port     unix port between 0 and 65535
#
# Returns:
#   0 on if valid, 1 otherwise
#
utils::validate_port() {
  local -ri port="$1"

  [[ "$port" -ge 0 && "$port" -le 65535 ]]
}

#
# Get argument from string
#
# Arguments:
#  args     string with arguments
#  arg_pos  argument position
#
# Output:
#  writes argument to stdout
#
# Returns:
# 0 on success, non-zero on error.
#
utils::get_arg_from_string() {
  local -r args="$1"
  local -r arg_pos="$2"

  # validate arguments
  if [[ -z "$args" ]]; then
    err "Argument 'args' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$arg_pos" ]]; then
    err "Argument 'arg_pos' must not be empty"
    return "$ERR_INVAL_ARG"
  fi
  # shellcheck disable=SC2034
  __get() {
    # shellcheck disable=SC2317
    set +o noglob
    # shellcheck disable=SC2317
    if [[ "$arg_pos" -le 0 || "$arg_pos" -gt $# ]]; then
      err "Argument 'arg_pos' must be between 1 and $#"
      return "$ERR_INVAL_ARG"
    fi
    # shellcheck disable=SC2317
    echo "${!arg_pos}"
  }
  set -o noglob
  eval "__get ${args}"
}

#
# Validate name
#
# Arguments:
#   image   name to validate
#
# Returns:
#   0 if valid, 1 if invalid
#
utils::validate_name_or_id() {
  local -r name="$1"
  # validate arguments
  if [[ -z "$name" ]]; then
    err "Argument must not be empty"
    return "$ERR_INVAL_ARG"
  fi

  local -r pattern="^${UTILS_REGEX_NAME}\$"
  if [[ ! "$name" =~ $pattern ]]; then
    err "Invalid argument '${name}'"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Get the minimum between two numbers
#
# Arguments:
#   a     number
#   b     number
#
# Output:
#   writes the minimum number to stdout
#
utils::minimun() {
  local -ri a="$1"
  local -ri b="$2"

  if [[ "$a" -lt "$b" ]]; then
    echo "$a"
  else
    echo "$b"
  fi
}

#
# Get the first invalid positions between two arrays
#
# Arguments:
#   arr_a[]             array<string>   array of items A
#   calc_item_id_func_a string          function to calculate item #                                       id from array_a
#   arr_b[]             array<string>   array of items B
#   calc_item_id_func_b string          function to calculate item #                                       id from array_b
#
# Output:
#   writes the first invalid positions (string) to stdout
#   in the format: 'first_invalid_pos_a|first_invalid_pos_b',
#   where: -1 means that the array is valid
#
utils::get_first_invalid_positions_between_two_arrays() {
  local -rn _arr_a="$1"
  local -r calc_item_id_func_a="$2"
  local -rn _arr_b="$3"
  local -r calc_item_id_func_b="$4"

  local -ri arr_a_length="${#_arr_a[@]}"
  local -ri arr_b_length="${#_arr_b[@]}"

  local -i first_invalid_pos_a=-1
  local -i first_invalid_pos_b=-1

  local -ri min_lenght="$(utils::minimun "$arr_a_length" "$arr_b_length")"

  if [[ "$arr_a_length" -gt "$arr_b_length" ]]; then
    first_invalid_pos_a="$min_lenght"
  elif [[ "$arr_b_length" -gt "$arr_a_length" ]]; then
    first_invalid_pos_b="$min_lenght"
  fi

  for ((i = 0; i < min_lenght; i += 1)); do
    local item_a="${_arr_a[$i]}"
    local item_b="${_arr_b[$i]}"

    local item_a_id="$("$calc_item_id_func_a" "$item_a")"
    local item_b_id="$("$calc_item_id_func_b" "$item_b")"

    if [[ "$item_a_id" != "$item_b_id" ]]; then
      first_invalid_pos_a="$i"
      first_invalid_pos_b="$i"
      break
    fi
  done

  echo "${first_invalid_pos_a}|${first_invalid_pos_b}"
}
