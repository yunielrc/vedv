<h1 align="center">
  <a href="" rel="noopener">
 <img width=200px height=150px src="media/icon.png" alt="Project logo"></a>
</h1>

<p align="center">
<i>A tool for developing in a secure and reproducible environment</i>
</p>

## About

A tool for developing applications in a secure and reproducible environment using virtual machines with a Docker-like flavor.

### 👉 THIS IS A WORK IN PROGRESS

<!--
## Motivation

The software we are developing needs to be tested on a system as similar as possible to the one where it is going to be executed. Sometimes it is very difficult to satisfy this requirement with docker and we have to use virtual machines missing the docker workflow. This is why I started the development of vedv. I hope you find it useful. Thank you.

#### This help has been tested on a clean installation of

- Linux manjaro-gnome 6.1.30-1-MANJARO #1 SMP PREEMPT_DYNAMIC Wed May 24 22:51:44 UTC 2023 x86_64 GNU/Linux (system updated by 2023-08-20)

You can check your distro and kernel version with the following command:

```sh
uname -a
```

## Dependencies

### Runtime Dependencies

- virtualbox
- gnu-netcat
- sshpass
- libxml2
- python-pip
  - dockerfile-parse
  - petname

## Install

For installation from source code is required to have installed git and make.

Clone the repository and switch to vedv directory

```sh
git clone https://github.com/yunielrc/vedv.git && cd vedv
```

For any linux distribution install runtime dependencies first and execute the command below:

```sh
make install
```

Manjaro

```sh
make install-m
```

You can leave the repository directory after installation

```sh
cd
```

## Configure

Register at <https://registry.vedv.dev>

### Create app password

- Go to <https://registry.vedv.dev/settings/user/security>

- Scroll to the end up to the section: **Devices & sessions**

<h1>
 <img width=500px  src="media/registry-nextcloud-app-password.png" alt="registry nextcloud app password">
</h1>

- Write on **App Name**: *vedv*

- Press **Create new app password**

- Copy the generated password

### Set the credentials

Note: The editor used in the examples is vim.

Copy the config to your home directory

```sh
cp /etc/skel/.vedv.env ~
```

Set the registry credentials

```sh
vim ~/.vedv.env
```

## Usage

Show the help

```sh
vedv --help
```

```sh
# command output:
Usage:
vedv COMMAND

A tool for developing in a secure and reproducible environment

Flags:
  -h, --help    show this help

Management Commands:
  container     manage containers
  image         manage images
  builder       manage builder
  registry      manage registry

Run 'vedv COMMAND --help' for more information on a command.
```

### Start a container

Download an image and create a container, then start it

```sh
vedv container create -n alpine admin@alpine/alpine-3.18.3-x86_64
vedv container start alpine    # starting a container can take around 10 to 30 seconds
```

Or download an image with custom name, create a container and start it

```sh
vedv image pull -n alpine admin@alpine/alpine-3.18.3-x86_64
vedv container create -n alpine alpine
vedv container start alpine     # starting a container can take around 10 to 30 seconds
```

Show running containers

```sh
vedv container ls
```

### Login to the container

If you see the error: `Connection timed out during banner exchange`,
the container is starting, wait around 10 seconds and try again.
To avoid that you can starts the container with the `--wait` flag

If you run the login command and the container is stopped, it is started automatically

```sh
vedv container login alpine  #  It can take around 10 to 30 seconds if the container is stopped
```

Play with it :)

Exit the container and remove it

```sh
vedv container rm --force alpine
```

### Build an image

The example is taken from <https://www.docker.com/101-tutorial/>, with some modifications.

#### Our Application

We will be working with a simple todo list manager that is running in Node.js.

#### Getting our App

Download the app

```sh
git clone https://github.com/yunielrc/todo-101.git
```

#### Building the App's Container Image

- Go to the app directory

```sh
cd app
```


- Create a file named  `Vedvfile` in the same folder as the file package.json
  with the following contents.

```dockerfile
FROM admin@alpine/alpine-3.18.3-x86_64

ENV APP_NAME='todo-101'
SHELL /bin/sh
USER root
WORKDIR /app

RUN apk add -U nodejs=18.17.0-r0 npm=9.6.6-r0 yarn=1.22.19-r0

COPY package.json .
COPY yarn.lock .
RUN yarn install --production

COPY --chmod 0755 ./root/etc/init.d/todo-101 /etc/init.d/todo-101
RUN rc-update add "$APP_NAME"

COPY . .
RUN rc-service "$APP_NAME" start

EXPOSE 3000/tcp
```

Vedvfile syntax is highly inspired by Dockerfile, but it has some differences,
so they are aren't compatible.

Save the file and exit

- Build it

```sh
vedv image build -n alpine-hello_world-1.0.0-x86_64
```

- Create a container from the image

```sh
vedv container create -p 3000:3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
# When the ports are the same like `3000:3000`  the command below is equivalent
# vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
vedv container start -w todo-101
```

- Open your browser and go to <http://localhost:3000>

  You should see the todo list manager app

<h1>
 <img width=500px  src="media/todo-list-manager.png" alt="todo list manager">
</h1>


#### Change the number of cpu cores and memory

- Execute the command below to see cpu cores and memory

```sh
vedv container exec todo-101 <<'EOF'                                                                        ✔
grep -m1 'cpu cores' /proc/cpuinfo
free -m | grep -Eo 'Mem:\s+\d+'
EOF
```

The output must be:


```sh
cpu cores       : 2
Mem:            223
```

- Remove the container

```sh
vedv container rm --force todo-101
```

- Open the Vedvfile in an editor and add the instruction `SYSTEM ...` right before
  the instruction `EXPOSE 3000/tcp`

```dockerfile
...
...
...

SYSTEM --cpus 3 --memory 740

EXPOSE 3000/tcp
```

Save the file and exit

- Build it again

```sh
vedv image build --force -n alpine-hello_world-1.0.0-x86_64
```

- Create a container from the image

```sh
vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
```

- Execute the command below to see cpu cores and memory

```sh
vedv container exec todo-101 <<'EOF'                                                                        ✔
grep -m1 'cpu cores' /proc/cpuinfo
free -m | grep -Eo 'Mem:\s+\d+'
EOF
```

The output must be:

```sh
cpu cores       : 1
Mem:            475
```

- Remove  `SYSTEM ...` instruction from the Vedvfile

- Remove the container

```sh
vedv container rm --force todo-101
```

#### Updating the Source Code

- In the src/static/js/app.js file, update line 56 to use the new empty text.

```diff
-  <p className="text-center">No items yet! Add one above!</p>
+  <p className="text-center">You have no todo items yet! Add one above!</p>
```

- Let's build our updated version of the image, using the same command we used before.

```sh
vedv image build --force -n alpine-hello_world-1.0.0-x86_64
```

- Let's start a new container using the updated code.

```sh
vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
```

- Refresh your browser on <http://localhost:3000> and you should see your updated help text!

- Remove the container

```sh
vedv container rm --force todo-101
```

### Push the image to the registry

👉 There is only 100MB of free space for each user at the moment, so use it
   for testing purposes only.
<!--
💰  I am looking for funding to increase the storage space and provisioning
    a best server.


```sh
vedv image push <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64
# If you want to push the image with a different name:
# vedv image push -n todo-101-alpine-1.0.0-x86_64 <your_user_id>@alpine/<your_image_name>-1.0.0-x86_64
```

- Pull your image from the registry

```sh
vedv image pull -n todo-101-alpine-1.0.0-x86_64 <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64
# If you pushed the image with a different name:
# vedv image pull -n todo-101-alpine-1.0.0-x86_64 <your_user_id>@alpine/<your_image_name>-1.0.0-x86_64
```

- Create and start the container

```sh
vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
vedv container start -w todo-101
```

- Play with it and remove the container when you finish


### Push an image link to the registry

Due to the limited storage space, you can push an image link to the registry,
it only takes 1KB of space.

- Export the image to a file with the .ova extension

```sh
vedv image export alpine-hello_world-1.0.0-x86_64 alpine-hello_world-1.0.0-x86_64.ova
```

- Copy the image and the .sha256sum to OneDrive, Google Drive or any http server

#### Share on OneDrive

#### Share on Google Drive

#### Share on http server

## Development dependencies

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
