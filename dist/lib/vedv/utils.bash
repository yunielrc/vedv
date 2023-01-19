# shellcheck disable=SC2034

readonly ERR_NOFILE=64  # file doesn't exist
readonly ERR_NOTIMPL=70 # not implemented

err() {
  echo "$*" >&2
}

dierr() {
  err "$1"
  exit "$2"
}

inf() {
  echo "$*"
}
