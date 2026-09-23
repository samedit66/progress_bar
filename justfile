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
    for source in src/*.e src/renders/*.e tests/*.e examples/*/*.e; do (cd "$(dirname "$source")" && GOBO_EIFFEL=ge "{{ gedoc }}" --silent --force "$(basename "$source")") || exit; done

# Generate the Eiffel test classes used by both backends.
generate-tests:
    "{{ getest }}" -g tests/getest.cfg

# Compile and run the test suite with Gobo Eiffel.
test-gobo: generate-tests
    GOBO_EIFFEL=ge "{{ gec }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --gelint --target=pb_tests progress_bar.ecf
    ./pb_tests{{ exe }}

# Compile and run the test suite with EiffelStudio.
test-ise: generate-tests
    GOBO_EIFFEL=ise "{{ ec }}" -batch -clean -config progress_bar.ecf -target pb_tests -c_compile
    ./EIFGENs/pb_tests/W_code/pb_tests{{ exe }}

# Generate and run the test suite with both Eiffel backends.
test: test-gobo test-ise

# Check the library and quick-start configuration with both Eiffel backends.
check:
    GOBO_EIFFEL=ge "{{ gelint }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --target=progress_bar progress_bar.ecf
    GOBO_EIFFEL=ge "{{ gelint }}" --variable=GOBO_EIFFEL=ge --ise=25.12 --target=quick_start examples/quick_start/quick_start.ecf
    GOBO_EIFFEL=ise "{{ ec }}" -batch -config progress_bar.ecf -target progress_bar -ca_default -ca_class -all
    GOBO_EIFFEL=ise "{{ ec }}" -batch -config examples/quick_start/quick_start.ecf -target quick_start -ca_default -ca_class -all

# Make a gif illustration for the README.md.
gif:
    # Temporary macOS workaround for Gobo's generated fork() declaration.
    # This fix exists until I send the PR to the gobo.
    cd examples/demo && GOBO_EIFFEL=ge "{{ gec }}" --cc=no --variable=GOBO_EIFFEL=ge --ise=25.12 --gelint --target=demo demo.ecf
    cd examples/demo && perl -0pi -e 's/\A/#include <unistd.h>\n/' .gobo/progress_bar_demo.h
    cd examples/demo/.gobo && ./progress_bar_demo.sh
    cd examples/demo && mv .gobo/progress_bar_demo ./progress_bar_demo
    cd examples/demo && vhs demo.tape
    cd examples/demo && ffmpeg -y -framerate 30 -pattern_type glob -i 'demo-frames/frame-text-*.png' -vf 'split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=sierra2_4a' -loop 0 demo.gif
    cd examples/demo && rm -rf ./demo-frames/ ./.gobo ./progress_bar_demo
