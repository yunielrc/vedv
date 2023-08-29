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

## Motivation

The software we are developing needs to be tested on a system as closed as possible to the one where it is going to be executed. Sometimes it is very difficult to satisfy this requirement with docker and we have to use virtual machines missing the docker workflow. This is why I started the development of vedv. I hope you find it useful. Thank you.

## Tested OS

Note: This tool doesn't work on nested virtualization.

### Manjaro

Runtime Dependencies:

```sh
${MANJARO_PACKAGES_PROD}

```

### Ubuntu

Runtime Dependencies:

```sh
${UBUNTU_PACKAGES_PROD}

```

## Install

For installation from source code is required to have installed `git` and `make`.

Clone the repository and switch to vedv directory

```sh
git clone https://github.com/yunielrc/vedv.git && cd vedv
```

Install on Manjaro:

```sh
sudo make OS=manjaro install
```

Install on Ubuntu:

```sh
sudo make OS=ubuntu install
```

For any other linux distribution install runtime dependencies first and execute the command below:

```sh
sudo make install
```

## Configure

Register at <https://registry.vedv.dev>

### Create app password

- Go to <https://registry.vedv.dev/settings/user/security>

- Scroll to the end up to the section: **Devices & sessions**

 <img width=500px  src="media/registry-nextcloud-app-password.png" alt="registry nextcloud app password">

- Write on **App Name**: *vedv*

- Click on **Create new app password**

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
${VEDV_HELP}
```

### Start a container

Download an image with custom name, create a container and start it

- To see the download activity, install `bmon`, open it `bmon -b` and select the network interface

```sh
vedv image pull -n alpine admin@alpine/alpine-3.18.3-x86_64 # 13.708s 90Mbps
vedv container create -n alpine alpine #  1.566s
# starting a container can take up to 1 minute the first time or more
# deppending on your hardware and the image os
vedv container start -w alpine # 30.215s / ubuntu-server starts in around 13s
vedv container stop alpine # 0.836s
vedv container start -w alpine # 13.275s

```

Or download an image and create a container, then start it

```sh
vedv container create -n alpine admin@alpine/alpine-3.18.3-x86_64
# starting a container can take up to 1 minute the first time or more
# deppending on your hardware and the image os
vedv container start alpine
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
# login to a container can take up to 1 minute the first time or more
# deppending on your hardware and the image os
vedv container login alpine
```

Play with it :)

Exit the container and remove it

```sh
vedv container rm --force alpine
```

Show the image and copy its name to remove

```sh
vedv image ls
```

Remove the image

```sh
vedv image rm <your-image-name>
```

### Our Application

This is a modified version of the sample app from <https://www.docker.com/101-tutorial/>.
Thanks to Docker.

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
RUN apk add -U nodejs~18 npm yarn
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

- Save the file and exit

- Build it

```sh
vedv image build -n todo-101-alpine-1.0.0-x86_64 # 1m 10.58s
```

- Create a container from the image

```sh
vedv container create -p 3000:3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64 # 1.718s
# When the ports are the same like `3000:3000`  the command below is equivalent
# vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64
vedv container start -w todo-101 # 13.646s
```

- Open your browser and go to <http://localhost:3000>

  You should see the todo list manager app

 <img width=500px  src="media/todo-list-manager.png" alt="todo list manager">

```sh
vedv container rm --force todo-101 # 2.816s
```

#### Updating the Source Code

- In the src/static/js/app.js file, update line 56 to use the new empty text.

```diff
-  <p className="text-center">No items yet! Add one above!</p>
+  <p className="text-center">You have no todo items yet! Add one above!</p>
```

- Let's build our updated version of the image, using the same command we used before.

```sh
vedv image build --force -n todo-101-alpine-1.0.0-x86_64 # 17.945s
```

Each line like the one below is a deleted layer:
`0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%`

In this case 3 layers were deleted, starting from `COPY . .` to the end of the file.

- Let's start a new container using the updated code.

```sh
vedv container create -p 3000/tcp -n todo-101 todo-101-alpine-1.0.0-x86_64 # 1.654s
vedv container start -w todo-101 # 13.698s
```

- Refresh your browser on <http://localhost:3000> and you should see your updated help text!

- Remove the container

```sh
vedv container rm --force todo-101 # 3.285s
```

#### Push the image to the registry

👉 There is only 200MB of free space for each user at the moment, so use it
   for testing purposes only.
<!--
💰  I am looking for funding to increase the storage space and provisioning
    a best server.
-->

```sh
vedv image push <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64 # 1m 37.62s 12Mbps
# If you want to push the image with a different name run the command below:
# vedv image push -n todo-101-alpine-1.0.0-x86_64 <your_user_id>@alpine/<your_image_name>-1.0.0-x86_64
```

- On finish open your browser and go to <https://registry.vedv.dev/apps/files/?dir=/00-user-images>

You should see the collection:

```
<your_user_id>@alpine
```

- Click on the collection and you should see the image file an its .sha256sum file:

```
todo-101-alpine-1.0.0-x86_64.ova
todo-101-alpine-1.0.0-x86_64.ova.sha256sum
```

**The uploaded image size is around 130MB, to give chance other users to test vedv,
please delete the image from the registry and push an image link instead. Thanks.**

👍 Congratulations, you have builded and uploaded your first image to the registry.

### Push an image link to the registry

**If your registry has images that weights MB, to give chance other users to test
vedv, please delete that images and push image links instead. Thanks.**

Due to the limited storage space at the moment, you should push image links to
the registry.

- Export the image to a file with the .ova extension

```sh
vedv image export todo-101-alpine-1.0.0-x86_64 todo-101-alpine-1.0.0-x86_64.ova # 6.317s
```

- Upload the image and the .sha256sum to OneDrive or Google Drive or any http server

#### Share on OneDrive

1. Go to <https://onedrive.live.com>

2. Open the image file menu and Click on **Embed** as shown in the image below

<img width=500px  src="media/onecloud-share-embed-menu.png" alt="onecloud share embed menu">

3. Click on **Generate** button

<img width=400px  src="media/onecloud-share-embed-button.png" alt="onecloud share embed button">

4. Reaload onedrive page and Click on **Shared**

<img width=720px  src="media/onecloud-shared.png" alt="onecloud shared">

5. Click on **Links Tab** and Copy it

<img width=500px  src="media/onecloud-share-embed-copy.png" alt="onecloud share embed copy">

- Open your terminal and save the image link to a variable

Replace `<image_link>` with the link you have copied

```sh
image='onedrive=<image_link>'
```

- Repeat the steps 1-5 for sharing the .sha256sum file

- On the same terminal save the .sha256sum link to a variable

Replace `<sum_link>` with the link you have copied

```sh
sum='onedrive=<sum_link>'
```

##### Push the image link to the registry

- On the same terminal execute the command below

```sh
vedv image push-link --image-address "$image" --checksum-address "$sum" \
 <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64 # 2.706s
```

- Remove the image to download it again to test the link

```sh
vedv image rm todo-101-alpine-1.0.0-x86_64 # 0.995s
```

- Pull the image from the link

Use the flag `--no-cache` to download the image again

```sh
vedv image pull --no-cache -n todo-101-alpine-1.0.0-x86_64 \
  <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64         # 18.487s 90Mbps
```

👍 Congratulations, you have uploaded your image link to the registry and saved space for other users.

#### Share on Google Drive

1. Go to <https://drive.google.com/>

2. Open the image file menu and Click on **Share** as shown in the image below

<img width=500px  src="media/gdrive-share-menu.png" alt="gdrive share menu">

3. Click on **General access** and select **Anyone with the link**

<img width=400px  src="media/gdrive-share-view.png" alt="gdrive share view">

5. Copy the link and click on **Done**

<img width=500px  src="media/gdrive-share-view-done.png" alt="gdrive share view done">

- Open your terminal and save the image link to a variable

Replace `<image_link>` with the link you have copied

```sh
image='gdrive-big=<image_link>'
```

- Repeat the steps 1-5 for sharing the .sha256sum file

- On the same terminal save the .sha256sum link to a variable

Replace `<sum_link>` with the link you have copied

```sh
sum='gdrive-small=<sum_link>'
```

##### Push the image link to the registry

- On the same terminal execute the command below

```sh
vedv image push-link --image-address "$image" --checksum-address "$sum" \
 <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64
```

- Remove the image to download it again to test the link

```sh
vedv image rm todo-101-alpine-1.0.0-x86_64
```

- Pull the image from the link

Use the flag `--no-cache` to download the image again

```sh
vedv image pull --no-cache -n todo-101-alpine-1.0.0-x86_64 \
  <your_user_id>@alpine/todo-101-alpine-1.0.0-x86_64
```

👍 Congratulations, you have uploaded your image link to the registry and saved space for other users.

### Vedvfile instructions

```dockerfile

# --------------
# Text surrounded by `` on the comments here is for emphasize.

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
# Download the image from the registry and import it
FROM admin@alpine/alpine-3.18.3-x86_64
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

## Contributing

Contributions, issues and feature requests are welcome!

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

## Show your support

Give a ⭐️ if this project helped you!
