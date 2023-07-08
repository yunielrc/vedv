#
# Manage containers
#
#

# this is only for code completion
if false; then
  . './../../utils.bash'
  . './container-entity.bash'
  . './../__base/vmobj-service.bash'
  . '../image/image-entity.bash'
  . '../image/image-service.bash'
  . './../../ssh-client.bash'
  . './../../hypervisors/virtualbox.bash'
fi

# CONSTANTS

readonly VEDV_CONTAINER_SERVICE_STANDALONE='STANDALONE'

# FUNCTIONS

#
# Constructor
#
# Arguments:
#  ssh_ip string    ssh ip address
#
# Returns:
#   0 on success, non-zero on error.
#
# vedv::container_service::constructor() {

# }

#
# Return if use cache for containers
#
# Output:
#  writes true if use cache otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::get_use_cache() {
  vedv::vmobj_service::get_use_cache 'container'
}

#
# Set use cache for containers
#
# Arguments:
#  value     bool     use cache value
#
# Returns:
#   0 on success, non-zero on error.
vedv::container_service::set_use_cache() {
  local -r value="$1"

  vedv::vmobj_service::set_use_cache 'container' "$value"
}

#
# Create a container from an image
#
# Arguments:
#   image             string    image name or image file
#   [container_name]  string    container name
#   [standalone]      bool      create a standalone container (default: false)
#   [publish_ports]   string[]  ports to be published
#   [publish_all]     bool      publish all ports (default: false)
#
# Output:
#  Writes container id and name (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::create() {
  local -r image="$1"
  local container_name="${2:-}"
  local -r standalone="${3:-false}"
  local -r publish_ports="${4:-}"
  local -r publish_all="${5:-false}"
  # validate arguments
  if [[ -z "$image" ]]; then
    err "Invalid argument 'image': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ -n "$container_name" ]]; then
    local exists_container
    exists_container="$(vedv::container_service::exists_with_name "$container_name")" || {
      err "Failed to check if container with name: '${container_name}' already exist"
      return "$ERR_CONTAINER_OPERATION"
    }
    readonly exists_container

    if [[ "$exists_container" == true ]]; then
      err "Container with name: '${container_name}' already exist, you can delete it or use another name"
      return "$ERR_CONTAINER_OPERATION"
    fi
  fi

  local image_name

  if [[ -f "$image" ]]; then
    image_name="$(petname)" || {
      err "Failed to generate a random name"
      return "$ERR_CONTAINER_OPERATION"
    }
    vedv::image_service::pull "$image" "$image_name" &>/dev/null || {
      err "Failed to pull image: '${image}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  else
    image_name="$image"
  fi
  readonly image_name

  local image_vm_name
  image_vm_name="$(vedv::image_entity::get_vm_name_by_image_name "$image_name")" || {
    err "Failed to get image vm name for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_vm_name

  if [[ -z "$image_vm_name" ]]; then
    err "Image: '${image_name}' does not exist"
    return "$ERR_NOT_FOUND"
  fi

  # create a vm snapshoot, the snapshoot is the container
  local image_id
  image_id="$(vedv::image_entity::get_id_by_vm_name "$image_vm_name")" || {
    err "Failed to get image id for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_id

  local last_layer_id
  last_layer_id="$(vedv::image_entity::get_last_layer_id "$image_id")" || {
    err "Failed to get last image layer id for image: '${image_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly last_layer_id

  local layer_vm_snapshot_name=''

  if [[ -n "$last_layer_id" ]]; then
    layer_vm_snapshot_name="$(vedv::image_entity::get_snapshot_name_by_layer_id "$image_id" "$last_layer_id")" || {
      err "Failed to get image layer snapshot name for image: '$image_name'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi
  readonly layer_vm_snapshot_name

  local container_vm_name
  container_vm_name="$(vedv::container_entity::gen_vm_name "$container_name")" || {
    err "Failed to generate container vm name for container: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  if [[ "$standalone" == false ]]; then
    vedv::hypervisor::clonevm_link "$image_vm_name" "$container_vm_name" "$layer_vm_snapshot_name" 'false' &>/dev/null || {
      err "Failed to link clone vm: '${image_vm_name}' to: '${container_vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  else
    vedv::hypervisor::clonevm "$image_vm_name" "$container_vm_name" "$layer_vm_snapshot_name" &>/dev/null || {
      err "Failed to full clone vm: '${image_vm_name}' to: '${container_vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  if [[ -z "$container_name" ]]; then
    container_name="$(vedv::container_entity::get_container_name_by_vm_name "$container_vm_name")" || {
      err "Failed to get container name for vm: '${container_vm_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi
  readonly container_name

  local container_id
  container_id="$(vedv::container_entity::get_id_by_vm_name "$container_vm_name")" || {
    err "Failed to get container id for vm: '${container_vm_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_id
  # we need to call this func to clean the cache for the vmobj_id is there is any
  vedv::vmobj_service::after_create 'container' "$container_id" || {
    err "Error on after create event: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  if [[ "$standalone" == false ]]; then
    vedv::image_entity::____add_child_container_id "$image_id" "$container_id" || {
      err "Failed to add child container id for image: '${image_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  vedv::container_entity::set_vm_name "$container_id" "$container_vm_name" || {
    err "Failed to set vm name for container: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  vedv::container_entity::set_parent_image_id "$container_id" "$([[ "$standalone" == false ]] && echo "$image_id" || echo "$VEDV_CONTAINER_SERVICE_STANDALONE")" || {
    err "Failed to set parent image id for container: '${container_name}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  if [[ -n "$publish_ports" ]]; then
    vedv::container_service::__publish_ports "$container_id" "$publish_ports" || {
      err "Failed to publish ports for container: '${container_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  if [[ "$publish_all" == true ]]; then
    vedv::container_service::__publish_exposed_ports "$container_id" || {
      err "Failed to publish all ports for container: '${container_name}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi
  # UNTESTED
  # vedv::container_entity::import_data "$container_id" || {
  #   err "Failed to import data for container: '${container_name}'"
  #   return "$ERR_CONTAINER_OPERATION"
  # }
  echo "${container_id} ${container_name}"
}

#
# Publish all exposed ports
# Assign a random host port for each container exposed port
#
# Arguments:
#   container_id  string     container id
#
# Output:
#  writes error message to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__publish_exposed_ports() {
  local -r container_id="$1"

  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local -a exp_ports_arr=
  local exp_ports_str

  # the function below starts the container
  exp_ports_str="$(vedv::container_entity::cache::get_exposed_ports "$container_id" 2>/dev/null)" || {
    err "Failed to get exposed ports for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly exp_ports_str

  if [[ -z "$exp_ports_str" ]]; then
    return 0
  fi

  readarray -t exp_ports_arr <<<"$exp_ports_str"
  readonly exp_ports_arr

  for exp_port in "${exp_ports_arr[@]}"; do
    local random_host_port=''

    random_host_port="$(utils::get_a_dynamic_port)"

    local port="${random_host_port}:${exp_port}"

    vedv::container_service::__publish_port "$container_id" "$port" || {
      err "Failed to publish port: '${port}' for container: '${container_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  done
}

#
# Publish ports for a container
#
# Arguments:
#   container_id  string     container id
#   ports_arr     string[]   ports to be published. eg: 8080:80/tcp 8081:81/udp
#
# Output:
#  writes error message to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__publish_ports() {
  local -r container_id="$1"
  local -a ports_arr=()

  IFS=' ' read -r -a ports_arr <<<"${2:-}"
  readonly ports_arr

  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  if [[ ${#ports_arr[@]} -eq 0 ]]; then
    return 0
  fi

  for port in "${ports_arr[@]}"; do
    vedv::container_service::__publish_port "$container_id" "$port" || {
      err "Failed to publish port: '${port}' for container: '${container_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  done
}

#
# Publish a port for a container
#
# Arguments:
#   container_id  string   container id
#   port          string   port to be published. eg: 8080:80/tcp 8082:82 8081 81/udp
#
# Output:
#  writes error message to the stderr
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__publish_port() {
  local -r container_id="$1"
  local -r port="$2"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$port" ]]; then
    err "Invalid argument 'port': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local -i host_port=''
  local -i container_port=''
  local protocol=''
  local -r rule_name="$(utils::crc_sum <<<"$port")"

  # 8080:80/tcp
  if [[ "$port" =~ ^[[:digit:]]+:[[:digit:]]+/(tcp|udp)$ ]]; then
    local -a port_arr
    IFS=':' read -ra port_arr <<<"$port"
    host_port="${port_arr[0]}"
    container_port="${port_arr[1]%%/*}"
    protocol="${port_arr[1]##*/}"
  # 8082:82
  elif [[ "$port" =~ ^[[:digit:]]+:[[:digit:]]+$ ]]; then
    IFS=':' read -r host_port container_port <<<"$port"
    protocol='tcp'
  # 81/udp
  elif [[ "$port" =~ ^[[:digit:]]+/(tcp|udp)$ ]]; then
    IFS='/' read -r container_port protocol <<<"$port"
    host_port="$container_port"
  # 8081
  elif [[ "$port" =~ ^[[:digit:]]+$ ]]; then
    host_port="$port"
    container_port="$port"
    protocol='tcp'
  else
    err "Invalid port format: '${port}'"
    return "$ERR_INVAL_ARG"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::get_vm_name "$container_id")" || {
    err "Failed to get vm name for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  if [[ -z "$container_vm_name" ]]; then
    err "There is no container with id '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  vedv::hypervisor::add_forwarding_port \
    "$container_vm_name" \
    "$rule_name" \
    "$host_port" \
    "$container_port" \
    "$protocol" 2>/dev/null || {
    err "Failed to publish port: '${port}' for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
}

#
# Tell if a container is started
#
# Arguments:
#   container_id  string       container id
#
# Output:
#  Writes true if started otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::is_started() {
  local -r container_id="$1"

  vedv::vmobj_service::is_started 'container' "$container_id"
}

#
# Start one or more containers by name or id
#
# Arguments:
#   container_names_or_ids  string[]  vmobj name or id
#   [wait_for_ssh]          bool      wait for ssh (default: true)
#   [show]                  bool      show container gui on supported desktop platforms (default: false)
#
#
# Output:
#  writes started containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::start() {
  local -r container_names_or_ids="$1"
  local -r wait_for_ssh="${2:-true}"
  local -r show="${3:-false}"

  vedv::vmobj_service::start \
    'container' \
    "$container_names_or_ids" \
    "$wait_for_ssh" \
    "$show"
}

#
#  Stop securely one or more running containers by name or id
#
# Arguments:
#   containers_name_or_ids  string[]     containers name or id
#
# Output:
#  writes stopped containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::stop() {
  local -r container_names_or_ids="$1"

  vedv::vmobj_service::stop 'container' "$container_names_or_ids" 'true'
}

#
#  Remove a container
#
# Arguments:
#   container_id  string     container id
#   force         bool       force remove container (default: false)
#
# Output:
#  writes removed container id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove_one() {
  local -r container_id="$1"
  local -r force="${2:-false}"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi
  if [[ -z "$force" ]]; then
    err "Invalid argument 'force': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::get_vm_name "$container_id")" || {
    err "Failed to get vm name for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  if [[ -z "$container_vm_name" ]]; then
    err "There is no container with id '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  local parent_image_id
  parent_image_id="$(vedv::container_entity::get_parent_image_id "$container_id")" || {
    err "Failed to get parent image id for container '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly parent_image_id

  if [[ -z "$parent_image_id" ]]; then
    err "No 'parent_image_id' for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  if [[ "$force" == false ]]; then
    local is_running
    is_running="$(vedv::container_service::is_started "$container_id")" || {
      err "Failed to check if container is started: '${container_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }
    readonly is_running

    if [[ "$is_running" == true ]]; then
      err "Failed to remove a running container '${container_id}'. Stop the container first or force remove"
      return "$ERR_CONTAINER_OPERATION"
    fi
  fi

  vedv::hypervisor::rm "$container_vm_name" &>/dev/null || {
    err "Failed to remove container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  vedv::vmobj_service::after_remove 'container' "$container_id" || {
    err "Error on after remove event: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }

  if [[ "$parent_image_id" != "$VEDV_CONTAINER_SERVICE_STANDALONE" ]]; then
    vedv::image_entity::____remove_child_container_id "$parent_image_id" "$container_id" || {
      err "Failed to remove child container id from parent image: '${container_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }
  fi

  echo "$container_id"
}

#
#  Remove a container
#
# Arguments:
#   force         bool       force remove container
#   container_id  string     container id
#
# Output:
#  writes removed container_id (string) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove_one_batch() {
  local -r force="$1"
  local -r container_id="$2"

  vedv::container_service::remove_one "$container_id" "$force"
}

#
# Get the running sibling containers ids of a container
#
# Arguments:
#   container_id  string     container id
#
# Output:
#  writes running sibling containers ids to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::__get_running_siblings_ids() {
  local -r container_id="$1"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local parent_image_id
  parent_image_id="$(vedv::container_entity::get_parent_image_id "$container_id")" || {
    err "Failed to get parent image id for container '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly parent_image_id

  if [[ -z "$parent_image_id" ]]; then
    err "No 'parent_image_id' for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  local image_childs_ids
  image_childs_ids="$(vedv::image_entity::get_child_containers_ids "$parent_image_id")" || {
    err "Failed to get child containers ids for image: '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly image_childs_ids

  if [[ -z "$image_childs_ids" ]]; then
    err "No child containers ids for image: '${parent_image_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi
  # shellcheck disable=SC2206
  local -a image_childs_ids_arr=($image_childs_ids)

  local -a running_siblings_ids_arr=()

  for image_child_id in "${image_childs_ids_arr[@]}"; do

    if [[ "$image_child_id" == "$container_id" ]]; then
      continue
    fi

    local is_started=false
    is_started="$(vedv::container_service::is_started "$image_child_id")" || {
      err "Failed to check if container is started: '${image_child_id}'"
      return "$ERR_CONTAINER_OPERATION"
    }

    if [[ "$is_started" == true ]]; then
      running_siblings_ids_arr+=("$image_child_id")
    fi
  done

  echo "${running_siblings_ids_arr[*]}"
}

#
# Remove one or more containers by name or id
#
# Arguments:
#   containers_names_or_ids  string[]  containers name or id
#   force                    bool      force remove container (default: false)
#
# Output:
#  writes removed containers name or id to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::remove() {
  local -r containers_names_or_ids="$1"
  local -r force="${2:-false}"

  vedv::vmobj_service::exec_func_on_many_vmobj \
    'container' \
    "vedv::container_service::remove_one_batch '${force}'" \
    "$containers_names_or_ids"
}

#
#  List containers
#
# Arguments:
#   [list_all]      bool       default: false, list running containers
#   [partial_name]  string     name of the exported VM
#
# Output:
#  writes image id, name to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::list() {
  local -r list_all="${1:-false}"
  local -r partial_name="${2:-}"

  vedv::vmobj_service::list \
    'container' \
    "$list_all" \
    "$partial_name"
}

#
# Execute cmd in a container
#
# Arguments:
#   container_id_or_name  string    container id or name
#   cmd                   string    command to execute
#   [user]                string    user name
#   [workdir]             string    working directory for command
#   [env]                 string    environment variable for command
#   [shell]               string    shell to use for command
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::execute_cmd() {
  local -r container_id_or_name="$1"
  local -r cmd="$2"
  local -r user="${3:-}"
  local -r workdir="${4:-}"
  local -r env="${5:-}"
  local -r shell="${6:-}"

  vedv::vmobj_service::execute_cmd \
    'container' \
    "$container_id_or_name" \
    "$cmd" \
    "$user" \
    "$workdir" \
    "$env" \
    "$shell"
}

#
# Establish a ssh connection to a container
#
# Arguments:
#   container_id_or_name  string     container id or name
#   [user]                string     container user
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::connect() {
  local -r container_id_or_name="$1"
  local -r user="${2:-}"

  vedv::vmobj_service::connect 'container' "$container_id_or_name" "$user"
}

#
# Copy files from local filesystem to a container
#
# Arguments:
#   container_id_or_name  string     container id or name
#   src                   string     local source path
#   dest                  string     container destination path
#   [user]                string     container user
#   [chown]               string     chown files to user
#   [chmod]               string     chmod files to mode
#
# Output:
#  writes command output to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::copy() {
  local -r container_id_or_name="$1"
  local -r src="$2"
  local -r dest="$3"
  local -r user="${4:-}"
  local -r chown="${5:-}"
  local -r chmod="${6:-}"

  vedv::vmobj_service::copy \
    'container' \
    "$container_id_or_name" \
    "$src" \
    "$dest" \
    "$user" \
    '' \
    "$chown" \
    "$chmod"
}

#
# List exposed ports from container filesystem
#
# Arguments:
#   container_name_or_id  string    container name or id
#
# Output:
#   writes exposed ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::cache::list_exposed_ports() {
  local -r container_name_or_id="$1"
  # validate arguments
  if [[ -z "$container_name_or_id" ]]; then
    err "Invalid argument 'vmobj_name_or_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local container_id
  container_id="$(vedv::vmobj_entity::get_id "$container_name_or_id")" || {
    err "Failed to get id for container: '${container_name_or_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_id

  vedv::container_entity::cache::get_exposed_ports "$container_id"
}

#
# List port mappings for the container
#
# Arguments:
#   container_id  string    container id
#
# Output:
#   writes expose ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::list_ports_by_id() {
  local -r container_id="$1"
  # validate arguments
  if [[ -z "$container_id" ]]; then
    err "Invalid argument 'container_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local container_vm_name
  container_vm_name="$(vedv::container_entity::get_vm_name "$container_id")" || {
    err "Failed to get vm name for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_vm_name

  if [[ -z "$container_vm_name" ]]; then
    err "There is no container with id '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  fi

  local vm_fw_ports
  vm_fw_ports="$(vedv::hypervisor::get_forwarding_ports "$container_vm_name")" || {
    err "Failed to get ports for container: '${container_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly vm_fw_ports

  local -a vm_fw_ports_arr=()
  readarray -t vm_fw_ports_arr <<<"$vm_fw_ports"

  for vm_fw_port in "${vm_fw_ports_arr[@]}"; do
    # transform from: 2150172608,tcp,,8082,,82
    # to            : 8082/tcp -> 82
    local -a vm_fw_port_arr
    IFS=',' read -ra vm_fw_port_arr <<<"$vm_fw_port"

    local protocol="${vm_fw_port_arr[1]}"
    local host_port="${vm_fw_port_arr[3]}"
    local container_port="${vm_fw_port_arr[5]}"

    echo "${host_port}/${protocol} -> ${container_port}"
  done
}

#
# List port mappings for the container
#
# Arguments:
#   container_name_or_id  string    container name or id
#
# Output:
#   writes expose ports (text) to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::list_ports() {
  local -r container_name_or_id="$1"
  # validate arguments
  if [[ -z "$container_name_or_id" ]]; then
    err "Invalid argument 'container_name_or_id': it's empty"
    return "$ERR_INVAL_ARG"
  fi

  local container_id
  container_id="$(vedv::vmobj_entity::get_id "$container_name_or_id")" || {
    err "Failed to get id for container: '${container_name_or_id}'"
    return "$ERR_CONTAINER_OPERATION"
  }
  readonly container_id

  vedv::container_service::list_ports_by_id "$container_id"
}

#
#  Exists container with id
#
# Arguments:
#  container_id string    container id
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::exists_with_id() {
  local -r vmobj_id="$1"

  vedv::vmobj_service::exists_with_id \
    'container' \
    "$vmobj_id"
}

#
#  Exists container with name
#
# Arguments:
#  container_name string  container name
#
# Output:
#  writes true if exists otherwise false to the stdout
#
# Returns:
#   0 on success, non-zero on error.
#
vedv::container_service::exists_with_name() {
  local -r vmobj_name="$1"

  vedv::vmobj_service::exists_with_name \
    'container' \
    "$vmobj_name"
}
