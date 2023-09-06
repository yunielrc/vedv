# grep -Po '^\S+(?=:)' Makefile | tr '\n' ' '
.PHONY: install uninstall configure configure-ci commit test-unit test-integration test-functional test-all test-all-ci test-suite test-tag test-name gen-manpages untested registry-dev-setup registry-dev-stop registry-dev-destroy registry-dev-start registry-dev-status registry-dev-ssh registry-prod-setup

install:
	# OPTIONAL ENV VARS: DESTDIR
	./install

install-deps-manjaro:
	./tools/install-pkgs-prod-manjaro

install-deps-ubuntu:
	./tools/install-pkgs-prod-ubuntu

uninstall:
	# OPTIONAL ENV VARS: FROMDIR
	./uninstall

configure:
	# MANDATORY ENV VAR: OS
	"./tools/install-pkgs-prod-${OS}" && \
	"./tools/install-pkgs-dev-${OS}"

configure-ci:
	# MANDATORY ENV VAR: OS
	"./tools/install-pkgs-prod-${OS}" && \
	"./tools/install-pkgs-ci-${OS}"

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

# ci server does not support VT-x so we can't run integration or functional tests
test-all-ci: test-unit

test-suite:
	./tools/bats $(u)

test-tag:
	./tools/bats --filter-tags '$(t)' $(u)

test-name:
	./tools/bats --filter '$(n)' $(u)

gen-manpages:
	# MANDATORY ENV VAR: DIR
	./tools/gen-manpages

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

