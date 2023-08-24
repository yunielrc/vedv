.PHONY: install uninstall configure-manjaro commit test-all test-unit test-tag test-name untested nextcloud-dev-setup nextcloud-dev-stop nextcloud-dev-destroy nextcloud-dev-start nextcloud-dev-status nextcloud-dev-ssh nextcloud-prod-setup
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
	./tools/update-pkgs-versions && \
	./tools/update-readme

test-unit:
	./tools/bats $(u)

test-tag:
	./tools/bats --filter-tags '$(t)' $(u)

test-name:
	./tools/bats --filter '$(n)' $(u)

untested:
	./tools/untested $(f)

nextcloud-dev-setup:
	./icac/nextcloud/vm.dev/nextcloud.vbox.iac

nextcloud-dev-stop:
	sudo -u root VBoxManage controlvm nextcloud-dev acpipowerbutton

nextcloud-dev-destroy:
	sudo -u root VBoxManage controlvm nextcloud-dev poweroff; \
		sudo -u root VBoxManage unregistervm nextcloud-dev --delete

nextcloud-dev-start:
	sudo -u root VBoxManage startvm nextcloud-dev --type headless

nextcloud-dev-status:
	sudo -u root VBoxManage showvminfo nextcloud-dev | grep State

nextcloud-dev-ssh:
	ssh -p 40022 user@127.0.0.1

nextcloud-prod-setup:
	./icac/nextcloud/vultr.prod/nextcloud-aio/nextcloud-aio.vultr.iac

