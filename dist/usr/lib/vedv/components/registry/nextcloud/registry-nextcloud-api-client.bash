#
# Registry nextcloud api client
#

# for code completion
if false; then
  . './../../../utils.bash'
fi

#
# Constructor
#
# Arguments:
#   credentials_dict_str   string    registry credentials dict
#                                    eg. ([registry_server_url]="user:password")
#   main_registry_url      string    default registry server url
#   [connect_timeout]      int       connect timeout in seconds
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::constructor() {
  readonly __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_DICT_STR="$1"
  readonly __VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL="$2"
  readonly __VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT="${3:-10}"
}
vedv::registry_api_client::constructor() {
  vedv::registry_nextcloud_api_client::constructor "$@"
}

#
# Get registry domaing
#
# Arguments:
#   [registry_url]  string  registry server url
#
# Output:
#  Writes domain (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::get_domain() {
  local -r registry_url="${1:-"$__VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL"}"

  echo "${registry_url#*://}"
}
vedv::registry_api_client::get_domain() {
  vedv::registry_nextcloud_api_client::get_domain "$@"
}

#
# Get registry user:password
#
# Arguments:
#   [registry_url]  string  registry server url
#
# Output:
#  Writes registry user:password (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::__get_credentials() {
  local -r registry_url="${1:-"$__VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL"}"

  eval local -rA dict="$__VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_DICT_STR"
  # shellcheck disable=SC2154
  if [[ ! -v dict["$registry_url"] ]]; then
    err "Registry '${registry_url}' not found in credentials dict"
    return "$ERR_INVAL_VALUE"
  fi
  local -r user_pass="${dict["$registry_url"]}"

  if [[ -z "$user_pass" ]]; then
    err "Empty user pass for registry '${registry_url}'"
    return "$ERR_INVAL_VALUE"
  fi

  echo "$user_pass"
}

#
# Get registry user
#
# Arguments:
#   [registry_url]  string  registry server url
#
# Output:
#  Writes registry_user (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::get_user() {
  local -r registry_url="${1:-}"

  local user_pass
  user_pass="$(vedv::registry_nextcloud_api_client::__get_credentials "$registry_url")" ||
    return $?

  echo "${user_pass%:*}"
}
vedv::registry_api_client::get_user() {
  vedv::registry_nextcloud_api_client::get_user "$@"
}

#
# Get registry base url
#
# Arguments:
#   [registry_url]  string  registry server url
#
# Output:
#  Writes registry base url (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::__base_url() {
  local -r registry_url="${1:-"$__VEDV_REGISTRY_NEXTCLOUD_API_CREDENTIALS_MAIN_URL"}"

  local user=''
  user="$(vedv::registry_nextcloud_api_client::get_user "$registry_url" 2>/dev/null)" || {
    err "Failed to get user for registry '${registry_url}', on base url"
    return "$ERR_REGISTRY_OPERATION"
  }

  echo "${registry_url}/remote.php/dav/files/${user}"
}

#
# Get owner of a file
#
# Arguments:
#   file            string  file or directory path
#   [registry_url]  string  registry server url
#
# Output:
#  Writes image owner to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::get_file_owner() {
  local -r file="$1"
  local -r registry_url="${2:-}"
  # validate arguments
  if [[ -z "$file" ]]; then
    err "File path is not specified"
    return "$ERR_INVAL_ARG"
  fi

  local base_url=''
  base_url="$(vedv::registry_nextcloud_api_client::__base_url "$registry_url")" ||
    return $?
  readonly base_url

  local credentials=''
  credentials="$(vedv::registry_nextcloud_api_client::__get_credentials "$registry_url")" ||
    return $?
  readonly credentials

  local resp=''
  resp="$(curl "${base_url}/${file#/}" \
    --max-time "$__VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT" \
    --silent \
    --show-error \
    --fail \
    --user "$credentials" \
    --request PROPFIND \
    --data '<?xml version="1.0" encoding="UTF-8"?>
    <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
      <d:prop>
        <oc:owner-display-name />
      </d:prop>
    </d:propfind>')" || {
    err "Failed to get owner for file '${file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
  readonly resp

  xmllint --format - <<<"$resp" | grep -Pom1 "(?<=<oc:owner-display-name>)[^<]+" || {
    err "No owner returned by registry for file '${file}'"
    return "$ERR_REGISTRY_OPERATION"
  }
}
vedv::registry_api_client::get_file_owner() {
  vedv::registry_nextcloud_api_client::get_file_owner "$@"
}

#
# Download a file
#
# Arguments:
#   file            string  path of the file to download
#   local_file      string  file path to save the downloaded file
#   [registry_url]  string  registry server url
#
# Output:
#  Writes error messages to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::download_file() {
  local -r file="$1"
  local -r local_file="$2"
  local -r registry_url="${3:-}"
  # validate arguments
  if [[ -z "$file" ]]; then
    err "File is not specified"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$local_file" ]]; then
    err "Local file is not specified"
    return "$ERR_INVAL_ARG"
  fi

  local base_url=''
  base_url="$(vedv::registry_nextcloud_api_client::__base_url "$registry_url")" ||
    return $?
  readonly base_url

  local credentials=''
  credentials="$(vedv::registry_nextcloud_api_client::__get_credentials "$registry_url")" ||
    return $?
  readonly credentials

  local errmsg=''
  errmsg="$(wget "${base_url}/${file#/}" \
    --connect-timeout "$__VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT" \
    --no-verbose \
    --user "${credentials%%:*}" \
    --password "${credentials#*:}" \
    --output-document "${local_file}" 2>&1)" || {
    err "Failed to download file '${file}'"
    [[ -n "$errmsg" ]] && err "$errmsg"
    return "$ERR_REGISTRY_OPERATION"
  }
}
vedv::registry_api_client::download_file() {
  vedv::registry_nextcloud_api_client::download_file "$@"
}

#
# Create directory
#
# Arguments:
#   directory       string  directory to create
#   [registry_url]  string  registry server url
#
# Output:
#  Writes error messages to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::create_directory() {
  local -r directory="$1"
  local -r registry_url="${2:-}"
  # validate arguments
  if [[ -z "$directory" ]]; then
    err "Directory is not specified"
    return "$ERR_INVAL_ARG"
  fi

  local base_url=''
  base_url="$(vedv::registry_nextcloud_api_client::__base_url "$registry_url")" ||
    return $?
  readonly base_url

  local credentials=''
  credentials="$(vedv::registry_nextcloud_api_client::__get_credentials "$registry_url")" ||
    return $?
  readonly credentials

  local errmsg=''
  errmsg="$(curl "${base_url}/${directory#/}" \
    --connect-timeout "$__VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT" \
    --silent \
    --show-error \
    --fail \
    --user "$credentials" \
    --request MKCOL 2>&1)" || {
    if [[ "$errmsg" == *'error: 405' ]]; then
      # directory already exists
      return 0
    fi

    err "Failed to create directory '${directory}'"
    [[ -n "$errmsg" ]] && err "$errmsg"

    return "$ERR_REGISTRY_OPERATION"
  }
}
vedv::registry_api_client::create_directory() {
  vedv::registry_nextcloud_api_client::create_directory "$@"
}

#
# Upload a file
#
# Arguments:
#   file            string  path of file to upload
#   remote_file     string  path to save the uploaded
#                           file on the registry server
#   [registry_url]  string  registry server url
#
# Output:
#  Writes error messages to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_nextcloud_api_client::upload_file() {
  local -r file="$1"
  local -r remote_file="$2"
  local -r registry_url="${3:-}"
  # validate arguments
  if [[ -z "$file" ]]; then
    err "File is not specified"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$remote_file" ]]; then
    err "Remote file is not specified"
    return "$ERR_INVAL_ARG"
  fi

  local base_url=''
  base_url="$(vedv::registry_nextcloud_api_client::__base_url "$registry_url")" ||
    return $?
  readonly base_url

  local credentials=''
  credentials="$(vedv::registry_nextcloud_api_client::__get_credentials "$registry_url")" ||
    return $?
  readonly credentials

  local errmsg=''
  errmsg="$(curl "${base_url}/${remote_file#/}" \
    --connect-timeout "$__VEDV_REGISTRY_NEXTCLOUD_API_CONNECT_TIMEOUT" \
    --silent \
    --show-error \
    --fail \
    --user "$credentials" \
    --upload-file "$file" 2>&1)" || {
    err "Failed to upload file to '${remote_file}'"
    [[ -n "$errmsg" ]] && err "$errmsg"

    return "$ERR_REGISTRY_OPERATION"
  }
}
vedv::registry_api_client::upload_file() {
  vedv::registry_nextcloud_api_client::upload_file "$@"
}
