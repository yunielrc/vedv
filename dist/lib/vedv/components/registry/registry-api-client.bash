#
# Registry api client
#

if false; then
  . './../../utils.bash'
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
vedv::registry_api_client::constructor() {
  err "Not implemented"
  return "$ERR_NOTIMPL"
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
vedv::registry_api_client::get_user() {
  err "Not implemented"
  return "$ERR_NOTIMPL"
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
vedv::registry_api_client::get_domain() {
  err "Not implemented"
  return "$ERR_NOTIMPL"
}

#
# Get owner of a file
#
# Arguments:
#   file            string  file or directory path
#   [registry_url]  string  registry server url
#
# Output:
#  Writes image_owner (string) to the stdout
#  Writes error messages (string) to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_api_client::get_file_owner() {
  err "Not implemented"
  return "$ERR_NOTIMPL"
}

#
# Download a file
#
# Arguments:
#   file            string  file path
#   output_file     string  output file path
#   [registry_url]  string  registry server url
#
# Output:
#  Writes error messages to stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::registry_api_client::download_file() {
  err "Not implemented"
  return "$ERR_NOTIMPL"
}
