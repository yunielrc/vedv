#
# API to manage qemu virtual machines
#

# FUNCTIONS

# IMAGE

# IMPL: Pull an image or a repository from a registry
vedv::qemu::image::pull() {
  echo 'vedv::qemu::image::pull'
}
# IMPL: Build an image
vedv::qemu::image::build() {
  echo 'vedv::qemu::image::build'
}

# CONTAINER

# IMPL: Create a new container
vedv::qemu::container::create() {
  echo 'vedv::qemu::container::create'
}

# IMPL: Start one or more stopped containers
vedv::qemu::container::start() {
  echo 'vedv::qemu::container::start'
}

#  IMPL: Stop one or more running containers
vedv::qemu::container::stop() {
  echo 'vedv::qemu::container::stop'
}

# IMPL: Remove one or more containers
vedv::qemu::container::rm() {
  echo 'vedv::qemu::container::rm'
}

# IMPL: Create and run a container from an image
vedv::qemu::container::run() {
  echo 'vedv::qemu::container::run'
}
