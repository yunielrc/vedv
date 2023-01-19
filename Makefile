.PHONY: commit test configure-dev-manjaro

commit:
	git cz

test:
	./tools/test-bats $(unit)

configure-dev-manjaro:
	./cac/configure.dev.manjaro
