<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=150px src="media/icon.png" alt="Project logo"></a>
</p>

<p align="center">
<i>A tool for developing in a secure and reproducible environment</i>
</p>

## About

A tool for developing applications in a secure and reproducible environment using virtual machines with a Docker-like flavor.

**THIS IS A WORK IN PROGRESS**

## Dependencies

### Runtime Dependencies

- virtualbox
- hadolint-bin
- gnu-netcat
- python-pip
  - dockerfile-parse
  - petname

## Install

Clone the repository and switch to vedv directory

```sh
git clone https://github.com/yunielrc/vedv.git && cd vedv
```

For any linux distribution install runtime dependencies first and execute the commands below:

```sh
make install
```

Manjaro

```sh
make install-m
```

## Configure

On your browser login to <https://registry.vedv.org> with your google account
to create your account

Copy the config to your home directory

```sh
cp /etc/skel/.vedv.env ~/
```

Edit the config and set the registry creadentials

```sh
vim ~/.vedv.env
```

## Usage

Show the help

```sh
vedv --help
```

Download an image and create a container, then start it

```sh
vedv container create -n alpine admin@alpine/alpine-3.18.3-x86_64
vedv container start alpine
```

Or download an image with custom name, create a container and start it

```sh
vedv image pull -n alpine admin@alpine/alpine-3.18.3-x86_64-fat-inv
vedv container create -n alpine alpine
vedv container start alpine
```

<!--

### Development dependencies
- make
- shfmt
- shellcheck
- python-pre-commit
- bash-bats
- bash-bats-assert-git
- bash-bats-file
- bash-bats-support-git
- vultr-cli
- nodejs
- npm
  - @commitlint/cli
  - @commitlint/config-conventional
  - commitizen
  - cz-conventional-changelog

## Contributing

Contributions, issues and feature requests are welcome -->
