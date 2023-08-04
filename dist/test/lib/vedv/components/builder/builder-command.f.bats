# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  delete_vms_directory
  export VED_HADOLINT_CONFIG="$TEST_HADOLINT_CONFIG"
  export VEDV_HADOLINT_ENABLED=false
  export VEDV_IMAGE_IMPORTED_DIR="$TEST_IMAGE_TMP_DIR"
}

teardown() {
  delete_vms_by_partial_vm_name 'container123'
  delete_vms_by_partial_vm_name 'container124'
  delete_vms_by_partial_vm_name 'image123'
  delete_vms_by_partial_vm_name 'container:'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'

  if [[ -d "$TEST_IMAGE_TMP_DIR" &&
    "$TEST_IMAGE_TMP_DIR" == */tmp/* ]]; then
    rm -rf "$TEST_IMAGE_TMP_DIR"
  fi
  [[ -d "$TEST_IMAGE_TMP_DIR" ]] ||
    mkdir -p "$TEST_IMAGE_TMP_DIR"
}

# Tests for 'vedv builder build'
@test "vedv builder build -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv builder build "$arg"

    assert_success
    assert_output --partial "Usage:
vedv builder build [FLAGS] [OPTIONS] VEDVFILE"
  done
}

@test "vedv builder build -n , Should fail if -n is passed without value" {

  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv builder build "$arg"
    # Assert
    assert_failure
    assert_output --partial "No image name specified"
  done
}
# bats test_tags=only
@test "vedv builder build, Should build the image from vedvfile" {
  cd "${BATS_TEST_DIRNAME}/fixtures/vedvfiles"

  run vedv builder build -t 'image123'

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}

@test "vedv builder build, Should build the image with SHELL command" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./shell.vedvfile

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'SHELL'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'

  run_cmd_wrapper() {
    vedv container exec 'container123' <<'EOF'
echo "shell_env: $SHELL"
echo -n 'shell_user: '
getent passwd | grep -e '/home' -e '^root:' | cut -d: -f7 | uniq
EOF
  }

  run run_cmd_wrapper

  assert_success
  assert_output "shell_env: /bin/sh
shell_user: /bin/sh"
}

@test "vedv builder build, Should build the image with USER" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./Vedvfile5

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'
created layer '.*' for command 'USER'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}

@test "vedv builder build , Should build with COPY --chown --chmod command" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./copy-chown-chmod.vedvfile

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'COPY'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'

  run vedv container exec --root container123 'ls -l /root && ls -l /root/homefs'

  assert_success
  assert_output --regexp "total .*
dr-xr-xr-x    3 vedv     vedv .* homefs
.*
total 2
dr-xr-xr-x    2 vedv     vedv .* d1
-r-xr-xr-x    1 vedv     vedv .* f2"
}

@test "vedv builder build --no-cache -t image123 Vedvfile2" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 --regexp "created layer '.*' for command 'FROM'"
  assert_line --index 1 --regexp "created layer '.*' for command 'RUN'"
  assert_line --index 2 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 3 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 4 "Build finished"
  assert_line --index 5 --regexp ".* image123"

  run vedv builder build -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 "Build finished"
  assert_line --index 1 --regexp ".* image123"

  __run_cmd_wrapper() {
    vedv builder build --no-wait --no-cache -t 'image123' ./Vedvfile2 2>/dev/null
  }

  run __run_cmd_wrapper

  assert_success
  assert_line --index 0 --regexp "created layer '.*' for command 'RUN'"
  assert_line --index 1 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 2 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 3 "Build finished"
  assert_line --index 4 --regexp ".* image123"
}

@test "vedv builder build -t image123 Vedvfile2 , Should fail 2nd build without --force because the image has containers" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./Vedvfile2

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'
  vedv container create -n 'container124' 'image123'

  run vedv builder build -t 'image123' ./Vedvfile2

  assert_failure
  assert_output "The image 'image123' has containers, you need to force the build, the containers will be removed."
}

@test "vedv builder build --force -t image123 Vedvfile2, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./Vedvfile2

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'
  vedv container create -n 'container124' 'image123'

  run vedv builder build --force -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 "Build finished"
  assert_line --index 1 --regexp ".* image123"
}

@test "vedv builder build -t 'image123' ./expose.vedvfile, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./expose.vedvfile

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'

  run vedv container exec --root 'container123' vedv-getexpose_ports

  assert_success
  assert_output "22/udp
23/tcp
443/tcp
444/udp
80/tcp
8080/tcp
8081/udp
81/tcp"
}

@test "vedv builder build -t image123 ./varsub.vedvfile, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv builder build -t 'image123' ./varsub.vedvfile

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'ENV'
created layer '.*' for command 'ENV'
created layer '.*' for command 'RUN'
created layer '.*' for command 'RUN'
created layer '.*' for command 'ENV'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'ENV'
created layer '.*' for command 'ENV'
created layer '.*' for command 'ENV'
created layer '.*' for command 'WORKDIR'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'

Build finished
.* image1"
}

@test "vedv builder build -t 'image123' ./cpus-memory.vedvfile, Should succeed" {
  run vedv builder build --force \
    -t 'image123' \
    'dist/test/lib/vedv/components/image/fixtures/vedvfiles/cpus-memory.vedvfile2'

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'SYSTEM'
created layer '.*' for command 'SYSTEM'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'

  run vedv container exec --root 'container123' vedv-getcpus

  assert_success
  assert_output "5"

  run vedv container exec --root 'container123' vedv-getmemory

  assert_success
  assert_output "868"

  run vedv builder build --force \
    -t 'image123' \
    'dist/test/lib/vedv/components/image/fixtures/vedvfiles/cpus-memory.vedvfile'

  assert_success
  assert_output --regexp "

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'

  run vedv container exec --root 'container123' vedv-getcpus

  assert_success
  assert_output "3"

  run vedv container exec --root 'container123' vedv-getmemory

  assert_success
  assert_output "740"
}
