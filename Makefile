SHELL=/bin/bash

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

test-unit:
	./tools/bats-unit

test-integration:
	./tools/bats-integration

test-functional:
	./tools/bats-functional

test-all: test-unit test-integration test-functional
	# MANDATORY ENV VARS: OS
	./tools/update-pkgs-versions

test-all-ci: test-unit test-integration test-functional

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
	sudo -H -u root VBoxManage controlvm nextcloud-dev acpipowerbutton

registry-dev-destroy:
	sudo -H -u root VBoxManage controlvm nextcloud-dev poweroff; \
		sudo -H -u root VBoxManage unregistervm nextcloud-dev --delete

registry-dev-start:
	sudo -H -u root VBoxManage startvm nextcloud-dev --type headless

registry-dev-status:
	sudo -H -u root VBoxManage showvminfo nextcloud-dev | grep State

registry-dev-ssh:
	# password: user
	ssh -p 40022 user@127.0.0.1

registry-prod-setup:
	./icac/nextcloud/vultr.prod/nextcloud-aio/nextcloud-aio.vultr.iac

