# Tutorial

This tutorial covers explicit `PB_BAR` updates, nested progress, and implicit
progress while traversing a `PB_ITERABLE [G]`.

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

Construct `PB_BAR` with a non-negative total and report absolute positions.
Reaching the total finishes the line automatically:

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
end
```

`update` is absolute, not an increment. This makes callback integration direct:
any producer that already reports `(position, total)` can bind
`agent bar.update` after constructing the bar with that total.

`position` starts at zero. Use
`advance (delta)` for relative changes, including negative corrections:

```eiffel
create bar.make (100)
bar.advance (40)
bar.advance (-10) -- 30
bar.advance (80)  -- Clamps to 100 and finishes automatically.
```

Values below zero are clamped to zero. A known total of zero is already finished
and silent; it is different from an unknown total.

## Work without a total

Use `make_unknown`; do not encode unknown as zero:

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
An empty finite traversal is already complete, produces no output or formatter
callbacks, and does not enter the loop body.

The wrapper retains the source rather than copying it. Every `new_cursor` call,
including every new `across`, creates an independent progress bar and observes
the source's count at that time.

## Write messages without overwriting progress

Use `put_line` instead of writing directly to the terminal while a progress
line is active:

```eiffel
across progress as source_file loop
    compile (source_file)
    progress.put_line ("Compiled " + source_file.name)
end
```

The same command is available on a manually driven bar:

```eiffel
bar.update (completed)
bar.put_line ("Retrying failed operation")
```

The command clears the managed progress block, writes the supplied text followed
by one newline, and restores every cached line. It does not advance `position`
or `revision`, change the lifecycle, or invoke any formatter. Before the first
update it writes an ordinary line to standard error. A finished manual bar ignores
`put_line`; use `bar.display.put_line` or the iterable wrapper for later messages.

`PB_RANGE` inherits `put_line` from `PB_ITERABLE [INTEGER]`. All bars and cursors
created in one `PB_DISPLAY` are restored in stable order.

## Nest progress bars

Create a child directly from its parent. The first non-empty child starts a lazy parent
automatically, reuses its display, and occupies the next row below the parent's
descendants:

```eiffel
local
    files, chunks: PB_BAR
do
    create files.make (file_count)
    from file_index := 1 until file_index > file_count loop
        create chunks.make_child (files, chunks_in (file_index))
        chunks.discard_final_line
        from chunk_index := 1 until chunk_index > chunks_in (file_index) loop
            process_chunk (file_index, chunk_index)
            chunks.update (chunk_index)
            chunk_index := chunk_index + 1
        end
        files.update (file_index)
        file_index := file_index + 1
    end
end
```

Children may have their own children. Finishing a parent explicitly or by reaching
its total also finishes all open descendants at their actual values.
`has_open_children` exposes unfinished descendants. Child progress does not advance
or aggregate into its parent automatically. Empty children are silent and do not
start a lazy parent.

Final rows are kept by default. Call `discard_final_line` before the first
update to remove a completed row, or `keep_final_line` to state the default
explicitly. The policy cannot change after a `PB_BAR` starts.

## Coordinate unrelated progress

Use one explicit display when bars are not in a parent-child relationship but
must share the same terminal block:

```eiffel
local
    display: PB_DISPLAY
    downloads, indexing: PB_BAR
do
    create display.make
    create downloads.make_in (display, download_count)
    create indexing.make_unknown_in (display)
end
```

The same pattern works with `PB_ITERABLE.make_in` and `PB_RANGE.make_from_to_in`. Every traversal cursor receives its own stable display line. Changing
an iterable's final-line policy affects only cursors created afterwards.

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
finishes silently without entering the loop body.

Use `set_formatter` after construction for a custom range formatter:

```eiffel
create progress.make_from_to (-2, 2)
progress.set_formatter (formatters.standard ("Scanning", "indices", "complete"))
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

Set one after construction, before the first update:

```eiffel
local
    formatters: PB_FORMATTERS
do
    create formatters
    create bar.make (total)
    bar.set_formatter (formatters.unicode)
end
```

`standard (label, unit, post_label)` returns an ASCII formatter with copied
affixes:

```eiffel
create bar.make (classes.count)
bar.set_formatter (formatters.standard ("Compiling", "classes", "ready"))
```

The copies mean later mutation of the supplied strings cannot silently change
the formatter.

## Finish early or without a known total

Known progress completes automatically when `update` or `advance` reaches its
total. Use `finish` for early termination or manually driven unknown progress:

```eiffel
create bar.make (100)
bar.update (40)
bar.finish -- Stops at 40; does not claim all 100 items were processed.
```

Completion is irreversible and also stops open descendants at their actual values.
After completion every command on that bar does nothing. Repeated `finish` calls
are harmless but unnecessary. Construct a new bar for a new operation.

For `PB_ITERABLE` and `PB_RANGE`, each cursor has its own lifecycle. Exhaustion
finishes the bar, including unknown sources. Breaking out of an `across` loop early
or a source exception does not exhaust the cursor: use a manually driven `PB_BAR`
when explicit cancellation and cleanup are required.
