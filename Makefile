VERONA ?= verona
VERONA_FORMATTER ?= verona-formatter
BUILD_DIR ?= dist

SOURCES := $(wildcard src/*.vrn tests/*.vrn)

.PHONY: all build test check check-format format clean

all: build

build:
	"$(VERONA)" build libc "$(BUILD_DIR)"

test:
	"$(VERONA)" build libc-tests "$(BUILD_DIR)"
	"$(BUILD_DIR)/libc-tests"

check: build test check-format

check-format:
	@set -e; for source in $(SOURCES); do \
		"$(VERONA_FORMATTER)" --check "$$source"; \
	done

format:
	@set -e; formatted=$$(mktemp); \
	trap 'rm -f "$$formatted"' EXIT; \
	for source in $(SOURCES); do \
		"$(VERONA_FORMATTER)" "$$source" > "$$formatted"; \
		if ! cmp -s "$$formatted" "$$source"; then \
			cat "$$formatted" > "$$source"; \
		fi; \
	done

clean:
	@test -n "$(BUILD_DIR)"
	rm -f -- "$(BUILD_DIR)/liblibc.a" "$(BUILD_DIR)/liblibc.h" "$(BUILD_DIR)/libc-tests"
