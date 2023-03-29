load test_helper

setup_file() {
  vedv::image_builder::constructor "$TEST_HYPERVISOR" \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD" \
    "$TEST_SSH_IP"

  export __VEDV_IMAGE_BUILDER_HYPERVISOR
  export __VEDV_IMAGE_BUILDER_SSH_USER
  export __VEDV_IMAGE_BUILDER_SSH_PASSWORD
  export __VEDV_IMAGE_BUILDER_SSH_IP

  vedv::image_service::constructor "$TEST_HYPERVISOR" "$TEST_SSH_IP"
  export __VEDV_IMAGE_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_SERVICE_SSH_IP

  vedv::image_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_ENTITY_HYPERVISOR
  vedv::image_cache_entity::constructor "$TEST_HYPERVISOR"
  export __VEDV_IMAGE_CACHE_ENTITY_HYPERVISOR
  vedv::image_vedvfile_service::constructor "$TEST_HYPERVISOR" false
  export __VEDV_IMAGE_VEDVFILE_SERVICE_HYPERVISOR
  export __VEDV_IMAGE_VEDVFILE_HADOLINT_ENABLED
  vedv::container_service::constructor "$TEST_HYPERVISOR"
  export __VEDV_CONTAINER_SERVICE_HYPERVISOR

}

teardown_file() {
  delete_vms_by_partial_vm_name "image-cache"
}

teardown() {
  delete_vms_by_partial_vm_name "$VM_TAG"
  delete_vms_by_partial_vm_name 'image:alpine-x86_64'
}

@test "vedv::image_builder::__build() Should succeed" {
  skip
  cd "dist/test/lib/vedv/components/image/fixtures"

  # Arrange
  local -r vedvfile="Vedvfile2"
  local -r image_name="image1"
  # Act
  run vedv::image_builder::__build "$vedvfile" "$image_name"
  # Assert
  assert_success
  assert_output ''
}
