# Tutorial

This tutorial covers the two ways to drive `progress_bar`: explicitly through
`PB_BAR`, or implicitly while traversing a `PB_ITERABLE [G]`.

## Add the library

Place the repository in the application tree and add it to the application
target:

```xml
<library name="progress_bar"
    location="./vendor/progress_bar/progress_bar.ecf"
    readonly="true"/>
```

The library is void-safe and depends only on the ELKS base library.

## Update a known total manually

Construct `PB_BAR` with a non-negative total, report absolute positions, then
finish the line:

```eiffel
local
    bar: PB_BAR
    completed: INTEGER_64
do
    create bar.make (jobs.count)
    across jobs as job loop
        run (job)
        completed := completed + 1
        bar.update (completed)
    end
    bar.finish
end
```

`update` is absolute, not an increment. This makes callback integration direct:
any producer that already reports `(position, total)` can bind
`agent bar.update` after constructing the bar with that total.

A known total of zero is valid and complete. It is deliberately different from
an unknown total.

## Work without a total

Use `make_unknown` or `make_unknown_with_formatter`; do not encode unknown as
zero:

```eiffel
create bar.make_unknown
across incoming_items as item loop
    consume (item)
    seen := seen + 1
    bar.update (seen)
end
bar.finish
```

The default formatter renders a spinner and the current position. `update`
advances the animation because each accepted update advances the snapshot
revision. If the position has not changed but a new frame is useful, call
`pulse`. Animation remains caller-driven and never creates a background task.

## Decorate an iterable

`PB_ITERABLE [G]` implements `ITERABLE [G]`, so it can be placed directly in an
`across` expression:

```eiffel
local
    progress: PB_ITERABLE [SOURCE_FILE]
do
    create progress.make (source_files)
    across progress as source_file loop
        compile (source_file)
    end
end
```

The wrapper asks the source for a fresh cursor. When the source also conforms
to `FINITE [G]`, the wrapper reads `count` for that traversal. A source that
only conforms to `ITERABLE [G]` receives unknown-total progress.

The progress position advances after the loop body has consumed each item.
Order, identity, and exceptions from the source cursor are not transformed.
An empty finite traversal renders the complete `0 / 0` state and finishes
without entering the loop body.

The wrapper retains the source rather than copying it. Every `new_cursor` call,
including every new `across`, creates an independent progress bar and observes
the source's count at that time.

## Traverse an integer range

`PB_RANGE` specializes `PB_ITERABLE [INTEGER]` for an inclusive integer
interval. Both bounds are visited:

```eiffel
local
    progress: PB_RANGE
do
    create progress.make_from_to (1, 100)
    across progress as index loop
        process (index)
    end
end
```

The example traverses `1` through `100` and reports a known total of 100. Equal
bounds produce one item. Reversed bounds produce a known empty traversal, which
renders and finishes at `0 / 0` without entering the loop body.

Use `make_from_to_with_formatter` to keep the same range semantics with any
existing formatter callback:

```eiffel
create progress.make_from_to_with_formatter (
    -2,
    2,
    formatters.standard ("Scanning", "indices", "complete")
)
```

The progress cursor reports its absolute processed-item count through
`PB_BAR.update`; callers do not update the bar from inside the `across` loop.

## Choose a built-in formatter

`PB_FORMATTERS` supplies reusable agents:

- `basic`: ASCII bar or ASCII spinner; the default;
- `unicode`: block bar or braille spinner;
- `compact`: percentage and counter without a graphical bar;
- `counter`: position and optional total;
- `minimal`: percentage or spinner only.

Pass one during construction:

```eiffel
local
    formatters: PB_FORMATTERS
do
    create formatters
    create bar.make_with_formatter (total, formatters.unicode)
end
```

`standard (label, unit, post_label)` returns an ASCII formatter with copied
affixes:

```eiffel
create bar.make_with_formatter (
    classes.count,
    formatters.standard ("Compiling", "classes", "ready")
)
```

The copies mean later mutation of the supplied strings cannot silently change
the formatter.

## Finish reliably

Call `finish` once the operation is done, including from rescue or cleanup code
when appropriate for the application. It writes the last formatted state and a
newline. `finish` is idempotent, so cleanup code may call it even when the
normal path has already done so.

After `finish`, `update` and `pulse` violate their `not_finished` precondition.
Construct a new bar for a new operation.
