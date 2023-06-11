# shellcheck disable=SC2016,SC2317
load test_helper

setup_file() {
  delete_vms_directory
  export VED_HADOLINT_CONFIG="$TEST_HADOLINT_CONFIG"
  export VEDV_HADOLINT_ENABLED=false
  export VEDV_IMAGE_CACHE_DIR="$TEST_IMAGE_CACHE_DIR"
}

teardown() {
  delete_vms_by_partial_vm_name 'container123'
  delete_vms_by_partial_vm_name 'container124'
  delete_vms_by_partial_vm_name 'image123'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'
}

# Tests for 'vedv image pull'
@test "vedv image pull, Should show help" {

  run vedv image pull

  assert_success
  assert_output "Usage:
vedv image pull IMAGE_FILE

Pull an image from a file"
}

@test "vedv image pull -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image pull "$arg"

    assert_success
    assert_output "Usage:
vedv image pull IMAGE_FILE

Pull an image from a file"
  done
}

@test "vedv image pull, Should pull the image" {

  run vedv image pull "$TEST_OVA_FILE"

  local -r image_name="$(vedv image list | head -n 1 | awk '{print $2}')"

  assert_success
  assert_output "$image_name"
}

@test "vedv image pull, Should show error with invalid argument" {

  run vedv image pull "$TEST_OVA_FILE" 'invalid_arg'

  assert_failure "$ERR_INVAL_ARG"
  assert_output 'Invalid argument: invalid_arg

Usage:
vedv image pull IMAGE_FILE

Pull an image from a file'
}

# Tests for 'vedv image list'
@test "vedv image list --help, Should show list help" {
  for arg in '-h' '--help'; do
    run vedv image list "$arg"

    assert_success
    assert_output "Usage:
vedv image ls

List images

Aliases:
  ls, list"
  done
}

@test "vedv image list, Should list nothing" {

  run vedv image list

  assert_success
  assert_output ''
}

@test "vedv image list, Should list images" {

  vedv image pull "$TEST_OVA_FILE"

  run vedv image list

  assert_success
  assert_output --regexp '^[[:digit:]]+ .+'
}

# Tests for 'vedv image rm'
@test "vedv image rm -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image rm "$arg"

    assert_success
    assert_output "Usage:
vedv image rm [FLAGS] IMAGE [IMAGE...]

Remove one or more images

Aliases:
  rm, remove

Flags:
  -h, --help    show help
  --force       force remove"
  done
}

@test "vedv image rm, Should remove the image" {

  vedv image pull "$TEST_OVA_FILE"

  local -r image_name="$(vedv image list | head -n 1 | awk '{print $2}')"

  run vedv image rm "$image_name"

  assert_success
  assert_output --regexp '^[0-9]+\s*$'
}

@test "vedv image rm, Should do nothing without passing an image" {

  vedv image pull "$TEST_OVA_FILE"
  run vedv image rm

  assert_success
  assert_output 'Usage:
vedv image rm [FLAGS] IMAGE [IMAGE...]

Remove one or more images

Aliases:
  rm, remove

Flags:
  -h, --help    show help
  --force       force remove'
}

# Tests for 'vedv image remove-cache'
@test "vedv image remove-cache -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image remove-cache "$arg"

    assert_success
    assert_output "Usage:
vedv image remove-cache

Remove unused cache images"
  done
}

@test "vedv image remove-cache, Should remove unused caches" {

  vedv image pull "$TEST_OVA_FILE"
  local -r image_name="$(vedv image list | head -n 1 | awk '{print $2}')"

  run vedv image remove-cache
  assert_success
  assert_output ''

  vedv image rm "$image_name"

  run vedv image remove-cache
  assert_success
  assert_output --regexp '^[0-9]{10,11}\s$'
}

# Tests for 'vedv image build'

@test "vedv image build -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv image build "$arg"

    assert_success
    assert_output --partial "Usage:
vedv image build [FLAGS] [OPTIONS] VEDVFILE"
  done
}

@test "vedv image build -n , Should fail if -n is passed without value" {

  for arg in '-n' '--name' '-t'; do
    # Act
    run vedv image build "$arg"
    # Assert
    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv image build, Should build the image from vedvfile" {
  cd "${BATS_TEST_DIRNAME}/fixtures/vedvfiles"

  run vedv image build -t 'image123'

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'COPY'
created layer '.*' for command 'RUN'

Build finished
.* image123"
}

@test "vedv image build, Should build the image with SHELL command" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./shell.vedvfile

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

@test "vedv image build, Should build the image with USER" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./Vedvfile5

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

@test "vedv image build , Should build with COPY --chown --chmod command" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./copy-chown-chmod.vedvfile

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

@test "vedv image build --no-cache -t image123 Vedvfile2" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 --regexp "created layer '.*' for command 'FROM'"
  assert_line --index 1 --regexp "created layer '.*' for command 'RUN'"
  assert_line --index 2 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 3 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 4 "Build finished"
  assert_line --index 5 --regexp ".* image123"

  run vedv image build -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 "Build finished"
  assert_line --index 1 --regexp ".* image123"

  __run_cmd_wrapper() {
    vedv image build --no-wait --no-cache -t 'image123' ./Vedvfile2 2>/dev/null
  }

  run __run_cmd_wrapper

  assert_success
  assert_line --index 0 --regexp "created layer '.*' for command 'RUN'"
  assert_line --index 1 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 2 --regexp "created layer '.*' for command 'COPY'"
  assert_line --index 3 "Build finished"
  assert_line --index 4 --regexp ".* image123"
}

@test "vedv image build -t image123 Vedvfile2 , Should fail 2nd build without --force because the image has containers" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./Vedvfile2

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'
  vedv container create -n 'container124' 'image123'

  run vedv image build -t 'image123' ./Vedvfile2

  assert_failure
  assert_output "The image 'image123' has containers, you need to force the build, the containers will be removed."
}

@test "vedv image build --force -t image123 Vedvfile2, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./Vedvfile2

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'RUN'
created layer '.*' for command 'COPY'
created layer '.*' for command 'COPY'

Build finished
.* image123"

  vedv container create -n 'container123' 'image123'
  vedv container create -n 'container124' 'image123'

  run vedv image build --force -t 'image123' ./Vedvfile2

  assert_success
  assert_line --index 0 "Build finished"
  assert_line --index 1 --regexp ".* image123"
}

@test "vedv image build -t 'image123' ./expose.vedvfile, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./expose.vedvfile

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

# Tests for vedv image list-exposed-ports ..

@test "vedv image list-exposed-ports image123, Should succeed" {

  run vedv image build \
    -t 'image123' \
    "${BATS_TEST_DIRNAME}/fixtures/expose1.vedvfile"

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'

Build finished
.* image123"

  run vedv image list-exposed-ports 'image123'

  assert_success
  assert_output '2300/tcp
3000/udp
5000/tcp
8080/tcp
8081/udp'
}

@test "vedv image build -t image123 ./varsub.vedvfile, Should succeed" {
  cd "${BATS_TEST_DIRNAME}/fixtures"

  run vedv image build -t 'image123' ./varsub.vedvfile

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

# Tests for vedv image import
@test "vedv image import --help, Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image import $flag

    assert_success
    assert_output --partial "Usage:
vedv image import IMAGE_FILE"
  done
}

@test "vedv image import --name, Should fail if missing image name" {

  run vedv image import --name

  assert_failure
  assert_output --partial 'No image name specified'
}

@test "vedv image import --check -n image123, Should check the image file without argument value" {

  run vedv image import --check --name image123 "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}

@test "vedv image import --check-file -n image123, Should check the image file" {

  run vedv image import --check-file "${TEST_OVA_FILE}.sha256sum" --name image123 "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}
@test "vedv image import -n image123 image_file, Should succeed" {

  run vedv image import -n 'image123' "$TEST_OVA_FILE"

  assert_success
  assert_output 'image123'
}

# Tests for vedv image from-url
# bats test_tags=only
@test "vedv image from-url --help, Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image from-url $flag

    assert_success
    assert_output --partial "Usage:
vedv image from-url URL"
  done
}
# bats test_tags=only
@test "vedv image from-url --name, Should fail if missing image name" {

  run vedv image from-url --name

  assert_failure
  assert_output --partial 'No image name specified'
}
# bats test_tags=only
@test "vedv image from-url --name image123 ..., Should import the image file" {

  run vedv image from-url --name image123 "$TEST_OVA_URL"

  assert_success
  assert_output 'image123'

  __run_cmd2_wrapper() {
    vedv image ls | grep 'image123'
  }

  run __run_cmd2_wrapper

  assert_success
  assert_output --regexp '.* image123'
}
# bats test_tags=only
@test "vedv image from-url -n image123 --checksum-url ..., Should check the image file" {

  run vedv image from-url -n image123 --checksum-url "$TEST_OVA_CHECKSUM" "$TEST_OVA_URL"

  assert_success
  assert_output 'image123'

  __run_cmd2_wrapper() {
    vedv image ls | grep 'image123'
  }

  run __run_cmd2_wrapper

  assert_success
  assert_output --regexp '.* image123'
}
# bats test_tags=only
@test "vedv image from-url -n image123 --check ..., Should fail If checksum does not exist on remote server" {

  run vedv image from-url --no-cache -n image123 --check "$TEST_OVA_URL"

  assert_failure
  assert_output --regexp 'Bad checksum file format: .*/checksum.sha256sum'
}
