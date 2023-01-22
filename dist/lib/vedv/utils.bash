# shellcheck disable=SC2034

readonly ERR_NOFILE=64             # file doesn't exist
readonly ERR_INVAL_ARG=69          # invalid argument
readonly ERR_NOTIMPL=70            # function not implemented
readonly ERR_VM_EXIST=80           # vm exist
readonly ERR_NO_START_CONTAINER=81 # error starting container vm

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
