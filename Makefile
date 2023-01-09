.PHONY: commit test

commit:
	git cz

configure-dev-manjaro:
	./cac/configure.dev.manjaro

test:
	./tools/test-bats
