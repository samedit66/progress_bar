<div align="center">

# `progress_bar`

### Portable terminal progress bars for Eiffel

[![ISE Eiffel](https://img.shields.io/badge/toolchain-ISE%20Eiffel-17365D)](https://www.eiffel.com/)
[![Gobo Eiffel](https://img.shields.io/badge/toolchain-Gobo%20Eiffel-8B5A2B)](https://www.gobosoft.com/)
[![CI](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml)

</div>

`progress_bar` is a void-safe, ELKS-only Eiffel library for terminal progress.
It supports manual updates, unknown totals, `across` traversal, and nested or
independently coordinated bars. Formatter agents keep presentation separate
from progress state. The `PB_` public API compiles with EiffelStudio and Gobo
Eiffel.

## Installation

Add the repository as a submodule:

```console
git submodule add https://github.com/samedit66/progress_bar.git vendor/progress_bar
git submodule update --init
```

Reference it from the consuming ECF file:

```xml
<library name="progress_bar"
    location="./vendor/progress_bar/progress_bar.ecf"
    readonly="true"/>
```

There are no production dependencies beyond the compiler's ELKS base library.

## Quick start

Create a bar, report absolute progress, and finish it:

```eiffel
local
    bar: PB_BAR
do
    create bar.make (100)
    bar.update (40)
    bar.finish
end
```

Wrap an `ITERABLE [G]` for transparent `across` traversal:

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

Create nested progress directly from its parent:

```eiffel
local
    parent, child: PB_BAR
do
    create parent.make (files.count)
    across files as source_file loop
        create child.make_child (parent, source_file.part_count)
        child.discard_final_line
        across source_file.parts as part loop
            process (part)
            child.update (child.position + 1)
        end
        child.finish
        parent.update (parent.position + 1)
    end
    parent.finish
end
```

`make_child` starts a lazy parent automatically. The child shares its parent's
display and occupies a stable row below it; descendants must finish before their
parent. Use an explicit `PB_DISPLAY` to coordinate unrelated bars or iterable
traversals.

Unknown totals (`make_unknown`), progress-safe messages (`put_line`), inclusive
integer ranges (`PB_RANGE`), and configured formatters are covered in the
[tutorial](docs/tutorial.md).

## Documentation

- [Tutorial](docs/tutorial.md) for lifecycle, traversal, nesting, and ranges.
- [Reference](docs/reference.md) for complete API semantics and contracts.
- [Custom formatters](docs/formatters.md) for presentation agents and units.
- [Quick-start application](examples/quick_start) for a complete program.

## Public API

| Class | Purpose |
| --- | --- |
| [`PB_DISPLAY`](src/internal/pb_display.e) | Coordinate ordered top-level and nested progress lines |
| [`PB_BAR`](src/bar/pb_bar.e) | Manually update known or unknown progress |
| [`PB_ITERABLE [G]`](src/iteration/pb_iterable.e) | Add progress to an existing iterable |
| [`PB_RANGE`](src/iteration/pb_range.e) | Traverse an inclusive integer range with progress |
| [`PB_PROGRESS`](src/progress/pb_progress.e) | Immutable snapshot passed to a formatter |
| [`PB_FORMATTERS`](src/formatter/pb_formatters.e) | Built-in and configured formatter agents |

## Behavior and constraints

- Output is synchronous, written to standard error, and creates no background
  worker.
- A `PB_DISPLAY` belongs to one thread; separate displays do not coordinate.
- Multiline rendering uses ECMA-48 cursor movement and erase-line sequences.
- A formatter result is one physical line. `put_line` accepts multiline text.

## Development

Building requires Gobo Eiffel 26.06 and EiffelStudio 25.12 or later:

```console
make gobo       # build and run the quick-start example with Gobo Eiffel
make ise        # build and run the quick-start example with EiffelStudio
make test       # run the shared GETEST suite with both compilers
make check      # run gelint and the EiffelStudio Code Analyzer
make format     # format tracked Eiffel sources with gedoc
```

CI runs the shared test suite on Ubuntu, macOS, and Windows.
