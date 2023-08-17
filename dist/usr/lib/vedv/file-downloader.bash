#
# File Downloader
#
# download a file from http/https, google drive, onedrive.
#

# for code completion
if false; then
  . './utils.bash'
fi

#
# Constructor
#
# Arguments:
#   user_agent  string    user agent to use in the http requests
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::constructor() {
  readonly __VEDV_FILE_DOWNLOADER_USER_AGENT="$1"
}

file_downloader::__validate_args() {
  local -r url="$1"
  local -r file="$2"
  # validate arguments
  if [[ -z "$url" ]]; then
    err "url is required"
    return "$ERR_INVAL_ARG"
  fi
  if ! utils::is_url "$url"; then
    err "url is not valid"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$file" ]]; then
    err "file is required"
    return "$ERR_INVAL_ARG"
  fi

  return 0
}

#
# Download a file
#
# Arguments:
#   url   string    url to download
#   file  string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::http_download() {
  local -r url="$1"
  local -r file="$2"
  # validate arguments
  file_downloader::__validate_args "$url" "$file" ||
    return "$?"

  wget --header "$__VEDV_FILE_DOWNLOADER_USER_AGENT" -qO "$file" "$url" || {
    err "error downloading file from ${url}"
    return "$ERR_DOWNLOAD"
  }
}

#
# Download a file from onedrive
#
# Arguments:
#   url   string    embed link url
#   file  string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::onedrive_embed_download() {
  # validate arguments
  file_downloader::__validate_args "$url" "$file" ||
    return "$?"

  # https://onedrive.live.com/embed?resid=DBA0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg
  # https://onedrive.live.com/download?resid=DBA0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg
  local -r download_url="${url/\/embed?//\download?}"

  wget --header "$__VEDV_FILE_DOWNLOADER_USER_AGENT" -qO "$file" "$download_url" || {
    err "error downloading file from ${url}"
    return "$ERR_DOWNLOAD"
  }
}

#
# Download a file from google drive that is > 100MB
#
# Arguments:
#   url   string    shared link url
#   file  string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::gdrive_big_download() {
  local -r url="$1"
  local -r file="$2"
  # validate arguments
  file_downloader::__validate_args "$url" "$file" ||
    return "$?"
  # https://drive.google.com/file/d/1O-Ss7b-M3ieg9x42TQoJvTv_NlzU90I2/view
  # https://docs.google.com/uc?export=download&id=FILEID

  local file_id
  file_id="$(grep -Pom1 '/file/d/\K\S+(?=/view)' <<<"$url")" || {
    err "error getting file id from ${url}"
    return "$ERR_FILE_DOWNLOADER"
  }
  readonly file_id

  local -r download_url="https://docs.google.com/uc?export=download&id=${file_id}"

  local cookies_file
  cookies_file="$(mktemp)" || {
    err "error creating temp file"
    return "$ERR_FILE_DOWNLOADER"
  }
  readonly cookies_file
  # shellcheck disable=SC2064
  trap "rm -f '${cookies_file}'" INT TERM EXIT

  local confirm=''
  confirm="$(wget --no-check-certificate \
    --header "$__VEDV_FILE_DOWNLOADER_USER_AGENT" \
    --save-cookies "$cookies_file" \
    --keep-session-cookies "$download_url" -qO-)" || {
    err "error getting confirmation from ${url}"
    return "$ERR_DOWNLOAD"
  }
  confirm="$(sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p' <<<"$confirm")"
  readonly confirm

  local -r download_url2="https://docs.google.com/uc?export=download&confirm=${confirm}&id=${file_id}"

  wget --no-check-certificate \
    --header "$__VEDV_FILE_DOWNLOADER_USER_AGENT" \
    --load-cookies "$cookies_file" \
    -qO "$file" "$download_url2" || {
    err "error downloading file from ${url}"
    return "$ERR_DOWNLOAD"
  }
}

#
# Download a file from google drive that is <= 100mb
#
# Arguments:
#   url   string    shared link url
#   file  string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::gdrive_small_download() {
  local -r url="$1"
  local -r file="$2"
  # validate arguments
  file_downloader::__validate_args "$url" "$file" ||
    return "$?"
  # https://drive.google.com/file/d/1O-Ss7b-M3ieg9x42TQoJvTv_NlzU90I2/view
  # https://docs.google.com/uc?export=download&id=FILEID

  local file_id
  file_id="$(grep -Pom1 '/file/d/\K\S+(?=/view)' <<<"$url")" || {
    err "error getting file id from ${url}"
    return "$ERR_FILE_DOWNLOADER"
  }
  readonly file_id
  local -r download_url="https://docs.google.com/uc?export=download&id=${file_id}"

  wget --no-check-certificate \
    --header "$__VEDV_FILE_DOWNLOADER_USER_AGENT" \
    -qO "$file" "$download_url" || {
    err "error downloading file from ${url}"
    return "$ERR_DOWNLOAD"
  }
}

#
# Check if the address is valid
#
# Arguments:
#   address   string    address to check
#
# Output:
#   Writes true to stdout if the address is valid, false otherwise.
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::is_address() {
  local -r address="$1"
  # validate arguments
  if [[ -z "$address" ]]; then
    err "address is required"
    return "$ERR_INVAL_ARG"
  fi

  if [[ "$address" =~ ^((https?|gdrive-big|gdrive-small|onedrive|magnet)=)?${UTILS_URL_EREGEX}$ ]]; then
    echo true
  else
    echo false
  fi
}

#
# Download a file from magnet link
#
# Arguments:
#   magnet_link   string    magnet link
#   file          string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::magnet_link_download() {
  # local -r magnet_link="$1"
  # local -r file="$2"
  err "not implemented"
  return "$ERR_NOT_IMPLEMENTED"
}

#
# download a file from http/https, google drive, onedrive
#
# Arguments:
#   address   string    address of file to download
#                         http download:
#                           e.g.: http=http://example.com/alpine.ova
#                         gdrive download >100mb:
#                           e.g.: gdrive-big=https://drive.google.com/file/d/1iya7JW_-anYYYzfQqitb_RDHJVAngzBQ/view?usp=drive_link
#                         gdrive download <=100mb:
#                           e.g.: gdrive-small=https://drive.google.com/file/d/11-Ss7b-M3ieg9x42TQoJvTv_NlzU90I2/view?usp=drive_link
#                         onedrive download:
#                           e.g.: onedrive=https://onedrive.live.com/embed?resid=DBC0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg
#
#   file      string    file to save the download
#
# Returns:
#   0 on success, non-zero on error.
#
file_downloader::any_download() {
  local -r address="$1"
  local -r file="$2"

  # validate arguments
  if [[ -z "$address" ]]; then
    err "address is required"
    return "$ERR_INVAL_ARG"
  fi
  if [[ "$(file_downloader::is_address "$address")" == false ]]; then
    err "address is not valid"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$file" ]]; then
    err "file is required"
    return "$ERR_INVAL_ARG"
  fi

  if utils::is_url "$address"; then
    file_downloader::http_download "$address" "$file"
    return "$?"
  fi

  local -r type="${address%%=*}"
  local -r url="${address#*=}"

  case "$type" in
  gdrive-big)
    file_downloader::gdrive_big_download "$url" "$file"
    ;;
  gdrive-small)
    file_downloader::gdrive_small_download "$url" "$file"
    ;;
  onedrive)
    file_downloader::onedrive_embed_download "$url" "$file"
    ;;
  magnet)
    file_downloader::magnet_link_download "$url" "$file"
    ;;
  http | https)
    file_downloader::http_download "$url" "$file"
    ;;
  *)
    err "unknown type"
    return "$ERR_INVAL_ARG"
    ;;
  esac
}
