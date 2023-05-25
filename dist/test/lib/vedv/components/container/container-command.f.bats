# shellcheck disable=SC2016
load test_helper

setup_file() {
  delete_vms_directory
  export VED_HADOLINT_CONFIG="$TEST_HADOLINT_CONFIG"
  VEDV_HADOLINT_ENABLED=false
  export VEDV_HADOLINT_ENABLED
}

teardown() {
  delete_vms_by_partial_vm_name 'container123'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'
}

# Tests for 'vedv container create'
@test "vedv container create, Should show help" {
  run vedv container create

  assert_success
  assert_output "Usage:
vedv container create [FLAGS] [OPTIONS] IMAGE

Create a new container

Flags:
  -h, --help            show help
  -s | --standalone     create a standalone container

Options:
  -n, --name <name>     assign a name to the container"
}

@test "vedv container create -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container create "$arg"

    assert_success
    assert_output "Usage:
vedv container create [FLAGS] [OPTIONS] IMAGE

Create a new container

Flags:
  -h, --help            show help
  -s | --standalone     create a standalone container

Options:
  -n, --name <name>     assign a name to the container"
  done
}

@test "vedv container create --name, Should throw error If --name is passed without value" {

  run vedv container create --name

  assert_failure
  assert_output "No container name specified

Usage:
vedv container create [FLAGS] [OPTIONS] IMAGE

Create a new container

Flags:
  -h, --help            show help
  -s | --standalone     create a standalone container

Options:
  -n, --name <name>     assign a name to the container"
}

@test "vedv container create --name container123, Should throw error Without passing an image" {

  run vedv container create --name 'container123'

  assert_failure
  assert_output --partial "Missing argument 'IMAGE'"
}

@test "vedv container create --name container123 image1 image2, Should throw error If passing more than one image" {

  run vedv container create --name 'container123' 'image1' 'image2'

  assert_failure
  assert_output "Image: 'image1' does not exist"
}

@test "vedv container create --name container123 image, Should create a container" {

  run vedv container create --name 'container123' "$TEST_OVA_FILE"

  assert_success
  assert_output "container123"
}

# Tests for 'vedv container start'
@test "vedv container start, Should show help" {
  run vedv container start

  assert_success
  assert_output --partial "Usage:
vedv container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help          show help
  -w, --wait          wait for SSH"
}

@test "vedv container start -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container start "$arg"

    assert_success
    assert_output --partial "Usage:
vedv container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help          show help
  -w, --wait          wait for SSH"
  done
}

@test "vedv container start container123a container123b, Should start containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"

  run vedv container start 'container123a' 'container123b'

  assert_success
  assert_output "375138354
339074491"
}

# Tests for 'vedv container rm'
@test "vedv container rm, Should show help" {
  run vedv container rm

  assert_success
  assert_output "Usage:
vedv container rm [FLAGS] CONTAINER [CONTAINER...]

Remove one or more running containers

Aliases:
  rm, remove

Flags:
  -h, --help          show help
  --force             force remove"
}

@test "vedv container rm -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container rm "$arg"

    assert_success
    assert_output "Usage:
vedv container rm [FLAGS] CONTAINER [CONTAINER...]

Remove one or more running containers

Aliases:
  rm, remove

Flags:
  -h, --help          show help
  --force             force remove"
  done
}

@test "vedv container rm container123a container123b, Should remove containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"

  run vedv container rm 'container123a' 'container123b'

  assert_success
  assert_output "375138354
339074491"
}

# Tests for 'vedv container stop'
@test "vedv container stop, Should show help" {
  run vedv container stop

  assert_success
  assert_output "Usage:
vedv container stop CONTAINER [CONTAINER...]

Stop one or more running containers

Flags:
  -h, --help          show help"
}

@test "vedv container stop -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container stop "$arg"

    assert_success
    assert_output "Usage:
vedv container stop CONTAINER [CONTAINER...]

Stop one or more running containers

Flags:
  -h, --help          show help"
  done
}

@test "vedv container stop container123a container123b, Should stop containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"
  vedv container start 'container123a' 'container123b'

  run vedv container stop 'container123a' 'container123b'

  assert_success
  assert_output "375138354
339074491"
}

# Tests for 'vedv container list'
@test "vedv container list -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container list "$arg"

    assert_success
    assert_output "Usage:
vedv container ls [FLAGS] [CONTAINER PARTIAL NAME]

List containers

Aliases:
  ls, ps, list

Flags:
  -h, --help      show help
  -a, --all       show all containers (default shows just running)"
  done
}

@test "vedv container list, Should show no containers" {
  run vedv container list

  assert_success
  assert_output ""
}

@test "vedv container list, Should list started containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"
  vedv container create --name 'container123c' "$TEST_OVA_FILE"
  vedv container start 'container123a' 'container123b'

  run vedv container list

  assert_success
  assert_output "375138354 container123a
339074491 container123b"
}

@test "vedv container list --all, Should list all containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"
  vedv container create --name 'container123c' "$TEST_OVA_FILE"
  vedv container start 'container123a' 'container123b'

  run vedv container list --all

  assert_success
  assert_output "375138354 container123a
339074491 container123b
367882556 container123c"
}

# Tests for vedv container login

@test "vedv container login container123a, Should login" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  __login() {
    vedv container login 'container123a' <<SSHEOF
      uname
SSHEOF
  }

  run __login

  assert_success
  assert_output --partial "Linux"
}

# Tests for vedv container login
@test "vedv container exec container123a uname, Should exec cmd" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec container123a uname

  assert_success
  assert_output --partial "Linux"
}

@test "vedv container exec container123a <<EOF, Should exec cmd" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  __exec() {
    vedv container exec container123a <<SSHEOF
        uname
SSHEOF
  }

  run __exec

  assert_success
  assert_success "Linux"
}

# bats test_tags=only
@test "vedv container copy container123a " {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  local -r src="$(mktemp)"
  echo "file123" >"$src"

  vedv container copy container123a "$src" /home/vedv/file123

  run vedv container exec container123a cat /home/vedv/file123

  assert_success
  assert_success "file123"
}
