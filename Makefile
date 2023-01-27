.PHONY: commit test-all test-unit test-tag configure-dev-manjaro

commit:
	git cz

test-all:
	./tools/bats --recursive dist/test

test-unit:
	./tools/bats $(u)

test-tag:
	./tools/bats --filter-tags $(t) $(u)

configure-dev-manjaro:
	./cac/configure.dev.manjaro
