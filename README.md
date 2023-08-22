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

The software we are developing needs to be tested on a system as closed as possible to the one where it is going to be executed. Sometimes it is very difficult to satisfy this requirement with docker and we have to use virtual machines missing the docker workflow. This is why I started the development of vedv. I hope you find it useful. Thank you.

## This help has been tested on a clean installation of:

- Linux manjaro-gnome 6.1.30-1-MANJARO #1 SMP PREEMPT_DYNAMIC Wed May 24 22:51:44 UTC 2023 x86_64 GNU/Linux (system updated by 2023-08-21)

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

Install on Manjaro:

```sh
make install-m
```

For any other linux distribution install runtime dependencies first and execute the command below:

```sh
make install
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

Copy the config to your home directory

```sh
cp /etc/skel/.vedv.env ~
```

Edit the config, set the registry credentials, save and exit

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
vedv container start -w alpine     # starting a container can take around 10 to 30 seconds
```

Show the image and copy its name to remove it later

```sh
vedv image ls
```

Show running container

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
Remove the image

```sh
vedv image rm <your-image-name>
```

### Our Application

This a modified version of the sample app from <https://www.docker.com/101-tutorial/>. Thanks to Docker for the sample app.

We will be working with a simple todo list manager that is running in Node.js.

#### Getting our App

Download the app and switch to its directory

```sh
git clone https://github.com/yunielrc/todo-101.git && cd todo-101
```

#### Building the App's Container Image

- Create a file named  `Vedvfile` in the same folder as the file package.json
  with the following contents.

```dockerfile
# Download the image from the registry and import it
FROM admin@alpine/alpine-3.18.3-x86_64
# Set the user, create it if doesn't exist and change the owner
# of WORKDIR recursively
USER root
# Set the working directory and create it if doesn't exist
WORKDIR /app
# Run commands on the current working directory
RUN apk add -U nodejs=18.17.0-r0 npm=9.6.6-r0 yarn=1.22.19-r0
# Copy package.json to the current working directory
COPY package.json .
# Copy yarn.lock to the current working directory
COPY yarn.lock .
# Install dependencies
RUN yarn install --production
# Copy the service file and set the permissions
COPY --chmod 0755 ./root/etc/init.d/todo-101 /etc/init.d/todo-101
# Add the service to the default runlevel (auto-start on boot)
RUN rc-update add todo-101
# Copy the source code to the current working directory
COPY . .
# Start the service
RUN rc-service todo-101 start
# Expose port 3000
EXPOSE 3000/tcp
```

Vedvfile syntax is highly inspired by Dockerfile, but with some differences

Save the file and exit

- Build it

```sh
vedv image build -n todo-101-alpine-1.0.0-x86_64
```

It took me around 1m 24s to build the image

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
vedv image build --force -n todo-101-alpine-1.0.0-x86_64
```


Each line like the one below is a deleted layer:
`0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%`

In this case 3 layers were deleted, starting from `COPY . .` to the end of the file.

It took me around 24s to rebuild the image

- Let's start a new container using the updated code.

```sh
vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
vedv container start -w todo-101
```

- Refresh your browser on <http://localhost:3000> and you should see your updated help text!

- Remove the container

```sh
vedv container rm --force todo-101
```

#### Push the image to the registry

👉 There is only 200MB of free space for each user at the moment, so use it
   for testing purposes only.
<!--
💰  I am looking for funding to increase the storage space and provisioning
    a best server.

```sh
vedv image push <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64
# If you want to push the image with a different name run the command below:
# vedv image push -n todo-101-alpine-1.0.0-x86_64 <your_user_id>@alpine/<your_image_name>-1.0.0-x86_64
```

- You can use the command bmon to see the upload activity

Install bmon if you don't have it, open it and select the network interface

It took around 1m 30s to upload the image with an upload speed of 12Mbps

```sh
bmon
```

### Vedvfile instructions

```dockerfile

# --------------
# Text surrounded by `` on the comments is for emphasize.

# Environment variables are always expanded in the Vedvfile keeping its quotes,
# even those surrounded by ''. To avoid a variable expansion on Vedvfile escape
# it, e.g.: \$VAR
# The scope of environment variables is Vedvfile and image os.

# Globbing is disabled in the Vedvfile, it is only enabled on the image os.

# All instructions are evaluated in the Vedvfile, except:
# RUN, to send the command to the image os as it is.
# ENV, to send the variable to the image os as it is, with its quotes.
# (unescaped environment variables are expanded in RUN and ENV instructions too)

# Host os environment variables aren't available in the Vedvfile
# -------------

# Declare an environment variable
# image os evals `DEST=dest`
ENV DEST=dest
# Image os evals `GREETINGS='hello world'`
ENV GREETINGS='hello world'
# Set the shell
SHELL /bin/sh
# Copy all files from `src` to `dest`. `COPY src/* dest` doesn't work because
# globbing is disabled in the Vedvfile.
COPY src/ dest
# Copy as root user
COPY --root ./src ./dest
# Copy and change user and group of `dest` to vedv recursively
COPY --chown vedv:vedv src dest
# Copy `src` to `WORKDIR` as vedv user
COPY --user vedv src .
# Variable `DEST` is expanded in the Vedvfile
COPY . $DEST
# Run command as root user
RUN --root id
# Run command as vedv user
RUN --user vedv id
# Variable is expanded in the Vedvfile
# image os evals `echo "hello world"`
RUN echo "$GREETINGS"
# Variable is expanded in the image os, the output is the same as the previous
# command, image os evals `echo "$GREETINGS"`
RUN echo "\$GREETINGS"
# Variable is expanded in the Vedvfile
# image os evals `echo 'hello world'`
RUN echo '$GREETINGS'
# Change the system cpu cores and memory
# Never use this instruction at the end of the Vedvfile, because it poweroff
# the image and don't save the state, so a rebuild will take more time.
# It is a very time consuming instruction, to change cpu cores and memory,
# the image needs to be turned off, the instruction is executed, and the image
# is turned on again by the next instruction.
SYSTEM --cpus 2 --memory 512
```

### Push image link to the registry

Due to the limited storage space at the moment, you can push image links to
the registry, it only takes 1KB of space.

- Export the image to a file with the .ova extension

```sh
vedv image export todo-101-alpine-1.0.0-x86_64 todo-101-alpine-1.0.0-x86_64.ova
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
