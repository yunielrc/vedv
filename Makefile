.PHONY: install uninstall configure commit test-all test-suite test-tag test-name untested registry-dev-setup registry-dev-stop registry-dev-destroy registry-dev-start registry-dev-status registry-dev-ssh registry-prod-setup
# grep -Po '^\S+(?=:)' Makefile | tr '\n' ' '

install:
	# OPTIONAL ENV VARS: OS, DESTDIR
	./install

uninstall:
	# OPTIONAL ENV VARS: FROMDIR
	./uninstall

configure:
	# MANDATORY ENV VAR: OS
	"./tools/install-pkgs-prod-${OS}" && \
	"./tools/install-pkgs-dev-${OS}"

commit:
	git cz

test-all:
	# MANDATORY ENV VARS: OS
	./tools/bats --recursive dist/test && \
	./tools/update-pkgs-versions

test-suite:
	./tools/bats $(u)

test-tag:
	./tools/bats --filter-tags '$(t)' $(u)

test-name:
	./tools/bats --filter '$(n)' $(u)

untested:
	./tools/untested $(f)

registry-dev-setup:
	./icac/nextcloud/vm.dev/nextcloud.vbox.iac

registry-dev-stop:
	sudo -u root VBoxManage controlvm nextcloud-dev acpipowerbutton

registry-dev-destroy:
	sudo -u root VBoxManage controlvm nextcloud-dev poweroff; \
		sudo -u root VBoxManage unregistervm nextcloud-dev --delete

registry-dev-start:
	sudo -u root VBoxManage startvm nextcloud-dev --type headless

registry-dev-status:
	sudo -u root VBoxManage showvminfo nextcloud-dev | grep State

registry-dev-ssh:
	# password: user
	ssh -p 40022 user@127.0.0.1

registry-prod-setup:
	./icac/nextcloud/vultr.prod/nextcloud-aio/nextcloud-aio.vultr.iac

