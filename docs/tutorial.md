# Tutorial

Choose [`PB_BAR`](../src/bar/pb_bar.e) when your application reports completed
work, [`PB_ITERABLE [G]`](../src/iteration/pb_iterable.e) to traverse a source,
or [`PB_STEP_BAR`](../src/iteration/pb_step_bar.e) for numbered steps.

## Add the library

Place the repository in your application tree, for example as a submodule:

```console
git submodule add https://github.com/samedit66/progress_bar.git vendor/progress_bar
```

Add its ECF to your application target:

```xml
<library name="progress_bar"
    location="./vendor/progress_bar/progress_bar.ecf"
    readonly="true"/>
```

The library requires only the compiler's ELKS base library.

## Report work manually

Creation is silent. Configure the bar, then call `start` to show zero before the
first operation. Reaching the total finishes automatically:

```eiffel
local
    bar: PB_BAR
do
    create bar.make_with_total (100)
    from bar.start until bar.is_finished loop
        do_work
        bar.forth
    end
end
```

`progress: INTEGER_64` counts completed units. `forth` adds one, `forth_by` adds a
signed amount, and `set_progress` sets an absolute value. Updates also start a bar
lazily, so `start` is optional when no initial frame is needed:

```eiffel
create bar.make_with_total (100)
bar.forth_by (40)
bar.forth_by (-10) -- Correct back to 30.
bar.set_progress (100) -- Finishes automatically.
```

Values are clamped to zero and, for known progress, the total. A zero total is
already finished and produces no output. `start` is idempotent and never resets
progress. Create another bar for another operation.

For callbacks reporting absolute progress, use `agent bar.set_progress`.

## Work without a total

```eiffel
create bar.make_unknown
bar.start
across incoming_items as item loop
    consume (item)
    bar.forth
end
bar.finish
```

The default formatter uses a spinner. Each update or `pulse` changes its revision;
there is no background animation during a long operation. `pulse` does not add
completed work and is available for unknown totals.

`finish` also stops known progress early, preserving the actual completed amount:

```eiffel
create bar.make_with_total (100)
bar.set_progress (40)
bar.finish -- Final result is 40/100.
```

## Traverse a source

```eiffel
local
    progress: PB_ITERABLE [STRING]
do
    create progress.make_over (items)
    across progress as item loop
        process (item)
    end
end
```

The wrapper retains your source without copying it. Each traversal creates a fresh
source cursor and its own progress state. A source conforming to `FINITE [G]`
supplies its count at traversal creation; otherwise the total is unknown.
Do not change the source's size during traversal.

The automatic cursor reports each completed body in `forth`, then finishes at
source exhaustion. Empty finite sources are silent. A repeated traversal starts
at zero, provided the source itself supports repeated traversal.

The wrapper has no `start`, `forth`, or `finish`. Use a manual bar if you need early
cancellation or exception cleanup: a cursor receives no automatic notification
when the body raises or the enclosing loop exits early.

## Traverse numbered steps

```eiffel
local
    steps: PB_STEP_BAR
do
    create steps.make_with_total (100)
    across steps as step loop
        do_work (step)
    end
end
```

Steps are `INTEGER` values from 1 through the total, generated without allocating
an item list. `PB_STEP_BAR` inherits `PB_ITERABLE [INTEGER]` and its configuration.
For an arbitrary interval, wrap an ordinary `INTEGER_INTERVAL` with `make_over`.

## Coordinate nested or independent bars

Each manual bar and iterable owns a private display by default. For overlapping
output, share one with `set_display`:

```eiffel
local
    files, parts: PB_STEP_BAR
do
    create files.make_with_total (3)
    create parts.make_with_total (10)
    parts.set_display (files.display)

    across files as file_number loop
        across parts as part_number loop
            process_part (file_number, part_number)
        end
    end
end
```

The outer row appears first. Each inner traversal gets a fresh row below it, then
removes that row at completion. Only after the outer body completes does the outer
count advance. At the end, the outer result remains.

The automatic retention rule depends on active rows, not lexical nesting: a bar
started on an idle display keeps its result; a bar started while others are active
removes it. Override before starting with `keep_final_line` or `discard_final_line`.
For an iterable, these commands configure future cursors.

Manual bars can share the same way:

```eiffel
create downloads.make_with_total (100)
create indexing.make_unknown
indexing.set_display (downloads.display)
indexing.keep_final_line -- Keep this independent operation's result too.
downloads.start
indexing.start
```

A manual bar's display cannot change after it starts or finishes. A zero-total bar
may receive a display because it never registers a row. Iterable configuration
changes affect future cursors only. Sharing copies the display reference; replacing
one object's display later does not redirect other objects.

Each bar has an independent lifecycle. Finishing one operation leaves the other
operations on its display active.

## Configure formatting

```eiffel
local
    bar: PB_BAR
do
    create bar.make_with_total (100)
    bar.set_line_formatter ({PB_FORMATTERS}.standard_formatter ("Compiling", "classes", "ready"))
    bar.start
end
```

Built-ins are class features: `basic_formatter`, `unicode_formatter`,
`compact_formatter`, `counter_formatter`, and `minimal_formatter`.
No formatter factory object is required.
The setter itself is silent; a manual bar uses the formatter on its next refresh.
Iterable cursors copy their formatter when created. See [custom formatters](formatters.md).

## Write messages

Use `put_line` to write above active progress without corrupting its rows:

```eiffel
across progress as item loop
    process (item)
    progress.put_line ("Processed " + item)
end
```

This also works on a manual bar. Finished manual bars ignore messages; use
`bar.display.put_line` for messages after completion. Multiline messages are allowed,
while each formatter must return exactly one physical line.
