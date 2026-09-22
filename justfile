set windows-shell := ["sh", "-cu"]

export GOBO := env("GOBO", home_directory() / "Projects/gobo")
gec := env("GEC", GOBO / "bin/gec")
gelint := env("GELINT", GOBO / "bin/gelint")
getest := env("GETEST", GOBO / "bin/getest")
gedoc := env("GEDOC", GOBO / "bin/gedoc")
ec := env("EC", "ec")
exe := if os() == "windows" { ".exe" } else { "" }

# Build the quick-start application with both Eiffel backends.
build:
    GOBO_EIFFEL=ge "{{ gec }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --gelint --target=quick_start examples/quick_start/quick_start.ecf
    GOBO_EIFFEL=ise "{{ ec }}" -batch -clean -config examples/quick_start/quick_start.ecf -target quick_start -c_compile

# Format all Eiffel sources.
format:
    for source in src/*.e src/renders/*.e tests/*.e examples/quick_start/*.e; do (cd "$(dirname "$source")" && GOBO_EIFFEL=ge "{{ gedoc }}" --silent --force "$(basename "$source")") || exit; done

# Generate and run the test suite with both Eiffel backends.
test:
    "{{ getest }}" -g tests/getest.cfg
    GOBO_EIFFEL=ge "{{ gec }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --gelint --target=pb_tests progress_bar.ecf
    ./pb_tests{{ exe }}
    GOBO_EIFFEL=ise "{{ ec }}" -batch -clean -config progress_bar.ecf -target pb_tests -c_compile
    ./EIFGENs/pb_tests/W_code/pb_tests{{ exe }}

# Check the library and quick-start configuration with both Eiffel backends.
check:
    GOBO_EIFFEL=ge "{{ gelint }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --target=progress_bar progress_bar.ecf
    GOBO_EIFFEL=ge "{{ gelint }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --target=quick_start examples/quick_start/quick_start.ecf
    GOBO_EIFFEL=ise "{{ ec }}" -batch -config progress_bar.ecf -target progress_bar -ca_default -ca_class -all
    GOBO_EIFFEL=ise "{{ ec }}" -batch -config examples/quick_start/quick_start.ecf -target quick_start -ca_default -ca_class -all
