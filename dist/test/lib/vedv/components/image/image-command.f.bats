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

# Tests for vedv image pull
@test "vedv image pull ,Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image pull $flag

    assert_success
    assert_output --partial "Usage:
vedv image pull [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv image pull ,Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv image pull $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv image pull ,Should fail With missing image_fqn" {

  run vedv image pull --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv image pull ,Should fail with invalid image fqn" {

  run vedv image pull --name 'my-alpine-14' 'admin_alpine/alpine-14'

  assert_failure
  assert_output "Invalid argument 'admin_alpine/alpine-14'"
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

  vedv image import "$TEST_OVA_FILE"

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

  vedv image import "$TEST_OVA_FILE"

  local -r image_name="$(vedv image list | head -n 1 | awk '{print $2}')"

  run vedv image rm "$image_name"

  assert_success
  assert_output --regexp '^[0-9]+\s*$'
}

@test "vedv image rm, Should do nothing without passing an image" {

  vedv image import "$TEST_OVA_FILE"
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

  vedv image import "$TEST_OVA_FILE"
  local -r image_name="$(vedv image list | head -n 1 | awk '{print $2}')"

  run vedv image remove-cache
  assert_success
  assert_output ''

  vedv image rm "$image_name"

  run vedv image remove-cache
  assert_success
  assert_output --regexp '^[0-9]{6,11}\s$'
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
# bats test_tags=only
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
  assert_output --partial 'image123'
}

@test "vedv image import --check-file -n image123, Should check the image file" {

  run vedv image import --check-file "${TEST_OVA_FILE}.sha256sum" --name image123 "$TEST_OVA_FILE"

  assert_success
  assert_output --partial 'image123'
}

@test "vedv image import -n image123 image_file, Should succeed" {

  run vedv image import -n 'image123' "$TEST_OVA_FILE"

  assert_success
  assert_output --partial 'image123'
}

@test "vedv image import -n image123 image_file, Should change the password" {

  export VEDV_CHANGE_PASSWORD_ON_IMPORT=true

  run vedv image import -n 'image123' "$TEST_OVA_FILE"

  assert_success
  assert_output --partial 'image123'

  local password
  password="$(VBoxManage getextradata 'image:image123|crc:3876716962|' user-data |
    grep -Po '\[password\]="\K[^"]+(?=")')"

  vedv container create -n 'container123' 'image123'

  vedv container start -w 'container123'

  local port
  port="$(VBoxManage getextradata 'container:container123|crc:1768101024|' user-data |
    grep -Po '\[ssh_port\]="\K[^"]+(?=")')"

  run sshpass -p "$password" \
    ssh -T -o 'ConnectTimeout=2' \
    -o 'UserKnownHostsFile=/dev/null' \
    -o 'PubkeyAuthentication=no' \
    -o 'StrictHostKeyChecking=no' \
    -o 'LogLevel=ERROR' \
    -p "$port" \
    "${TEST_SSH_USER}@${TEST_SSH_IP}" 'echo $USER'

  assert_success
  assert_output 'vedv'
}

# Tests for vedv image from-url

@test "vedv image from-url --help, Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image from-url $flag

    assert_success
    assert_output --partial "Usage:
vedv image from-url URL"
  done
}

@test "vedv image from-url --name, Should fail if missing image name" {

  run vedv image from-url --name

  assert_failure
  assert_output --partial 'No image name specified'
}

@test "vedv image from-url --name image123 ..., Should import the image file" {

  run vedv image from-url --name image123 "$TEST_OVA_URL"

  assert_success
  assert_output --partial 'image123'

  __run_cmd2_wrapper() {
    vedv image ls | grep 'image123'
  }

  run __run_cmd2_wrapper

  assert_success
  assert_output --regexp '.* image123'
}

@test "vedv image from-url -n image123 --checksum-url ..., Should check the image file" {

  run vedv image from-url -n image123 --checksum-url "$TEST_OVA_CHECKSUM" "$TEST_OVA_URL"

  assert_success
  assert_output --partial 'image123'

  __run_cmd2_wrapper() {
    vedv image ls | grep 'image123'
  }

  run __run_cmd2_wrapper

  assert_success
  assert_output --regexp '.* image123'
}

@test "vedv image from-url -n image123 --check ..., Should fail If checksum does not exist on remote server" {

  run vedv image from-url -n image123 --check "$TEST_OVA_URL"

  assert_failure
  assert_output --partial 'Failed to check sha256sum for image file'
}

# Tests for vedv image export
@test "vedv image export --help, Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image export $flag

    assert_success
    assert_output --partial "Usage:
vedv image export IMAGE FILE"
  done
}

@test "vedv image export --no-checksum, Should fail if missing image name or id" {

  run vedv image export --no-checksum

  assert_failure
  assert_output --partial "Missing argument 'IMAGE'"
}

@test "vedv image export --no-checksum image123, Should fail if missing FILE" {

  run vedv image export --no-checksum image123

  assert_failure
  assert_output --partial "Missing argument 'FILE'"
}

@test "vedv image export --no-checksum image123 FILE, Should succeed" {

  vedv image import --name image123 "$TEST_OVA_FILE"

  run vedv image export --no-checksum image123 "${TEST_IMAGE_TMP_DIR}/image123.ova"

  assert_success
  assert_output ""

  assert [ -f "${TEST_IMAGE_TMP_DIR}/image123.ova" ]
  assert [ ! -f "${TEST_IMAGE_TMP_DIR}/image123.ova.sha256sum" ]
}

@test "vedv image export image123 FILE, Should succeed" {

  vedv image import --name image123 "$TEST_OVA_FILE"

  run vedv image export image123 "${TEST_IMAGE_TMP_DIR}/image123.ova"

  assert_success
  assert_output ""

  assert [ -f "${TEST_IMAGE_TMP_DIR}/image123.ova" ]
  assert [ -f "${TEST_IMAGE_TMP_DIR}/image123.ova.sha256sum" ]

  run_cmd_wrapper() (
    cd "$TEST_IMAGE_TMP_DIR"
    sha256sum -c image123.ova.sha256sum
  )

  run run_cmd_wrapper

  assert_success
  assert_output --partial 'image123.ova: OK'
}

@test "vedv image build -t 'image123' ./cpus-memory.vedvfile, Should succeed" {
  run vedv image build --force \
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

  run vedv image build --force \
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

# Tests for vedv image push()
@test "vedv image push ,Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv image push $flag

    assert_success
    assert_output --partial "Usage:
vedv image push [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv image push, Should fail With missing image_name" {

  for opt in '-n' '--name'; do
    run vedv image push $opt

    assert_failure
    assert_output --partial "No image name specified"
  done
}

@test "vedv image push, Should fail With missing image_fqn" {
  run vedv image push --name 'alpine-14'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv image push, Should fail With invalid image_fqn" {
  run vedv image push 'admin/alpine-test/alpine-14'

  assert_failure
  assert_output "Invalid argument 'admin/alpine-test/alpine-14'
Failed to get image name from fqn: 'admin/alpine-test/alpine-14'"
}

@test "vedv image push, Should fail With invalid image_name" {
  run vedv image push --name '_invalid/name' 'admin@alpine-test/alpine-14'

  assert_failure
  assert_output "Invalid argument '_invalid/name'"
}

@test "vedv image push, Should fail With invalid image domain" {
  run vedv image push 'nextcloud123.loc/admin@alpine-test/alpine-14'

  assert_failure
  assert_output "Registry 'https://nextcloud123.loc' not found in credentials dict
Failed to get registry user
Error pushing image to registry"
}

# Tests for vedv image push-link
@test "vedv image push-link,  Should show help" {
  for flag in '' '-h' '--help'; do
    run vedv image push-link $flag

    assert_success
    assert_output --partial "Usage:
vedv image push-link [FLAGS] [OPTIONS] [DOMAIN/]USER@COLLECTION/NAME"
  done
}

@test "vedv image push-link,  Should fail With missing image_url arg" {
  run vedv image push-link --image-url

  assert_failure
  assert_output --partial "No image_url argument"
}

@test "vedv image push-link,  Should fail Without checksum_url" {
  run vedv image push-link --image-url "$TEST_OVA_URL"

  assert_failure
  assert_output --partial "No checksum_url specified"
}

@test "vedv image push-link,  Should fail With missing checksum_url arg" {
  run vedv image push-link \
    --image-url "$TEST_OVA_URL" --checksum-url

  assert_failure
  assert_output --partial "No checksum_url argument"
}

@test "vedv image push-link,  Should fail With missing image_fqn" {

  run vedv image push-link \
    --image-url "$TEST_OVA_URL" --checksum-url "$TEST_OVA_CHECKSUM_URL"

  assert_failure
  assert_output --partial "Missing argument 'IMAGE_FQN'"
}

@test "vedv image push-link --image-url, Should push an image link" {

  run vedv image push-link \
    --image-url "$TEST_OVA_URL" \
    --checksum-url "$TEST_OVA_CHECKSUM_URL" \
    'admin@alpine-test/alpine-14-link'

  assert_success
  assert_output ""
}
