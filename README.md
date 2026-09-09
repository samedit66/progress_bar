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

Create a bar and report absolute progress. Reaching its total finishes it automatically:

```eiffel
local
    bar: PB_BAR
do
    create bar.make (100)
    bar.update (40)
    bar.update (100) -- Automatically finished; no finish call needed.
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
            child.advance (1)
        end
        parent.advance (1)
    end
end
```

A non-empty `make_child` starts a lazy parent automatically. The child shares its
parent's display and occupies a stable row below it. Finishing a parent, explicitly
or by reaching its total, also finishes all open descendants at their actual values.
Unrelated bars in the same `PB_DISPLAY` remain active.

Unknown totals (`make_unknown`), progress-safe messages (`put_line`), inclusive
integer ranges (`PB_RANGE`), and configured formatters are covered in the
[tutorial](docs/tutorial.md).

## Updating and stopping

`position` starts at `0` and reports the last accepted absolute value.
`update (value)` sets it; `advance (delta)` adds a signed increment. Negative values
are clamped to zero, and known progress is capped at its total. Reaching or exceeding
the total irreversibly finishes the bar.

```eiffel
create bar.make (100)
bar.advance (40)
bar.advance (-10) -- 30
bar.advance (80)  -- 100; automatically finished
```

Use `finish` to stop early, or to end manually driven progress with an unknown total:

```eiffel
create bar.make (100)
bar.update (40)
bar.finish -- Stops at 40, without claiming 100 completed.

create bar.make_unknown
bar.advance (7)
bar.finish -- An unknown total cannot trigger automatic completion.
```

A finished bar ignores all commands, including `put_line` and formatter changes.
Its queries remain readable. A zero total creates an already finished, silent bar.
Use a new bar for a new operation; use `display.put_line` to write messages after
completion.

## Formatting

Construct with the default formatter, then optionally call `set_formatter`:

```eiffel
local
    bar: PB_BAR
    formatters: PB_FORMATTERS
do
    create formatters
    create bar.make (100)
    bar.set_formatter (formatters.standard ("Compiling", "classes", "ready"))
    bar.update (100)
end
```

The default `basic` agent already selects a bar for known totals and a spinner for
unknown totals. `set_formatter` itself prints nothing; a manual bar uses the new
agent on its next refresh. `PB_ITERABLE` and `PB_RANGE` copy the configured formatter
to each new cursor, without changing existing traversals.

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

## API migration

Formatter-only constructor variants (`*_with_formatter`) have been removed from
`PB_BAR`, `PB_ITERABLE`, and `PB_RANGE`. Use the corresponding constructor without
that suffix, then `set_formatter (agent)`. Existing formatter agents, snapshots,
displays, iterables, and range behavior are reused; no new formatter class is needed.
Remove trailing `finish` calls after known totals are reached. Keep them for early
termination and manually driven unknown totals. Empty finite traversals now finish
silently without invoking the formatter.
