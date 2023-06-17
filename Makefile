.PHONY: commit test-all test-unit test-tag configure-dev-manjaro untested

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

configure-dev-manjaro:
	./cac/configure.dev.manjaro
