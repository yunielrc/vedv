.PHONY: commit test-all test-unit test-tag test-name untested configure-dev-manjaro

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
	./icac/nextcloud/nextcloud.vbox.dev.iac

nextcloud-dev-stop:
	sudo -u root VBoxManage controlvm nextcloud-dev acpipowerbutton

nextcloud-dev-destroy:
	sudo -u root VBoxManage controlvm nextcloud-dev poweroff && \
		sudo -u root VBoxManage unregistervm nextcloud-dev --delete

nextcloud-dev-start:
	sudo -u root VBoxManage startvm nextcloud-dev --type headless

nextcloud-dev-status:
	sudo -u root VBoxManage showvminfo nextcloud-dev | grep State
