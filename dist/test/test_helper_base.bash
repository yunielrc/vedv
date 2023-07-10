# LOAD BAT LIBS
. "${BATS_LIBS_DIR}/bash-bats-support-git/load.bash"
. "${BATS_LIBS_DIR}/bash-bats-assert-git/load.bash"
# . "${BATS_LIBS_DIR}/bats-file/load.bash"

# SET BASH OPTIONS
set -eu

# VARIABLES
VM_TAG="${BATS_TEST_FILENAME##*/}"
VM_TAG="${VM_TAG%'.bats'}"
readonly VM_TAG
export VM_TAG

vedv() {
  "${DIST_PATH}/usr/bin/vedv" "$@"
}
export -f vedv
# LOAD COMMON PROJECT LIBS
. "${DIST_PATH}/lib/vedv/utils.bash"

# DOWNLOAD OVA FILE
if [[ ! -f "$TEST_OVA_FILE" ]]; then
  (
    # TODO: change if [[ $# == 0 ]]; then; set -- '-h'; fi
    [[ ! -d "${TEST_OVA_FILE%/*}" ]] &&
      mkdir -p "${TEST_OVA_FILE%/*}"

    cd "${TEST_OVA_FILE%/*}" || exit
    wget -O "${TEST_OVA_FILE##*/}" "$TEST_OVA_URL"
    wget -O "${TEST_OVA_FILE##*/}.sha256sum" "$TEST_OVA_CHECKSUM"

    sha256sum -c "${TEST_OVA_FILE##*/}.sha256sum"
  )
fi

# HELPER FUNCTIONS

__remove_inaccessible_hdds() {
  local -ri calls="${1:-0}"

  if [[ "$calls" -gt 10 ]]; then
    err "Failed to remove inaccessible hdds after 10 attempts"
    return "$ERR_VIRTUALBOX_OPERATION"
  fi

  local hdds
  hdds="$(VBoxManage list hdds)" || {
    err "Failed to get hdds list"
    return "$ERR_VIRTUALBOX_OPERATION"
  }
  readonly hdds

  local -r inaccessible_hdds="$(echo "$hdds" | pcregrep -M 'UUID:.*\nParent UUID:.*\nState:\s+inaccessible' | grep '^UUID:' | cut -d':' -f2 | sed 's/^\s\+//')"

  if [[ -n "$inaccessible_hdds" ]]; then
    local there_is_error=false

    while IFS= read -r hdd_uuid; do
      VBoxManage closemedium disk "$hdd_uuid" --delete &>/dev/null || {
        there_is_error=true
        err "Failed to remove inaccessible hdd '${hdd_uuid}'"
        continue
      }
      echo "$hdd_uuid"
    done <<<"$inaccessible_hdds"

    if [[ "$there_is_error" == true ]]; then
      __remove_inaccessible_hdds "$((calls + 1))"
    fi
  fi
}

delete_vms_directory() {
  delete_vms_by_partial_vm_name

  local vbox_sysprops
  vbox_sysprops="$(VBoxManage list systemproperties)" || {
    echo "Failed to get system properties for '${vm_name}'" >&2
    return 1
  }
  readonly vbox_sysprops

  local -r all_vms_dir="$(echo "$vbox_sysprops" | grep -i 'Default machine folder:' | grep -o '/.*$')"

  if [[ ! -d "$all_vms_dir" ]]; then
    echo "Directory '$all_vms_dir' does not exist"
    return 0
  fi

  if ! grep -q 'VirtualBox VMs' <<<"$all_vms_dir"; then
    echo "Directory '$all_vms_dir' is not a VirtualBox VMs directory" >&2
    return 1
  fi

  if [[ -d "$all_vms_dir" ]]; then
    rm -rf "$all_vms_dir"
  fi

  __remove_inaccessible_hdds 2>/dev/null || :
}

delete_vms_by_partial_vm_name() {
  local -r vm_partial_name="${1:-'.*'}"

  local -r vm_name_list="$(VBoxManage list vms | grep "$vm_partial_name" | cut -d' ' -f1 | sed 's/"//g')"

  if [[ -n "$vm_name_list" ]]; then
    for vm_name in $vm_name_list; do
      VBoxManage controlvm "$vm_name" poweroff 2>/dev/null || :
      sleep 2

      local vm_info
      vm_info="$(VBoxManage showvminfo "$vm_name" --machinereadable)" || {
        echo "Failed to get vm info for '${vm_name}'" >&2
        continue
      }

      local vm_cfg="$(echo "$vm_info" | grep -o '^CfgFile=.*' | grep -o '".*"' | tr -d '"')"
      local vm_dir="${vm_cfg%/*}"

      local vbox_sysprops
      vbox_sysprops="$(VBoxManage list systemproperties)" || {
        echo "Failed to get system properties for '${vm_name}'" >&2
        continue
      }

      local all_vms_dir="$(echo "$vbox_sysprops" | grep -i 'Default machine folder:' | grep -o '/.*$')"

      if [[ "$vm_dir" != "$all_vms_dir"* ]]; then
        echo "Vm dir '${vm_dir}' is not inside '${all_vms_dir}'" >&2
        continue
      fi

      VBoxManage unregistervm "$vm_name" --delete

      if [[ -d "$vm_dir" ]]; then
        rm -rf "$vm_dir"
      fi
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

wait_for_ssh_service() {
  local -i i=0
  local -i max="$TEST_SSH_WAIT_TIMEOUT"

  while ! ssh -T -o 'ConnectTimeout=1' \
    -o 'UserKnownHostsFile=/dev/null' \
    -o 'PubkeyAuthentication=no' \
    -o 'StrictHostKeyChecking=no' \
    -o 'PasswordAuthentication=no' \
    -p "$TEST_SSH_PORT" \
    "${TEST_SSH_USER}@${TEST_SSH_IP}" 2>&1 | grep -q 'Permission denied'; do
    # TODO: change if [[ $# == 0 ]]; then; set -- '-h'; fi
    [[ $i -ge $max ]] && return 1
    sleep 1
    ((i += 1))
  done
  return 0
}

start_vm() {
  local -r vm_name="$1"
  VBoxManage startvm "$vm_name" --type headless &>/dev/null
}

start_vm_wait_ssh() {
  start_vm "$@"
  wait_for_ssh_service
}

ssh_run_cmd() {
  local -r cmd="$*"

  sshpass -p "$TEST_SSH_PASSWORD" \
    ssh -T -o 'ConnectTimeout=1' \
    -o 'UserKnownHostsFile=/dev/null' \
    -o 'PubkeyAuthentication=no' \
    -o 'StrictHostKeyChecking=no' \
    -p "$TEST_SSH_PORT" \
    "${TEST_SSH_USER}@${TEST_SSH_IP}" 2>/dev/null <<SSHEOF
         eval "$cmd"
SSHEOF
}

# cd "$BATS_TEST_DIRNAME" || exit

[[ -d "$TEST_TMP_DIR" ]] || {
  mkdir -p "$TEST_TMP_DIR"
  chmod 777 "$TEST_TMP_DIR"
}
