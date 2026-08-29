GOBO ?= $(HOME)/Projects/gobo
GEC ?= $(GOBO)/bin/gec
GELINT ?= $(GOBO)/bin/gelint
GETEST ?= $(GOBO)/bin/getest
GEDOC ?= $(GOBO)/bin/gedoc
EC ?= ec

GOBO_FLAGS = --variable=GOBO_EIFFEL=ge --ise=25.12 --gelint
ISE_TEST_FLAGS ?= -clean
ISE_TEST_CODE_DIR ?= W_code
EIFFEL_TARGETS ?= progress_bar.ecf@progress_bar examples/quick_start/quick_start.ecf@quick_start
EIFFEL_FORMAT_SOURCES ?= $(shell git ls-files '*.e')

.PHONY: all check check-gobo check-ise format gobo ise test generate-tests \
	test-gobo test-ise test-ise-finalized clean

all: gobo

check: check-gobo check-ise

check-gobo:
	@set -e; for system in $(EIFFEL_TARGETS); do \
		ecf=$${system%@*}; target=$${system#*@}; \
		GOBO_EIFFEL=ge $(GELINT) --variable=GOBO_EIFFEL=ge --ise=25.12 \
			--target="$$target" "$$ecf"; \
	done

check-ise:
	@set -e; for system in $(EIFFEL_TARGETS); do \
		ecf=$${system%@*}; target=$${system#*@}; \
		GOBO="$(GOBO)" GOBO_EIFFEL=ise $(EC) -batch -config "$$ecf" \
			-target "$$target" -clean -ca_default -ca_class -all; \
	done

format:
	@set -e; formatter="$(abspath $(GEDOC))"; \
	for source in $(EIFFEL_FORMAT_SOURCES); do \
		directory=$${source%/*}; filename=$${source##*/}; \
		(cd "$$directory" && GOBO="$(GOBO)" GOBO_EIFFEL=ge \
			"$$formatter" --silent --force "$$filename"); \
	done

gobo:
	GOBO_EIFFEL=ge $(GEC) $(GOBO_FLAGS) --target=quick_start examples/quick_start/quick_start.ecf
	./progress_bar_quick_start

ise:
	GOBO="$(GOBO)" GOBO_EIFFEL=ise $(EC) -batch -clean \
		-config examples/quick_start/quick_start.ecf -target quick_start -c_compile
	./EIFGENs/quick_start/W_code/progress_bar_quick_start

test: test-gobo test-ise

generate-tests:
	$(GETEST) -g tests/getest.cfg

test-gobo: generate-tests
	GOBO="$(GOBO)" GOBO_EIFFEL=ge $(GEC) $(GOBO_FLAGS) \
		--target=pb_tests progress_bar.ecf
	./pb_tests

test-ise: generate-tests
	GOBO="$(GOBO)" GOBO_EIFFEL=ise $(EC) -batch -config progress_bar.ecf \
		-target pb_tests $(ISE_TEST_FLAGS) -c_compile
	./EIFGENs/pb_tests/$(ISE_TEST_CODE_DIR)/pb_tests

test-ise-finalized:
	$(MAKE) test-ise ISE_TEST_FLAGS="-clean -finalize -keep" ISE_TEST_CODE_DIR=F_code

clean:
	rm -rf build EIFGENs progress_bar_quick_start progress_bar_quick_start.exe \
		pb_tests pb_tests.exe
