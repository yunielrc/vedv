# shellcheck disable=SC2016,SC2086
load test_helper

setup_file() {
  # delete_vms_directory
  vedv::hypervisor::constructor
  export __VEDV_HYPERVISOR_FRONTEND
}

teardown() {
  delete_vms_by_partial_vm_name 'container123'
  delete_vms_by_partial_vm_name 'container:'
  delete_vms_by_partial_vm_name 'image:'
  delete_vms_by_partial_vm_name 'image-cache|'
}

# Tests for 'vedv container create'

@test "vedv container create -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container create "$arg"

    assert_success
    assert_output --partial "Usage:
vedv container create [FLAGS] [OPTIONS] IMAGE_NAME|URL|FILE|FQN

Create a new container"
  done
}

@test "vedv container create --name, Should throw error If --name is passed without value" {

  run vedv container create --name

  assert_failure
  assert_output --partial "No container name specified"
}

@test "vedv container create --name, Should throw error Without container name value" {

  run vedv container create --name

  assert_failure
  assert_output --partial "No container name specified"
}

@test "vedv container create --name container123 --publish, Should throw error Without publish port value" {

  run vedv container create --name 'container123' --publish

  assert_failure
  assert_output --partial "No publish port specified"
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
  assert_output --partial "container123"
}

@test "vedv container create --name container123 -p 8080:80/tcp -p 8082:82 -p 8081 -p 81/udp image, Should create a container" {
  local -r container_id='container123'

  run vedv container create --name "$container_id" -p 8080:80/tcp -p 8082:82 -p 8081 -p 81/udp "$TEST_OVA_FILE"

  assert_success
  assert_output --partial "container123"

  local container_vm_name="$(vedv::hypervisor::list_vms_by_partial_name "container:${container_id}|" | head -n 1)"

  run vedv::hypervisor::get_forwarding_ports "$container_vm_name"

  assert_success
  assert_output "2150172608,tcp,,8082,,82
2227371250,udp,,81,,81
2250533131,tcp,,8081,,8081
3074115300,tcp,,8080,,80
nc,tcp,,4444,,4444
test-ssh,tcp,,2022,,22"
}

@test "vedv container create --name container123 --cpus, Should fail Without cpu value" {
  local -r container_id='container123'

  run vedv container create --name "$container_id" --cpus

  assert_failure
  assert_output --partial "No cpus specified"
}

@test "vedv container create --name container123 --cpus, Should fail Without memory value" {
  local -r container_id='container123'

  run vedv container create \
    --name "$container_id" --cpus 4 --memory

  assert_failure
  assert_output --partial "No memory specified"
}

@test "vedv container create --name container123 --cpus, Should succeed" {
  local -r container_id='container123'

  run vedv container create \
    --name "$container_id" --cpus 4 --memory 1024 "$TEST_OVA_FILE"

  assert_success
  assert_output "1768101024 container123"
}

# Tests for 'vedv container start'
@test "vedv container start, Should show help" {
  run vedv container start

  assert_success
  assert_output --partial "Usage:
vedv container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help    show help
  -w, --wait    wait for SSH"
}

@test "vedv container start -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container start "$arg"

    assert_success
    assert_output --partial "Usage:
vedv container start [FLAGS] CONTAINER [CONTAINER...]

Start one or more stopped containers

Flags:
  -h, --help    show help
  -w, --wait    wait for SSH"
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
  -h, --help    show help
  --force       force remove"
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
  -h, --help    show help
  --force       force remove"
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
  assert_output --partial "Usage:
vedv container stop [FLAGS] CONTAINER [CONTAINER...]"
}

@test "vedv container stop -h , Should show help" {

  for arg in '-h' '--help'; do
    run vedv container stop "$arg"

    assert_success
    assert_output --partial "Usage:
vedv container stop [FLAGS] CONTAINER [CONTAINER...]"
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
  -h, --help    show help
  -a, --all     show all containers (default shows just running)"
  done
}

@test "vedv container list, Should show no containers" {
  run vedv container list

  assert_success
  assert_output ""
}
# bats test_tags=only
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

# Tests for vedv container exec

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

@test "vedv container exec --root container123a id" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec --root container123a id

  assert_success
  assert_output --partial "uid=0(root) gid=0(root)"
}

@test "vedv container exec container123a --workdir /etc" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec --workdir /etc container123a pwd

  assert_success
  assert_output "/etc"
}

@test "vedv container exec container123a --env 'E1=ve1 E2=ve2'" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec --env 'E1=ve1 E2=ve2' container123a 'echo "$E1 $E2 $USER"'

  assert_success
  assert_output "ve1 ve2 vedv"
}

@test "vedv container exec container123a --env 'E1=\"ve1 ef\"' --env E2=ve2" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec --env 'E1="ve1 ef"' --env E2=ve2 container123a 'echo "E1:${E1} E2:${E2} U:${USER}"'

  assert_success
  assert_output "E1:ve1 ef E2:ve2 U:vedv"
}

@test "vedv container exec container123a --shell bash 'echo \$0'" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  run vedv container exec --shell bash container123a 'echo $0'

  assert_success
  assert_output "bash"
}

# Tests for vedv container copy
@test "vedv container copy container123a src /home/vedv/file123" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  local -r src="$(mktemp)"
  echo "file123" >"$src"

  vedv container copy container123a "$src" /home/vedv/file123

  run vedv container exec container123a cat /home/vedv/file123

  assert_success
  assert_success "file123"
}

@test "vedv container copy container123a src dest " {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  local -r src="$(mktemp)"
  echo "file123" >"$src"

  vedv container copy --root container123a "$src" /home/vedv/file123

  run vedv container exec --root container123a ls -l /home/vedv/file123

  assert_success
  assert_output --partial "-rw-------    1 root     root"

  vedv container copy --root --chown vedv:vedv --chmod 440 container123a "$src" /home/vedv/file124

  run vedv container exec --root container123a ls -l /home/vedv/file124

  assert_success
  assert_output --partial "-r--r-----    1 vedv     vedv"
}

@test "vedv container copy container123a src dest with vedvfileignore" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container start --wait 'container123a'

  local -r dir="$(mktemp -d)"

  cd "$dir"
  touch "${dir}/file1" "${dir}/file2"
  echo file1 >.vedvfileignore

  vedv container exec container123a mkdir /home/vedv/dir

  vedv container copy container123a "${dir}/" /home/vedv/dir

  run vedv container exec container123a ls -1a /home/vedv/dir

  assert_success
  assert_output ".
..
.vedvfileignore
file2"

  vedv container copy --no-vedvfileignore container123a "${dir}/" /home/vedv/dir

  run vedv container exec container123a ls -1a /home/vedv/dir

  assert_success
  assert_output ".
..
.vedvfileignore
file1
file2"
}

# Tests for vedv container create --publish-all ...

@test "vedv container create --publish-all --name container123 image, Should succeed" {
  local -r container_id='container123'

  run vedv image build -t 'image123' "${BATS_TEST_DIRNAME}/fixtures/expose.vedvfile"

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'POWEROFF'

Build finished
.* image123"

  run vedv container create --publish-all --name "$container_id" 'image123'

  assert_success
  assert_output --partial "$container_id"

  local -r container_vm_name="$(vedv::hypervisor::list_vms_by_partial_name "container:${container_id}|" | head -n 1)"

  run vedv::hypervisor::get_forwarding_ports "$container_vm_name"

  assert_success
  assert_output --regexp '.*,udp,,.*,,3000'
  assert_output --regexp '.*,tcp,,.*,,8080'
  assert_output --regexp '.*,tcp,,.*,,5000'
  assert_output --regexp '.*,udp,,.*,,8081'
  assert_output --regexp '.*,tcp,,.*,,2300'
}

# Tests for vedv container list-ports ..

@test "vedv container list-ports container123" {
  local -r container_id='container123'

  run vedv image build \
    -t 'image123' \
    "${BATS_TEST_DIRNAME}/fixtures/expose.vedvfile"

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'POWEROFF'

Build finished
.* image123"

  run vedv container create \
    -p 30000:3000/udp \
    -p 8080 \
    -p 50000:5000 \
    -p 8081/udp \
    -p 23000:2300/tcp \
    --name "$container_id" \
    'image123'

  assert_success
  assert_output --partial "$container_id"

  run vedv container list-ports "$container_id"

  assert_success
  assert_output --partial '30000/udp -> 3000'
  assert_output --partial '8080/tcp -> 8080'
  assert_output --partial '50000/tcp -> 5000'
  assert_output --partial '8081/udp -> 8081'
  assert_output --partial '23000/tcp -> 2300'
}

# Tests for vedv container list-exposed-ports ..

@test "vedv container list-exposed-ports container123,  Should succeed" {
  local -r container_id='container123'

  run vedv image build \
    -t 'image123' \
    "${BATS_TEST_DIRNAME}/fixtures/expose.vedvfile"

  assert_success
  assert_output --regexp "created layer '.*' for command 'FROM'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'EXPOSE'
created layer '.*' for command 'POWEROFF'

Build finished
.* image123"

  run vedv container create --name "$container_id" 'image123'

  assert_success
  assert_output --partial "$container_id"

  run vedv container list-exposed-ports "$container_id"

  assert_success
  assert_output '2300/tcp
3000/udp
5000/tcp
8080/tcp
8081/udp'
}

# Tests for 'vedv container kill'
@test "vedv container kill, Should show help" {

  for flag in '' '-h' '--help'; do
    run vedv container kill $flag

    assert_success
    assert_output --partial 'vedv container kill [FLAGS] CONTAINER [CONTAINER...]'
  done
}

@test "vedv container kill container123a container123b, Should kill containers" {

  vedv container create --name 'container123a' "$TEST_OVA_FILE"
  vedv container create --name 'container123b' "$TEST_OVA_FILE"

  vedv container start --wait 'container123a' 'container123b'

  run vedv container kill 'container123a' 'container123b'

  assert_success
  assert_output "375138354
339074491"
}

# Tests for vedv::container_command::__restart()
@test "vedv container restart -h, Should show help With flags '-h|--help'" {

  for flag in '' '-h' '--help'; do
    run vedv container restart $flag

    assert_success
    assert_output --partial 'vedv container restart [FLAGS] CONTAINER [CONTAINER...]'
  done
}

@test "vedv container restart --wait ct1 ct2 ct3, Should succeed" {
  local -r container_names_or_ids='ct1 ct2 ct3'

  vedv container create --name 'ct1' "$TEST_OVA_FILE"
  vedv container create --name 'ct2' "$TEST_OVA_FILE"
  vedv container create --name 'ct3' "$TEST_OVA_FILE"

  vedv container start --wait 'ct1' 'ct2' 'ct3'

  run vedv container restart \
    --wait $container_names_or_ids

  assert_success
  assert_output "2410003725
2378975364
2350179331"
}
