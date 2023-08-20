#
# Utils
#

#
# Wait for http service to be ready
#
# Arguments:
#   url          string    http service url
#   wait_time    int       wait time in seconds
#   curl_options string    curl options
#
# Returns:
#   0 if http service is ready, 1 otherwise
#
utils::wait_for_http_service() {
  local -r url="$1"
  local -r wait_time="${2:-240}"
  local -r curl_options="${3:-}"

  echo '>>> Waiting for http service to be ready...'

  if [[ -n "$curl_options" ]]; then
    curl() {
      command curl "$curl_options" "$@"
    }
  fi

  local -i i=0
  local -ri max="$wait_time"

  while
    ! curl --connect-timeout 2 \
      --location --fail \
      --silent --head "$url" |
      grep --quiet 'HTTP/.* 200'
  do

    if [[ $i -ge $max ]]; then
      echo "Timeout waiting for http service on '${url}'"
      return 1
    fi

    sleep 1
    ((i += 1))
  done

  echo -e '>>> Waiting for http service to be ready. DONE\n'
}

#
# Wait for docker container to be ready
#
# Arguments:
#   container_name    string    container name
#   wait_time    int       wait time in seconds
#
# Returns:
#   0 if http service is ready, 1 otherwise
#
utils::wait_for_docker_container() {
  local -r container_name="$1"
  local -r wait_time="${2:-240}"
  # validate arguments
  if [[ -z "$container_name" ]]; then
    echo "Argument 'container_name' is required" >&2
    return 1
  fi

  echo '>>> Waiting for docker container to be ready...'

  local -i i=0
  local -ri max="$wait_time"

  while [[ -z "$(docker container ls -qaf "name=${container_name}")" ]]; do

    if [[ $i -ge $max ]]; then
      echo "Timeout waiting for docker container to be ready"
      return 1
    fi

    sleep 1
    ((i += 1))
  done

  echo -e '>>> Waiting for docker container to be ready. DONE\n'
}

#
# Load user data
#
# Arguments:
#   user_name  string  user name
#   user_pass  string  user password
#   domain     string  http service domain
#   data_dir   string  data directory
#
# Returns:
#   0 if user data is loaded, 1 otherwise
#
utils::upload_user_data() {
  local -r user_name="$1"
  local -r user_pass="$2"
  local -r domain="$3"
  local -r data_dir="$4"

  echo '>>> Loading user data...'

  local -r mount_dir="$(mktemp -d)"

  local -ri _uid="$(id -u)"
  local -ri _gid="$(id -g)"

  echo -e "${user_name}\n${user_pass}\n" |
    sudo mount -t davfs -o uid=$_uid,gid=$_gid \
      "https://${domain}/remote.php/dav/files/${user_name}" "$mount_dir"

  cp -r "$data_dir"/* "$mount_dir"

  sudo umount "$mount_dir" || :

  echo -e '>>> Loading user data. DONE\n'
}
