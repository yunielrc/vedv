. "${DIST_PATH}/test/test_helper_base.bash"

. "${DIST_PATH}/lib/vedv/components/__base/vmobj-entity.bash"
. "${DIST_PATH}/lib/vedv/components/image/image-entity.bash"
. "${DIST_PATH}/lib/vedv/components/registry/nextcloud/registry-nextcloud-api-client.bash"
. "${DIST_PATH}/lib/vedv/components/registry/registry-service.bash"
. "${DIST_PATH}/lib/vedv/components/registry/registry-command.bash"

nextcloud_is_running() {
  multipass list | grep nextcloud-dev | grep Running -q
}

nextcloud_start() {
  if ! nextcloud_is_running; then
    multipass start nextcloud-dev
    sleep 10
  fi
}
