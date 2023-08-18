.PHONY: commit test-all test-unit test-tag test-name untested manjaro-dev-configure nextcloud-dev-setup nextcloud-dev-stop nextcloud-dev-destroy nextcloud-dev-start nextcloud-dev-status nextcloud-dev-ssh nextcloud-prod-setup install uninstall

commit:
	git cz

test-all:
	./tools/bats --recursive dist/test

test-unit:
	./tools/bats $(u)

test-tag:
	./tools/bats --filter-tags '$(t)' $(u)

test-name:
	./tools/bats --filter '$(n)' $(u)

untested:
	./tools/untested $(f)

manjaro-dev-configure:
	./icac/manjaro.local.dev.cac

nextcloud-dev-setup:
	./icac/nextcloud/vm.dev/nextcloud.vbox.dev.iac

nextcloud-dev-stop:
	sudo -u root VBoxManage controlvm nextcloud-dev acpipowerbutton

nextcloud-dev-destroy:
	sudo -u root VBoxManage controlvm nextcloud-dev poweroff && \
		sudo -u root VBoxManage unregistervm nextcloud-dev --delete

nextcloud-dev-start:
	sudo -u root VBoxManage startvm nextcloud-dev --type headless

nextcloud-dev-status:
	sudo -u root VBoxManage showvminfo nextcloud-dev | grep State

nextcloud-dev-ssh:
	ssh -p 40022 user@127.0.0.1

nextcloud-prod-setup:
	./icac/nextcloud/vultr.prod/nextcloud.vultr.prod.iac

install-m:
	sudo ./install --os manjaro --depends

install:
	sudo ./install

uninstall:
	sudo ./uninstall
