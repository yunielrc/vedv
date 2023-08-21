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
readonly ERR_IMAGE_ENTITY=89
readonly ERR_CONTAINER_ENTITY=90
readonly ERR_VMOBJ_ENTITY=91
readonly ERR_VMOBJ_OPERATION=92
readonly ERR_CHECKSUM=93
readonly ERR_FILE_EXISTS=94
readonly ERR_DOWNLOAD=95
readonly ERR_FAILED_CREATE_DIR=96
readonly ERR_BUILDER_SERVICE_OPERATION=97
readonly ERR_REGISTRY_OPERATION=98
readonly ERR_COPY_FILE=99
# This error code can only be throwed by vedv::builder_service::__layer_execute_cmd()
readonly ERR_BUILDER_SERVICE_LAYER_CREATION_FAILURE_PREV_RESTORATION_FAIL=100
readonly ERR_FILE_DOWNLOADER=101
#
readonly UTILS_ENCODED_VAR_PREFIX='var_9f57a558b3_'
readonly UTILS_ENCODED_ESCVAR_PREFIX='escvar_fc064fcc7e_'

readonly UTILS_DOMAIN_NAME_EREGEX='[A-Za-z0-9-]+([\-\.]{1}[a-z0-9]+)*\.[A-Za-z]{2,6}'
readonly UTILS_URL_EREGEX='https?://[-a-zA-Z0-9+\&@\#/%?=~_|!:,.\;]*'
readonly UTILS_HTTP_URL_EREGEX="(https?://)?${UTILS_DOMAIN_NAME_EREGEX}"

#
# Constructor
#
# Arguments:
#  tmp_dir  string  temporary directory
#
utils::constructor() {
  readonly __VEDV_UTILS_TMP_DIR="$1"
}

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

utils::gen_password() {
  openssl rand -hex 10
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
crc_sum() { utils::crc_sum "$@"; }

#
# calc crc sum for a file, a set of files, or a files inside a directory
#
# Arguments:
#  source               string    file or directory
#  [exclude_file_path]  string    file with a list of files to exclude
#
# Output:
#  writes file crc sum to stdout
#
# Returns:
#  0 on success, non-zero on error.
#
utils::crc_file_sum() {
  local -r source="$1"
  local -r exclude_file_path="${2:-}"

  rsync -azv \
    --info=FLIST0,STATS0 \
    --relative \
    --dry-run \
    --exclude-from "${exclude_file_path}" \
    "$source" "$(mktemp -d)" |
    sed '/\/$/d' |
    sed 's/ ->.*$//' |
    tr '\n' '\0' |
    xargs -0 cksum |
    LC_ALL=C sort |
    cksum |
    cut -d' ' -f1
  # IFS='' eval find "$1" -type f -exec cksum {} + | LC_ALL=C sort | cksum | cut -d' ' -f1
  return "${PIPESTATUS[0]}"
}
crc_file_sum() { utils::crc_file_sum "$1"; }

utils::valid_ip() {
  [[ "$1" =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]
}

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
  local -i min max
  read -r min max </proc/sys/net/ipv4/ip_local_port_range
  readonly min max

  local -i port="$(utils::random_number $min $max)"

  while nc -z localhost $port &>/dev/null; do
    port="$(utils::random_number $min "$max")"
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
      set -o noglob
      return "$ERR_INVAL_ARG"
    fi
    # shellcheck disable=SC2317
    echo "${!arg_pos}"
  }
  set -o noglob
  eval "__get ${args}"
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

    local item_a_id
    item_a_id="$("$calc_item_id_func_a" "$item_a")" || {
      err "Error calculating item_a id"
      return "$ERR_INVAL_ARG"
    }
    local item_b_id
    item_b_id="$("$calc_item_id_func_b" "$item_b")" || {
      err "Error calculating item_b id"
      return "$ERR_INVAL_ARG"
    }

    if [[ "$item_a_id" != "$item_b_id" ]]; then
      first_invalid_pos_a="$i"
      first_invalid_pos_b="$i"
      break
    fi
  done

  echo "${first_invalid_pos_a}|${first_invalid_pos_b}"
}

#
# Return the array as a string
#
# Arguments:
#   arr_name  string    array name
#
# Output:
#   writes the array as a string to stdout
#
utils::array::to_string() {
  local -r arr_name="$1"

  local arr_text
  arr_text="$(declare -p "$arr_name")"

  echo "${arr_text#*=}"
}

#
# Return the array as a string
#
# Arguments:
#   arr_name  string    array name
#
# Output:
#   writes the array as a string to stdout
#
arr2str() { utils::array::to_string "$@"; }

utils::sleep() { sleep "$@"; }

declare -ga VED_UTILS_DECODED_CHARS=()
VED_UTILS_DECODED_CHARS[0]="'"
VED_UTILS_DECODED_CHARS[1]='"'
readonly VED_UTILS_DECODED_CHARS

declare -ga VED_UTILS_ENCODED_CHARS=()
VED_UTILS_ENCODED_CHARS[0]='3c5d99d4c5'
VED_UTILS_ENCODED_CHARS[1]='f7ce31e217'
readonly VED_UTILS_ENCODED_CHARS

declare -ga VED_UTILS_ENCODED_CHARS2=()
VED_UTILS_ENCODED_CHARS2[0]="'3c5d99d4c5"
VED_UTILS_ENCODED_CHARS2[1]='"f7ce31e217'
readonly VED_UTILS_ENCODED_CHARS2

#
# Encode a string and keep the original char in the string
#
# Arguments:
#   str   string    string to encode
#
# Output:
#   writes the encoded string to stdout
#
utils::str_encode2() {
  local -r str="$1"

  if [[ -z "$str" ]]; then
    return 0
  fi

  local str_encoded="$str"

  for ((i = 0; i < ${#VED_UTILS_DECODED_CHARS[@]}; i += 1)); do
    local decode_char="${VED_UTILS_DECODED_CHARS[$i]}"
    local encoded_char="${VED_UTILS_ENCODED_CHARS2[$i]}"

    str_encoded="${str_encoded//"$decode_char"/"$encoded_char"}"
  done

  echo "$str_encoded"
}

#
# Encode a string
#
# Arguments:
#   str   string    string to encode
#
# Output:
#   writes the encoded string to stdout
#
utils::str_encode() {
  local -r str="$1"

  if [[ -z "$str" ]]; then
    return 0
  fi

  local str_encoded="$str"

  for ((i = 0; i < ${#VED_UTILS_DECODED_CHARS[@]}; i += 1)); do
    local decode_char="${VED_UTILS_DECODED_CHARS[$i]}"
    local encoded_char="${VED_UTILS_ENCODED_CHARS[$i]}"

    str_encoded="${str_encoded//"$decode_char"/"$encoded_char"}"
  done

  echo "$str_encoded"
}

#
# Decode a string
#
# Arguments:
#   str   string    string to decode
#
# Output:
#   writes the decoded string to stdout
#
utils::str_decode() {
  local -r str="$1"

  if [[ -z "$str" ]]; then
    return 0
  fi

  local str_decoded="$str"

  for ((i = 0; i < ${#VED_UTILS_ENCODED_CHARS[@]}; i += 1)); do
    local decode_char="${VED_UTILS_DECODED_CHARS[$i]}"
    local encoded_char="${VED_UTILS_ENCODED_CHARS[$i]}"

    str_decoded="${str_decoded//"$encoded_char"/"$decode_char"}"
  done

  echo "$str_decoded"
}

#
# Get file path on working directory
#
# Arguments:
#   file_name   string    file name
#   working_dir string    working directory
#
# Output:
#   writes the file path (string) to stdout
#
utils::get_file_path_on_working_dir() {
  local -r file_name="$1"
  local -r working_dir="${2:-}"
  # validate arguments
  if [[ -z "$file_name" ]]; then
    err "file_name is required"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -z "$working_dir" ]]; then
    echo "$file_name"
    return 0
  fi
  if [[ "${file_name:0:1}" != @('/'|'~') ]]; then
    echo "${working_dir%/}/${file_name}"
    return 0
  fi

  echo "$file_name"
}

#
# Escape quotes in a string
#
# Arguments:
#   str   string    string to scape
#
# Output:
#   writes the encoded string to stdout
#
utils::str_escape_quotes() {
  local -r str="$1"

  # escape \
  local str_escaped="${str//\\/\\\\}"
  # escape single quotes
  str_escaped="${str_escaped//\'/\\\'}"
  # escape double quotes
  str_escaped="${str_escaped//\"/\\\"}"

  echo "$str_escaped"
}

#
# Escape quotes in a string maintaining the original quotes
#
# Arguments:
#   str   string    string to scape
#
# Output:
#   writes the encoded string to stdout
#
utils::str_escape_quotes2() {
  local -r str="$1"

  # escape \
  local str_escaped="${str//\\/\\\\}"
  # escape single quotes
  str_escaped="${str_escaped//\'/\'\\\'}"
  # escape double quotes
  str_escaped="${str_escaped//\"/\"\\\"}"

  echo "$str_escaped"
}

#
# Remove quotes in a string
#
# Arguments:
#   str   string    string to remove quotes
#
# Output:
#   writes the encoded string to stdout
#
utils::str_remove_quotes() {
  local -r str="$1"

  # remove single quotes
  local str_no_quotes="${str//\'/}"
  # remove double quotes
  str_no_quotes="${str_no_quotes//\"/}"

  echo "$str_no_quotes"
}

#
# Alias for utils::str_remove_quotes()
#
# Remove quotes in a string
#
# Arguments:
#   str   string    string to remove quotes
#
# Output:
#   writes the encoded string to stdout
#
str_rm_quotes() { utils::str_remove_quotes "$@"; }

declare -ga VED_UTILS_DECODED_VARS=()
VED_UTILS_DECODED_VARS[0]='\$'
# shellcheck disable=SC2016
VED_UTILS_DECODED_VARS[1]='${'
VED_UTILS_DECODED_VARS[2]='$'
VED_UTILS_DECODED_VARS[3]='subvar_ef1677a892_'
readonly VED_UTILS_DECODED_VARS

declare -ga VED_UTILS_ENCODED_VARS=()
VED_UTILS_ENCODED_VARS[0]="$UTILS_ENCODED_ESCVAR_PREFIX"
VED_UTILS_ENCODED_VARS[1]='subvar_ef1677a892_'
VED_UTILS_ENCODED_VARS[2]="\$${UTILS_ENCODED_VAR_PREFIX}"
VED_UTILS_ENCODED_VARS[3]="\${${UTILS_ENCODED_VAR_PREFIX}"
readonly VED_UTILS_ENCODED_VARS

#
# Encode the variables in a text
#
# Arguments:
#   str   text    text to encode
#
# Output:
#   writes the encoded string to stdout
#
utils::str_encode_vars() {
  local -r str="$1"

  if [[ -z "$str" ]]; then
    return 0
  fi

  local str_encoded="$str"

  for ((i = 0; i < ${#VED_UTILS_DECODED_VARS[@]}; i += 1)); do
    local decode_char="${VED_UTILS_DECODED_VARS[$i]}"
    local encoded_char="${VED_UTILS_ENCODED_VARS[$i]}"

    str_encoded="${str_encoded//"$decode_char"/"$encoded_char"}"
  done

  echo "$str_encoded"
}

#
# Decode the variables in a text
#
# Arguments:
#   str   text    text to decode
#
# Output:
#   writes the decoded string to stdout
#
utils::str_decode_vars() {
  local -r str="$1"

  if [[ -z "$str" ]]; then
    return 0
  fi

  local str_decoded="$str"

  for ((i = ${#VED_UTILS_ENCODED_VARS[@]} - 1; i >= 0; i -= 1)); do
    local decode_char="${VED_UTILS_DECODED_VARS[$i]}"
    local encoded_char="${VED_UTILS_ENCODED_VARS[$i]}"

    str_decoded="${str_decoded//"$encoded_char"/"$decode_char"}"
  done

  echo "$str_decoded"
}

#
# Escape double quotes in a string
#
# Arguments:
#   str   string    string to scape
#
# Output:
#   writes the encoded string to stdout
#
utils::str_escape_double_quotes() {
  local -r str="$1"

  echo "${str//\"/\\\"}"
}

#
# sha256sum check
#
# Arguments:
#   checksum_file   string    file with the checksum
#
# Returns:
#   0 if the checksum is correct or 1 otherwise
#
utils::sha256sum_check() {
  local -r checksum_file="$1"
  # validate arguments
  if [[ -z "$checksum_file" ]]; then
    err "checksum_file is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -f "$checksum_file" ]]; then
    err "checksum file doesn't exist"
    return "$ERR_NOFILE"
  fi

  (
    local -r file_dir="${checksum_file%/*}"

    cd "$file_dir" || {
      err "Error changing directory to '${file_dir}'"
      return "$ERR_NOFILE"
    }
    # check the checksum
    sha256sum --status --check "$checksum_file" &>/dev/null || {
      err "checksum doesn't match"
      return "$ERR_CHECKSUM"
    }
  )
}

#
# Check if a string is a valid URL
#
# Arguments:
#   url   string    string to check
#
# Returns:
#   0 if the string is a valid URL or 1 otherwise
#
utils::is_url() {
  local -r url="$1"
  [[ $url =~ ^${UTILS_URL_EREGEX}$ ]]
}

#
# Make a temporary directory
#
# Arguments:
#   [tmp_dir]   string    base directory (default: __VEDV_UTILS_TMP_DIR)
#
# Output:
#   Writes the path of the temporary directory (string) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
utils::mktmp_dir() {
  local -r tmp_dir="${1:-"$__VEDV_UTILS_TMP_DIR"}"
  mktemp -p "$tmp_dir" -d
}

#
# Validate the format of a sha256sum file
#
# Arguments:
#   checksum_file   string    file with the checksum
#
# Returns:
#   0 if the checksum file is valid or 1 otherwise
#
utils::validate_sha256sum_format() {
  local checksum_file="$1"
  # validate arguments
  if [[ -z "$checksum_file" ]]; then
    err "checksum_file is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ ! -f "$checksum_file" ]]; then
    err "checksum file doesn't exist"
    return "$ERR_NOFILE"
  fi

  while read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi
    if [[ ! $line =~ ^[a-f0-9]{64}[[:space:]]+.+$ ]]; then
      return 1
    fi
  done <"$checksum_file"

  return 0
}

#
# Generate a random number between min and max
#
# Arguments:
#   [min] int   minimum value (default: 100)
#   [max] int   maximum value (default: 200)
#
# Output:
#   Writes the random number (int) to stdout
#
# Returns:
#   0 on success, non-zero on error.
#
utils::random_number() {
  local -ri min="${1:-100}"
  local -ri max="${2:-200}"

  if [[ -z "$min" ]]; then
    err "min is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$max" ]]; then
    err "max is required"
    return "$ERR_INVAL_ARG"
  fi

  echo "$((min + RANDOM % $((max - min))))"
}

#
# Generate a random number string
#
#
# Output:
#   Writes the random string to stdout
#
utils::random_string() {
  openssl rand -hex 15
}

#
# Escape a string for use in a posix basic regular expression
# (IT ONLY ESCAPES THE CHARACTERS: .)
#
# Arguments:
#   str   string    string to scape
#
# Output:
#   writes the escaped string to stdout
#
utils::escape_for_bregex() {
  local -r str="$1"

  local esc_str="${str//./\\.}"

  echo "$esc_str"
}
