# LOAD BAT LIBS
. "${BATS_LIBS_DIR}/bats-support/load.bash"
. "${BATS_LIBS_DIR}/bats-assert/load.bash"
# . "${BATS_LIBS_DIR}/bats-file/load.bash"

# SET BASH OPTIONS
set -euEo pipefail

# VARIABLES
__test_unit="testunit:${BATS_TEST_FILENAME##*/}"
__test_unit="${__test_unit%'.bats'}"
readonly VM_ID_TAG="${__test_unit,,}-$(echo "${__test_unit,,}" | cksum | cut -d' ' -f1)"
export VM_ID_TAG

# LOAD COMMON PROJECT LIBS
. "${DIST_PATH}/lib/vedv/utils.bash"

# DOWNLOAD OVA FILE
if [[ ! -f "$TEST_OVA_FILE" ]]; then
  (
    [[ ! -d "${TEST_OVA_FILE%/*}" ]] &&
      mkdir -p "${TEST_OVA_FILE%/*}"

    cd "${TEST_OVA_FILE%/*}" || exit

    wget -O "${TEST_OVA_FILE##*/}" "https://onedrive.live.com/download?cid=DBA0B75F07574EAA&resid=DBA0B75F07574EAA%21118&authkey=APpbuFTG_6LHwb4"

    wget -O "${TEST_OVA_FILE##*/}.sha256" "https://onedrive.live.com/download?cid=DBA0B75F07574EAA&resid=DBA0B75F07574EAA%21121&authkey=AIHWIMDKgelPfmU"

    sha256sum -c "${TEST_OVA_FILE##*/}.sha256"
  )
fi

# HELPER FUNCTIONS

delete_vms_by_id_tag() {
  local -r vm_id_tag="$1"

  local -r vm_name_list="$(VBoxManage list vms | grep "$vm_id_tag" | cut -d' ' -f1 | sed 's/"//g')"

  if [[ -n "$vm_name_list" ]]; then
    for vm_name in $vm_name_list; do
      VBoxManage unregistervm "$vm_name" --delete
    done
  fi
}

# shellcheck disable=SC2120
gen_vm_name() {
  echo "${VM_ID_TAG:-"$1"}-alpine-x86_64-${RANDOM}"
}

gen_vm_clone_name() {
  echo "${VM_ID_TAG:-"$1"}-clone-alpine-x86_64-${RANDOM}"
}

create_vm() {
  local -r vm_name="${1:-"$(gen_vm_name)"}"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$vm_name" &>/dev/null

  echo "$vm_name"
}

delete_all_test_unit_vms() {
  delete_vms_by_id_tag "${VM_ID_TAG:-"$1"}-clone"
  delete_vms_by_id_tag "${VM_ID_TAG:-"$1"}"
}

# cd "$BATS_TEST_DIRNAME" || exit
