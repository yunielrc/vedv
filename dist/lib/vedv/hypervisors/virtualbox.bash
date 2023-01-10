#
# API to manage virtualbox virtual machines
#

# FUNCTIONS

# IMAGE

# IMPL: Pull an image or a repository from a registry
vedv::virtualbox::image::pull() {
  echo 'vedv::virtualbox::image::pull'
}
# IMPL: Build an image
vedv::virtualbox::image::build() {
  echo 'vedv::virtualbox::image::build'
}

# CONTAINER

# IMPL: Create a new container
vedv::virtualbox::container::create() {
  echo 'vedv::virtualbox::container::create'
}

# IMPL: Start one or more stopped containers
vedv::virtualbox::container::start() {
  echo 'vedv::virtualbox::container::start'
}

#  IMPL: Stop one or more running containers
vedv::virtualbox::container::stop() {
  echo 'vedv::virtualbox::container::stop'
}

# IMPL: Remove one or more containers
vedv::virtualbox::container::rm() {
  echo 'vedv::virtualbox::container::rm'
}

# IMPL: Create and run a container from an image
vedv::virtualbox::container::run() {
  echo 'vedv::virtualbox::container::run'
}
