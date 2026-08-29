<div align="center">

# `progress_bar`

### Portable terminal progress bars for Eiffel

[![Language: Eiffel](https://img.shields.io/badge/language-Eiffel-6f42c1)](https://www.eiffel.org/)
[![ISE Eiffel](https://img.shields.io/badge/toolchain-ISE%20Eiffel-17365D)](https://www.eiffel.com/)
[![Gobo Eiffel](https://img.shields.io/badge/toolchain-Gobo%20Eiffel-8B5A2B)](https://www.gobosoft.com/)
[![Platforms](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-2f855a)](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml)
[![CI](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml)

</div>

`progress_bar` is a void-safe, ELKS-only Eiffel library for terminal progress.
It supports direct updates, unknown totals with a spinner, and transparent
`across` traversal. Presentation is an agent, so applications can define
labels, units, counters, rates, or any domain-specific suffix without coupling
the progress state to those concerns.

The public classes use the `PB_` prefix and compile with both EiffelStudio and
Gobo Eiffel.

## Installation

Add the repository to an Eiffel project. A Git submodule keeps the selected
revision explicit:

```console
git submodule add https://github.com/samedit66/progress_bar.git vendor/progress_bar
git submodule update --init
```

Reference the package from the consuming ECF file:

```xml
<library name="progress_bar"
    location="./vendor/progress_bar/progress_bar.ecf"
    readonly="true"/>
```

There are no production dependencies beyond the compiler's ELKS base library.

## Quick start

Manual progress with a known total:

```eiffel
local
    bar: PB_BAR
    i: INTEGER_64
do
    create bar.make (100)
    from i := 0 until i > 100 loop
        bar.update (i)
        i := i + 1
    end
    bar.finish
end
```

Use the explicit unknown-total constructor when no count is available:

```eiffel
create bar.make_unknown
bar.update (items_seen)
bar.pulse
bar.finish
```

Wrap any `ITERABLE [G]` for an `across` loop:

```eiffel
local
    progress: PB_ITERABLE [MY_ITEM]
do
    create progress.make (items)
    across progress as item loop
        process (item)
    end
end
```

If `items` also conforms to `FINITE [MY_ITEM]`, each traversal uses its
`count`. Otherwise the cursor uses unknown-total progress. Every call to
`new_cursor` owns an independent bar.

To add labels and units, use a configured built-in formatter:

```eiffel
local
    bar: PB_BAR
    formatters: PB_FORMATTERS
do
    create formatters
    create bar.make_with_formatter (
        250,
        formatters.standard ("Compiling", "classes", "ready")
    )
end
```

Continue with the [tutorial](docs/tutorial.md). The
[reference guide](docs/reference.md) defines lifecycle and iteration
semantics, while [custom formatters](docs/formatters.md) covers pure and
stateful formatter agents. A complete program is in
[`examples/quick_start`](examples/quick_start).

## Public API

| Class | Purpose |
| --- | --- |
| [`PB_BAR`](src/bar/pb_bar.e) | Manually update known or unknown progress |
| [`PB_ITERABLE [G]`](src/iteration/pb_iterable.e) | Add progress to an existing iterable |
| [`PB_PROGRESS`](src/progress/pb_progress.e) | Immutable snapshot passed to a formatter |
| [`PB_FORMATTERS`](src/formatter/pb_formatters.e) | Built-in and configured formatter agents |

`PB_ITERATION_CURSOR [G]` and `PB_TERMINAL_RENDERER` are implementation
classes. Individual feature signatures and contracts in the Eiffel classes are
the source of truth.

## Design boundaries

- Progress is synchronous: updates redraw the line; no worker or background
  animation is created.
- `PB_BAR` knows positions and totals, not bytes, downloads, tasks, or time.
- Formatters return text and own presentation policy. Stateful formatter
  objects can add application-specific measurements.
- Output goes to standard error and repeated formatted lines are not rewritten.
- The ASCII formatter is the default. Unicode output is opt-in.

## Development

Building requires Gobo Eiffel 26.06 and EiffelStudio 25.12 or later. The main
commands are:

```console
make gobo       # build and run the quick-start example with Gobo Eiffel
make ise        # build and run the quick-start example with EiffelStudio
make test       # run the shared GETEST suite with both compilers
make check      # run gelint and the EiffelStudio Code Analyzer
make format     # format tracked Eiffel sources with gedoc
```

CI runs the shared test suite on Ubuntu, macOS, and Windows.
