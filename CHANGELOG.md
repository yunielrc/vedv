# Changelog

## [0.3.1](https://github.com/yunielrc/vedv/compare/v0.3.0...v0.3.1) (2023-09-28)


### Bug Fixes

* **icac/images:** env variables are available on a container after build ([204c669](https://github.com/yunielrc/vedv/commit/204c669b35a5db92e9fb7d0f48e99ad963f3bf67))

## [0.3.0](https://github.com/yunielrc/vedv/compare/v0.2.3...v0.3.0) (2023-09-23)


### Features

* **container-command:** allow copy file to a container ignoring .vedvfileignore ([a9b5601](https://github.com/yunielrc/vedv/commit/a9b56010d37298a5c4da0b226a14c54f8c0d0952))


### Performance Improvements

* **vedv:** add a validation to do not load home config twice ([3e0a99c](https://github.com/yunielrc/vedv/commit/3e0a99c6b763013febcc337f79ad61764fece579))

## [0.2.3](https://github.com/yunielrc/vedv/compare/v0.2.2...v0.2.3) (2023-09-06)


### Bug Fixes

* **install:** create man pages directory ([96ba2cd](https://github.com/yunielrc/vedv/commit/96ba2cd2366734414fa2b8277aa45d0b47d1d1fa))
* **install:** install man pages from docs directory ([9c9fbf0](https://github.com/yunielrc/vedv/commit/9c9fbf06d640ab413845df42652222b5f1ac9f37))

## [0.2.2](https://github.com/yunielrc/vedv/compare/v0.2.1...v0.2.2) (2023-09-06)


### Bug Fixes

* **install:** take in account DESTDIR on man pages install ([d590005](https://github.com/yunielrc/vedv/commit/d5900055da415de7986ba8a9e831225e24dd66bc))

## [0.2.1](https://github.com/yunielrc/vedv/compare/v0.2.0...v0.2.1) (2023-09-06)


### Miscellaneous Chores

* release 0.2.1 ([ebcea02](https://github.com/yunielrc/vedv/commit/ebcea02b0ee37731659aa62a4702e61a0514ed5f))

## 0.2.0 (2023-09-06)


### Features

* add the image builder with layer support ([fb729c7](https://github.com/yunielrc/vedv/commit/fb729c7b01f157b9def5402645a1c014a24076ef))
* add the options --chown, --chmod to copy command ([7395c14](https://github.com/yunielrc/vedv/commit/7395c14189c9fbc1e4767f2a5b04cb5df98b643b))
* add write to stdout functions ([77b61bf](https://github.com/yunielrc/vedv/commit/77b61bf847181391a4a604cf88d346277938e52d))
* **builder:** add POWEROFF instruction ([d42f084](https://github.com/yunielrc/vedv/commit/d42f0846972d1002fa33db65163c280b42770203))
* **cac:** add a function to add an user for vedv ([c5c8097](https://github.com/yunielrc/vedv/commit/c5c809739c38923e850ad94d4563dbc6e87da995))
* **cac:** add script to configure alpine linux vm image for vedv ([6ef371b](https://github.com/yunielrc/vedv/commit/6ef371b0419fae8e71600df44dfdedfdb6499e1e))
* **cac:** install bash on alpine linux vm image ([97648d6](https://github.com/yunielrc/vedv/commit/97648d6f15123e7fca1c2182b52981fb6f5dc509))
* **cac:** install rsync on alpine linux vm image ([ea69d14](https://github.com/yunielrc/vedv/commit/ea69d14384f020032b95f803f085c45c161d9fdf))
* change the design of the system ([09fd751](https://github.com/yunielrc/vedv/commit/09fd751be60b31d32df58ce9625b3a5c4f66a51d))
* **container-command:** add options --workdir, --env, --user to container exec command ([9520178](https://github.com/yunielrc/vedv/commit/9520178bf912fd123e02a13ee4ebce0818c873bf))
* **container:** add a command to kill containers ([dcba556](https://github.com/yunielrc/vedv/commit/dcba55626f5557cd892cbc51c48e6fa357c66d81)), closes [#5](https://github.com/yunielrc/vedv/issues/5)
* **container:** add a command to restart containers ([47e14d2](https://github.com/yunielrc/vedv/commit/47e14d2781d3f3d216e15fe85623ab6c24927589)), closes [#4](https://github.com/yunielrc/vedv/issues/4)
* **container:** add a command to show container exposed ports ([3d6c128](https://github.com/yunielrc/vedv/commit/3d6c128c60496eb1dde3a0eb1c488ab1c08487e6))
* **container:** add a command to show container published ports ([f47c234](https://github.com/yunielrc/vedv/commit/f47c23453fb5607c572916a3063ab46d0f06fa33))
* **container:** add an option to container start to show the gui ([60c8b80](https://github.com/yunielrc/vedv/commit/60c8b80398d2b0bd8105e717a59d2d528f99b52a))
* **container:** add an option to create a container from image fqn ([e88a3f3](https://github.com/yunielrc/vedv/commit/e88a3f37de01c70141a08cf813a5fbc9be029fad))
* **container:** add an option to execute a command on container as a given user ([610d80f](https://github.com/yunielrc/vedv/commit/610d80f3431ae889ab91f3166f2d6d3c7d251cf0))
* **container:** add an option to login (connect) as a given user ([bedf432](https://github.com/yunielrc/vedv/commit/bedf432c2aa642cae4a884e960c89e7c8081ece9))
* **container:** add an option to publish ports on container creation ([8f07e65](https://github.com/yunielrc/vedv/commit/8f07e6598f023fca3d4a523693c8c77bcc3b69be))
* **container:** add an option to publish random ports from all exposed ports on container creation ([d00606a](https://github.com/yunielrc/vedv/commit/d00606a0882cb95ac1c31a373b7d4eac2c76ee9d))
* **container:** add copy command to copy files to a container ([3e9fe69](https://github.com/yunielrc/vedv/commit/3e9fe6995da1eeddbc55ca6e90c39bff40e7c155))
* **container:** add create container ([8feb754](https://github.com/yunielrc/vedv/commit/8feb754ddd8e18184e459533a455984fad9ead69))
* **container:** add exec command to execute commands inside a running container ([025d9b1](https://github.com/yunielrc/vedv/commit/025d9b1969ec1e3780cd4b921febeafa5ebec0a5))
* **container:** add force flag to remove running containers ([d792d16](https://github.com/yunielrc/vedv/commit/d792d16be30f44273b2d0f53ef0b0a70f3d57e9a))
* **container:** add login command to connect to containers by ssh ([e3a597e](https://github.com/yunielrc/vedv/commit/e3a597e5528207f05d9f1eec2ecf6e01a53ce0d8))
* **container:** add rm containers feature ([ae747b0](https://github.com/yunielrc/vedv/commit/ae747b02219431c3cc255a7cbad5a9af081769bb))
* **container:** add start containers feature ([4af1c01](https://github.com/yunielrc/vedv/commit/4af1c011439e1dfb7795f36a6a3787ef6b0ba1fb))
* **container:** add stop containers feature ([f6eccd0](https://github.com/yunielrc/vedv/commit/f6eccd037ca28a178ce4191be6890d89c82cd41b))
* **container:** add support to copy files to a container as specific user ([c83605f](https://github.com/yunielrc/vedv/commit/c83605f7c8e1f49b056f44fa92565b290ab5b6d2))
* **container:** create standalone container independently of the image ([43f8894](https://github.com/yunielrc/vedv/commit/43f8894f3fc4816bc5c4b82e7d1d8bf9b0ea3195))
* design the system ([cc65efc](https://github.com/yunielrc/vedv/commit/cc65efc93b89d50ee8d94009e13699e718501818))
* **hypervisor:** add a config variable default_hypervisor ([2d0d9f4](https://github.com/yunielrc/vedv/commit/2d0d9f463432f9f3063fa758f7842adb932e7984))
* **hypervisor:** add a config variable hypervisor_frontend to show or hide vm gui ([b5ed19f](https://github.com/yunielrc/vedv/commit/b5ed19fcdad3dfaa36abc9134f0090a5023fb828))
* **image-builder:** add (ENV) environment variables to image filesystem ([4d524df](https://github.com/yunielrc/vedv/commit/4d524df5ce844a75c9198bb2130d6dadddd47745))
* **image-builder:** add an option to build the image from the beginning whithout layer cache ([7c6396f](https://github.com/yunielrc/vedv/commit/7c6396f9fab08c4348221e35cb0a37e41ac1fb42))
* **image-builder:** add an option to build the image from the beginning whithout layer cache ([cbb875c](https://github.com/yunielrc/vedv/commit/cbb875cf4274ff2f140e6166139cf7bd4912a59a))
* **image-builder:** add an option to RUN command on image build as a given user ([6954805](https://github.com/yunielrc/vedv/commit/6954805cd4dfa77d7975cb30bad0bb21aa4e40ad))
* **image-builder:** add force option to remove containers on image build ([952bdfe](https://github.com/yunielrc/vedv/commit/952bdfe544661417e9c893231653084e3c4a824d))
* **image-builder:** add support for exposing ports on image build ([be69737](https://github.com/yunielrc/vedv/commit/be697377c43da64f36777890b81a5215095e4cd2))
* **image-builder:** add support for set the default shell on build ([c8ba3b5](https://github.com/yunielrc/vedv/commit/c8ba3b54d571b2a965c1b9fbaa323db863e35b55))
* **image-builder:** add support for set USER on image build process ([ee6f24b](https://github.com/yunielrc/vedv/commit/ee6f24baba2a20d708487d1cf0aafde8c84445d2))
* **image-builder:** add support for set working directory (WORKDIR) on build ([b5b902b](https://github.com/yunielrc/vedv/commit/b5b902bce8012363f8b2015c26ed95d65e5ddee9))
* **image-builder:** add support for variable substitution in vedvfile ([cbca2ba](https://github.com/yunielrc/vedv/commit/cbca2ba76896efbd2329a1580c7523f7079ab786))
* **image-builder:** add the option to ignore files on the copy command during building an image ([6979f95](https://github.com/yunielrc/vedv/commit/6979f954af64d732593b3f53490d322419d98e12))
* **image-builder:** copy files as specific user during image building process ([3f5a93c](https://github.com/yunielrc/vedv/commit/3f5a93c19fbebb00d17e03e7290422fc835111fb))
* **image-entity:** add support for user name with '.' ([b0fb3d8](https://github.com/yunielrc/vedv/commit/b0fb3d862fe49364f572f9c1fbe1024f906c9c56))
* **image-entity:** allow user names with - ([2adf384](https://github.com/yunielrc/vedv/commit/2adf384d14d82d897fe612c7349f605a9dcd134b))
* **image-service:** change image generated password to the default one on image export ([77b17b2](https://github.com/yunielrc/vedv/commit/77b17b235a66326561fe4d1a7e32dd7e5487192b)), closes [#3](https://github.com/yunielrc/vedv/issues/3)
* **image,container:** add an instruction on builder and options to modify cpus and memory ([dc188bd](https://github.com/yunielrc/vedv/commit/dc188bdd4fc7274da872691be3af35634736f7cd))
* **image:** add a command to export image with checksum ([44ddae7](https://github.com/yunielrc/vedv/commit/44ddae78a2c0eb2c10e8c68ebd47837b6af47d8c))
* **image:** add a command to show image exposed ports ([8d9c516](https://github.com/yunielrc/vedv/commit/8d9c516cb9416d0750493aa2974a696802cb2700))
* **image:** add a feature to import an image from a local file ([a71316a](https://github.com/yunielrc/vedv/commit/a71316afd6cef00b9c5e8e4bcd4eacc5884a2d88))
* **image:** add a feature to import an image from the web with checksum ([02642e7](https://github.com/yunielrc/vedv/commit/02642e78c86c5d02ff9d7bf3df266e5fb4856e00))
* **image:** add command pull to download images from registry ([b3cb1d0](https://github.com/yunielrc/vedv/commit/b3cb1d0dc7c92b8a44c05b329c4f3173d54c3e0e))
* **image:** add command push to upload images to registry ([d29385c](https://github.com/yunielrc/vedv/commit/d29385cb791247d389cca41cabdea5dba57adbcf))
* **image:** add force flag to remove an image with containers ([f4c0001](https://github.com/yunielrc/vedv/commit/f4c0001bf68c2ae372074408df1b19b28cecdd2f))
* **image:** add image cache ([d90aed4](https://github.com/yunielrc/vedv/commit/d90aed42ceb2465ec3def823b12cea7e65d33483))
* **image:** add list containers feature ([2bef866](https://github.com/yunielrc/vedv/commit/2bef866216407291737a31e410f26c25822d6d92))
* **image:** add list images feature ([33b1e3b](https://github.com/yunielrc/vedv/commit/33b1e3b8506f7c7cd1ba6867fddf90391bad3e0c))
* **image:** add remove images feature ([02c1cd4](https://github.com/yunielrc/vedv/commit/02c1cd4677b7694257ca6e7f7917683498b83cd0))
* **image:** after build save state of image instead poweroff it to save time ([8c40e4a](https://github.com/yunielrc/vedv/commit/8c40e4a5f1cf02b502f1ef34f838dd17a9030446))
* **image:** change the password of all users on image import ([ad7c93c](https://github.com/yunielrc/vedv/commit/ad7c93c90d7ee41312c6d7e67fdcbab16a6781b1))
* **image:** generate vm image name with crc algorithm ([9a5d74d](https://github.com/yunielrc/vedv/commit/9a5d74dd5c4a75c041675fdc27ca0a060708f50b))
* **image:** generate vm image name with crc algorithm ([257e2d7](https://github.com/yunielrc/vedv/commit/257e2d7d5765098683d8a019d92773c59c61c950))
* **image:** pull an image from file ([b842aff](https://github.com/yunielrc/vedv/commit/b842aff2c9142be64836eefba849a32bbeeaba32))
* **image:** refactor download from url ([e599f38](https://github.com/yunielrc/vedv/commit/e599f3815cd9be65c193e3848733067afd2653ec))
* **registry:** add a command to clean registry cache ([6f6822b](https://github.com/yunielrc/vedv/commit/6f6822bcaf3649880cd770dbdc11bee716d84896))
* **registry:** add a command to push an image to nextcloud registry ([372e8c7](https://github.com/yunielrc/vedv/commit/372e8c7254a73d56ad97c94e7f2b33affb0a7542))
* **registry:** add a command to upload image reference to nextcloud registry ([cf31936](https://github.com/yunielrc/vedv/commit/cf3193697130525784622d774bf33760a8109a0b))
* **registry:** add a feat to pull an image from nextcloud registry ([70a3425](https://github.com/yunielrc/vedv/commit/70a34255778cb28e0939d79da279541961bd4a5d))
* **registry:** add support pull and push-link for google drive and onedrive ([4c7a3bc](https://github.com/yunielrc/vedv/commit/4c7a3bc8fd1c0358eb880d80bfa21767c8c01ff6))
* **registry:** create registry dir structure if doesn't exist ([3a3082b](https://github.com/yunielrc/vedv/commit/3a3082b002ce1ea4e9f47043823fd4aaafd924a1))
* **registry:** download image from registry reference to external source ([3a61b31](https://github.com/yunielrc/vedv/commit/3a61b316d05d97b6606d18d78960be8d9f1f749a))
* **registry:** remove temporary image and checksum after push ([e5e3901](https://github.com/yunielrc/vedv/commit/e5e39012af0f9ed83d1556ddaed43fba44659623))
* remove wilcard support on copy command by / ([09653f7](https://github.com/yunielrc/vedv/commit/09653f71ba25e60c5ecf7001cd1e42c22aa31a61))
* **ssh-client:** add connection timeout configuration variable ([c134ed4](https://github.com/yunielrc/vedv/commit/c134ed43178924e369ee2b5fe5709c67a6be4888))
* **utils:** add user agent to download file ([3cb6c03](https://github.com/yunielrc/vedv/commit/3cb6c03d1d319321a6131b3ff95a983b1d47e954))
* **vedvfile:** add comment support on Vedvfile ([c68380a](https://github.com/yunielrc/vedv/commit/c68380a45ad4a1a9d08c3e4966fffd04b7953255))
* **virtualbox:** implement take snapshot, import vm, clone linked vm ([564e948](https://github.com/yunielrc/vedv/commit/564e948d39f19346a91b5291493d6b1e54a796d4))
* **vmobj-entity:** add support for vmobj name with '.' ([8971f59](https://github.com/yunielrc/vedv/commit/8971f59e207f1df924cf2cc6ae804994441e09b2))


### Bug Fixes

* **builder-service:** fix invalid copy calc id when it has options like --root, --chmod, ([a2567d0](https://github.com/yunielrc/vedv/commit/a2567d07a2636c785311dfb3f17cbf20837468aa))
* **builder-service:** restore the last layer before building an image ([7a62a5c](https://github.com/yunielrc/vedv/commit/7a62a5c2039c5d054be41133f9c64c2f2bb0b813)), closes [#7](https://github.com/yunielrc/vedv/issues/7)
* **builder-service:** stop image after build without saving the state to start any service ([0ddec72](https://github.com/yunielrc/vedv/commit/0ddec7217734e27fcfe10292c7ccd7328f044732))
* **builder-service:** update the cached data when image is build with --no-cache ([968fa33](https://github.com/yunielrc/vedv/commit/968fa33f76cea961629200c1508709ec462e4fe0))
* **builder:** fix failed to calculate layer id for cmd: FROM admin@alpine/alpine-13 ([6f506e9](https://github.com/yunielrc/vedv/commit/6f506e95d97a191264afc19a670ab12a43bedaf3))
* **builder:** validate invalid argument for SYSTEM instruction ([2fdc1dc](https://github.com/yunielrc/vedv/commit/2fdc1dc8fc2f0aba0718daf868db26c86844b16a))
* **cac:** fix vedv-adduser name ([08ae2c9](https://github.com/yunielrc/vedv/commit/08ae2c96541da742fc32bbd49ac8a233872acf6d))
* **config:** remove backslash at end from default registry url in vedv.env ([9cfa02a](https://github.com/yunielrc/vedv/commit/9cfa02ac2fd1244dc853f4a5cd918e56468c1b69))
* **config:** remove VEDV_ prefix from config variables ([c599385](https://github.com/yunielrc/vedv/commit/c5993851720bf4200e1a79d3bd9c76ebfb5a2273))
* **container:** container creation return the container name instead container vm name ([8d88912](https://github.com/yunielrc/vedv/commit/8d88912ad4e5dba8022d3bc02a676a0b4aedb4f6))
* **container:** delete orphan snapshot from image when child container is removed ([ace46a1](https://github.com/yunielrc/vedv/commit/ace46a1c9f6268cc797885d01101022034101ab2))
* **container:** fix hiding return code ([0ef6acc](https://github.com/yunielrc/vedv/commit/0ef6accf9e6cd9bba975cd5bb8c70104dba24ed7))
* **container:** fix unbound variable in container creation ([303d3d1](https://github.com/yunielrc/vedv/commit/303d3d1577ab5814027bd3d774c922a4b501148e))
* **container:** remove readonly attribute for container_name variable ([06d0dca](https://github.com/yunielrc/vedv/commit/06d0dca4bae07b48fa0de7cc57ca87d54ef7320f))
* **file-downloader:** add a connect timeout config variable to avoid timemouts ([4931ac2](https://github.com/yunielrc/vedv/commit/4931ac25fdd3f24c573b2994342a6ccc82795fee))
* **file-downloader:** remove null bytes to avoid bash warning ([642cfce](https://github.com/yunielrc/vedv/commit/642cfcef78ae66dd1242029e7bf9a9d29de37e18))
* filter vms with a regex including the type ([1cd12ec](https://github.com/yunielrc/vedv/commit/1cd12ec16b1e3d78037637b7745507f1c0351acf))
* **hadolint:** disable hadolint by default for incompatibility ([f2f81a1](https://github.com/yunielrc/vedv/commit/f2f81a10806aa3262b3fb643c9b993f030e13303))
* **image:** __pull_from_file print only the name of vm ([c1e3e4c](https://github.com/yunielrc/vedv/commit/c1e3e4c95039e0442582e7190d1cd87feaafb4e2))
* **image-builder:** allow copy files with spaces in its names ([1e664f1](https://github.com/yunielrc/vedv/commit/1e664f1f98a7b9ad9386570b7b3cf99d95ea0a9e))
* **image-builder:** now workdir with quotes works in vedvfile ([c565e17](https://github.com/yunielrc/vedv/commit/c565e17cdfc71901c09021b20401c2e89d01c520))
* **image-builder:** on build delete the image only when its really corrupted ([c68bc62](https://github.com/yunielrc/vedv/commit/c68bc626149f0e8531e6d3cd160d847bd3dac985))
* **image-builder:** remove quotes from user name on run command ([a74629d](https://github.com/yunielrc/vedv/commit/a74629d318aeb5280620dffae99ceb17f185b059))
* **image-builder:** save the user workdir inside the image filesystem ([b4dcf21](https://github.com/yunielrc/vedv/commit/b4dcf2142e6024073784367ca6f0d73344295a63))
* **image-builder:** stop the image before build ([8c1a76b](https://github.com/yunielrc/vedv/commit/8c1a76b73aca710cc9a9f1990df992a878ca78cd))
* **image-builder:** user instruction work with quoted values ([bffca18](https://github.com/yunielrc/vedv/commit/bffca18955d0d0fda0b64362d9cf59c587f6dc6a))
* **image-service:** check and delete any image export clone after script execution ([270b2b7](https://github.com/yunielrc/vedv/commit/270b2b770280f8a55c4050ea72f6eb0b65f59ab6))
* **image-service:** delete only image clone if the process that creates it is not running ([45c7232](https://github.com/yunielrc/vedv/commit/45c7232ae0efde3bfa29e5f61ba3c3b492310de2))
* **image-service:** fix error that get an invalid directory for a file ([e3ed6ee](https://github.com/yunielrc/vedv/commit/e3ed6ee053f840f81df6399df158b55721a191c1))
* **image-service:** fix the problem when on image removal fail to delete the snapshot in image-cache ([002bcc0](https://github.com/yunielrc/vedv/commit/002bcc01569e1b283654f183151994b8a5cafda7))
* **image-service:** fix to return correct image id when importing from an existing image ([224a579](https://github.com/yunielrc/vedv/commit/224a57980af37b6b9da1307605ed76652ecbd792))
* **image:** add a last layer with a poweroff state ([27bdbb5](https://github.com/yunielrc/vedv/commit/27bdbb52867f18cd9d68c3f7ba163980467887c0))
* **image:** capture error for showing the error message ([9cd9306](https://github.com/yunielrc/vedv/commit/9cd9306eb26ba1745ef3d2a5ca54270eb259262a))
* **image:** fix the bug that all created images without custom name had the same ID ([8d04aad](https://github.com/yunielrc/vedv/commit/8d04aada98e833baf73113a595cc15a6d8faacd2))
* **image:** fix the vedfile parser, now can parse multiline arguments on instructions ([14008e1](https://github.com/yunielrc/vedv/commit/14008e18b83697029102dbff1fd8f973ab44d4b9))
* **image:** image creation return the image name instead image vm name ([dab8df2](https://github.com/yunielrc/vedv/commit/dab8df2272c109fa606b4d280fdd0a6974e78eb4))
* **image:** on image creation when it exists know print the image name ([840b689](https://github.com/yunielrc/vedv/commit/840b689a81644d944fd904aa81be577424c256b4))
* **image:** only import an ova image file if the vm doesn't exist ([ed8a12e](https://github.com/yunielrc/vedv/commit/ed8a12e10b4793310e0cf191d82e7b4004e06e38))
* **image:** save user inside the image filesystem to work with image layers ([d9d235e](https://github.com/yunielrc/vedv/commit/d9d235e15ec42bbe1f3b67cbfaaaba21b94d02ae))
* **image:** set the image vm name on image creation ([212ea29](https://github.com/yunielrc/vedv/commit/212ea2933833160f885a6131b10ceda9469be2c8))
* **install:** add sudo to the internals commands instead invoking sudo make install ([9c738c3](https://github.com/yunielrc/vedv/commit/9c738c3207bec5f0fa75ae4e680f59b682f1e86f))
* on copy command validate that src file exists ([126863f](https://github.com/yunielrc/vedv/commit/126863fba2848f82b31de094b3944c048d865b32))
* set the default workdir to empty value ([110ba27](https://github.com/yunielrc/vedv/commit/110ba27d3bf6a0e4ef44cee99047d0dce7752cad))
* set the ownership of the workdir to the user defined on vedvfile ([d8332b0](https://github.com/yunielrc/vedv/commit/d8332b0baf10f606d9fc9c7e75eefd252f4bed09))
* **ssh-client:** fix some images asking for password during waiting for start ([439815c](https://github.com/yunielrc/vedv/commit/439815c7d39a5f7ba2eb2a211f6b068476387ca6))
* **ssh-client:** fix the behavior that split quoted word with spaces ([7f22e27](https://github.com/yunielrc/vedv/commit/7f22e27bae647bbb8a79e72c15e630a71702ba19))
* **utils:** capture the error when calc_item_id_func_(a|b) function fails ([ab68232](https://github.com/yunielrc/vedv/commit/ab68232472ca641ab1ae7e80a2806849419337db))
* **utils:** file sum includes vedvignorefile ([dd09398](https://github.com/yunielrc/vedv/commit/dd093988d114f6f4bea56c1c171d6b49ca9e1a49))
* **utils:** get ports from ip_local_port_range ([7d018d2](https://github.com/yunielrc/vedv/commit/7d018d2abb97a8c4e34fa9d798a661773fcee1a8))
* **vedv:** show a message that qemu is not supported yet ([2b9523e](https://github.com/yunielrc/vedv/commit/2b9523eda798545a3f5cef9d4ad1f40bdc59ec83))
* virtualbox ([618c4bb](https://github.com/yunielrc/vedv/commit/618c4bb0df5dda4b1e65a0b054dfa4aa21dcefeb))
* **virtualbox:** delete the directory of non-existent vm during vm creation ([29f54b1](https://github.com/yunielrc/vedv/commit/29f54b1bfaaf3bc93fa41c7930aa39a995e701aa)), closes [#10](https://github.com/yunielrc/vedv/issues/10)
* **virtualbox:** fix vm creation error when virtualbox vms directory doesn't exist ([b057574](https://github.com/yunielrc/vedv/commit/b057574059378a3685764c9b5aee2d163f3d3702))
* **virtualbox:** switch off usb-ehci on import/export process ([476ac5b](https://github.com/yunielrc/vedv/commit/476ac5be57039b91b9dbff6067fe925b81ecbc5c)), closes [#6](https://github.com/yunielrc/vedv/issues/6)
* **vmobj-service:** fix duplicated ids on stop_one vmobj ([d552124](https://github.com/yunielrc/vedv/commit/d552124150f714016d7cb86864b381f3de905ab5))
* **vmobj-service:** fix the bug on list function that doesn't filter names correctly ([5e89bd3](https://github.com/yunielrc/vedv/commit/5e89bd3b6ee5f7bbcfc007b20ef433c97bc1ae50))
* **vmobj-service:** set bash as shell for adding env var and exposed ports ([4601e2c](https://github.com/yunielrc/vedv/commit/4601e2c7542c5e1d6df2c961f0107ce161b9e081))


### Performance Improvements

* **builder:** add support for no wait for executing the POWEROFF command ([9137fac](https://github.com/yunielrc/vedv/commit/9137fac2909cd9e2d5336107e45564092a158fd5))
* **container:** add a data cache, so containers can access data faster ([8148f0d](https://github.com/yunielrc/vedv/commit/8148f0d2ec483f93724d86ed04dc0ff00ad8f677))
* **container:** decrease around 900ms container login time ([63973df](https://github.com/yunielrc/vedv/commit/63973dfb724cd4d0022d93b9fcd8da67cf0ea693))
* **image-builder:** add an option to exit after the image is build without waiting for stopping it ([809f741](https://github.com/yunielrc/vedv/commit/809f741d05e0efa4535b2a6b4c837413d17cdfb7))
* **image-builder:** on build, it access image cached data to optimize time ([01e4586](https://github.com/yunielrc/vedv/commit/01e45863182310cae4c53fc63cba7bb5ddd7451d))
* **image-builder:** on built with --no-cache remove the layers except the first one ([8629222](https://github.com/yunielrc/vedv/commit/8629222048a3a2958cef548574e7469825d4f21e))
* **image,container:** implement a data cache mechanism ([dfb026c](https://github.com/yunielrc/vedv/commit/dfb026c3f417010c7ddc58cef825d5594606dc58))
* **registry-command.f:** fix cache test ([8e9ca51](https://github.com/yunielrc/vedv/commit/8e9ca51c212dcc6dc634d884b4e6008da6adc011))
* save image childs containers ids on a property instead layers ([25037e1](https://github.com/yunielrc/vedv/commit/25037e1ceadad0fc6aa624681f54fe3e8da7e904))
* **utils:** replace shuf with bash RANDOM ([d7eebc7](https://github.com/yunielrc/vedv/commit/d7eebc7b8a0963f0d97c26804d9afda636a15700))
* **virtualbox:** use pipe on vm list ([e8f1ba4](https://github.com/yunielrc/vedv/commit/e8f1ba46269daa1425301e70bf27be5f98ee25f3))
* **vmobj-entity:** add a cache to reduce access time to entity data ([f6da736](https://github.com/yunielrc/vedv/commit/f6da736360aafb126777495a42ac6905dc544f62))
* **vmobj-entity:** add fn get_id to get it from name without query fs database ([720ab58](https://github.com/yunielrc/vedv/commit/720ab583c06eda64de599e26a26073a2e8e4abbf))
* **vmobj-entity:** cache vm_name property on memory ([069db24](https://github.com/yunielrc/vedv/commit/069db24e18d2d97c60748abf90c4be380ac51d91))


### Miscellaneous Chores

* release 0.2.0 ([1035d19](https://github.com/yunielrc/vedv/commit/1035d199cafa4c87e45166f643103c44933bb00a))
