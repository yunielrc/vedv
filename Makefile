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

configure-manjaro-dev:
	./icac/manjaro.local.dev.cac

setup-nextcloud-dev:
	./icac/nextcloud/nextcloud.multipass.dev.iac
