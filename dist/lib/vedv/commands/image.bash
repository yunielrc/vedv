#
# Manage images
#
# Process command line and call hypervisors
#

# VARIABLES

__VEDV_IMAGE_HYPERVISOR=''

# FUNCTIONS

# IMPL: Pull an image or a repository from a registry
vedv::image::pull() {
  echo 'vedv:image:pull'
  vedv::"$__VEDV_IMAGE_HYPERVISOR"::image::pull
}
vedv::image::__pull_run_cmd() {
  echo 'vedv:image:pull_run_cmd'
  vedv::image::pull
}

# IMPL: Build an image from a Vedvfile
vedv::image::build() {
  echo 'vedv:image:build'
  vedv::"$__VEDV_IMAGE_HYPERVISOR"::image::build
}
#
vedv::image::__build_run_cmd() {
  echo 'vedv:image:build_run_cmd'
  vedv::image::build
}

vedv::image::__help() {
  echo 'vedv::image::__help'
}

vedv::image::run_cmd() {

  case "${1:-}" in
  virtualbox)
    shift
    readonly __VEDV_IMAGE_HYPERVISOR='virtualbox'
    ;;
  qemu)
    shift
    readonly __VEDV_IMAGE_HYPERVISOR='qemu'
    ;;
  *)
    readonly __VEDV_IMAGE_HYPERVISOR='virtualbox'
    ;;
  esac

  [[ $# == 0 ]] && set -- '-h'

  if [[ "${1:-}" == @(-h|--help) ]]; then
    vedv::image::__help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    pull)
      shift
      vedv::image::__pull_run_cmd "$@"
      return $?
      ;;
    build)
      shift
      vedv::image::__build_run_cmd "$@"
      return $?
      ;;
    *)
      echo -e "Invalid parameter: ${1}\n" >&2
      vedv::image::__help
      return 10
      ;;
    esac
  done
}
