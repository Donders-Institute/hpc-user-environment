PREFIX ?= /mnt/software
DRYRUN ?= true

SRC=$(shell find opt -type f)
DST=$(patsubst opt/%,${PREFIX}/%,$(SRC))

all: $(DST)

list:
	@printf "%s\n" $(DST)

$(PREFIX)/%: opt/%
	@if [ ! -e "$@" ] || ! diff -q "$<" "$@" >/dev/null 2>&1; then \
		msg="Installing"; \
		[ "${DRYRUN}" = "true" ] && msg="[DRYRUN]"; \
		echo "$$msg $< -> $@"; \
		if [ "${DRYRUN}" != "true" ]; then \
			mkdir -p $(dir $@); \
			cp -a "$<" "$@"; \
		fi; \
	else \
		msg="Unchanged"; \
		[ "${DRYRUN}" = "true" ] && msg="[DRYRUN] Unchanged"; \
		echo "$$msg: $@"; \
	fi
