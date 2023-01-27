# LOAD BAT LIBS
. "${BATS_LIBS_DIR}/bats-support/load.bash"
. "${BATS_LIBS_DIR}/bats-assert/load.bash"
# . "${BATS_LIBS_DIR}/bats-file/load.bash"

# SET BASH OPTIONS
set -euEo pipefail

# VARIABLES
VM_TAG="${BATS_TEST_FILENAME##*/}"
VM_TAG="${VM_TAG%'.bats'}"
readonly VM_TAG
export VM_TAG

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

delete_vms_by_partial_vm_name() {
  local -r vm_partial_name="$1"

  local -r vm_name_list="$(VBoxManage list vms | grep "$vm_partial_name" | cut -d' ' -f1 | sed 's/"//g')"

  if [[ -n "$vm_name_list" ]]; then
    for vm_name in $vm_name_list; do
      VBoxManage controlvm "$vm_name" poweroff &>/dev/null || :
      sleep 2
      VBoxManage unregistervm "$vm_name" --delete &>/dev/null || :
    done
  fi
}

# alias delete_vms_by_partial_vm_name='delete_vms_by_id_tag'
delete_vms_by_id_tag() { delete_vms_by_partial_vm_name "$@"; }

# shellcheck disable=SC2120
gen_vm_name() {
  local prefix="${1:-}"

  if [[ -z "$prefix" ]]; then
    prefix="$(petname)"
  fi
  echo "${prefix}-${VM_TAG}"
}

create_vm() {
  local -r vm_name="${1:-"$(gen_vm_name)"}"

  VBoxManage import "$TEST_OVA_FILE" --vsys 0 --vmname "$vm_name" &>/dev/null
  echo "$vm_name"
}

# cd "$BATS_TEST_DIRNAME" || exit
