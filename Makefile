PREFIX ?= /mnt/software
DRYRUN ?= true

SRC=$(shell find opt -type f)
DST=$(patsubst opt/%,${PREFIX}/%,$(SRC))

all: $(DST)

list:
	@printf "%s\n" $(DST)

$(PREFIX)/%: opt/%
	@if [ "${DRYRUN}" == "true" ]; then \
		echo "[DRYRUN] $< -> $@"; \
	else \
		mkdir -p $(dir $@); \
		echo "Installing $< -> $@"; \
		cp -a "$<" "$@"; \
	fi

