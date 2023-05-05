load test_helper

setup_file() {
  vedv::image_builder::constructor \
    "$TEST_SSH_USER" \
    "$TEST_SSH_PASSWORD" \
    "$TEST_SSH_IP" \
    "$TEST_BASE_VEDVFILEIGNORE" \
    "$TEST_VEDVFILEIGNORE"

  export __VEDV_IMAGE_BUILDER_SSH_USER
  export __VEDV_IMAGE_BUILDER_SSH_PASSWORD
  export __VEDV_IMAGE_BUILDER_SSH_IP
  export __VEDV_IMAGE_BUILDER_BASE_VEDVFILEIGNORE_PATH
  export __VEDV_IMAGE_BUILDER_VEDVFILEIGNORE_PATH

  vedv::image_vedvfile_service::constructor \
    "$TEST_HADOLINT_CONFIG" \
    false \
    "$TEST_BASE_VEDVFILEIGNORE" \
    "$TEST_VEDVFILEIGNORE"

  export __VEDV_IMAGE_VEDVFILE_HADOLINT_CONFIG
  export __VEDV_IMAGE_VEDVFILE_HADOLINT_ENABLED
  export __VEDV_IMAGE_VEDVFILE_BASE_VEDVFILEIGNORE_PATH
  export __VEDV_IMAGE_VEDVFILE_VEDVFILEIGNORE_PATH
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
