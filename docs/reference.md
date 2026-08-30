# Reference

## `PB_BAR`

Creation procedures:

- `make (total)` creates known progress with the ASCII `basic` formatter;
- `make_with_formatter (total, formatter)` creates known formatted progress;
- `make_unknown` creates unknown progress with the default formatter;
- `make_unknown_with_formatter (formatter)` creates unknown formatted
  progress;
- `make_in (display, total)` and `make_in_with_formatter (display, total,
  formatter)` create known top-level progress in an existing display;
- `make_unknown_in (display)` and `make_unknown_in_with_formatter (display,
  formatter)` create unknown top-level progress in an existing display.

Known totals and positions must be non-negative. `update (position)` replaces
the absolute position, marks the bar started, advances `revision`, and invokes
the formatter. A known position may exceed its total; percentage and fraction
remain capped at complete.

`pulse` is valid only for unknown progress. It advances `revision` without
changing `position`, allowing a spinner or another revision-based formatter to
change frame.

`display` identifies the `PB_DISPLAY` coordinating the bar. A child shares its
parent's display and has a stable position after the parent and its existing
descendants. `new_child (total)` returns a lazy child with a known total and the
default formatter. If the parent is still lazy, creating its first child renders
the parent at its existing position and advances its revision once. Later child
creation does not refresh the parent. Child updates do not modify parent state.
`has_open_children` includes every unfinished descendant. A parent may finish
only after this query becomes false.

`finish` invokes the formatter with `is_final = True` and closes the line.
`keeps_final_line` is true by default. `keep_final_line` and
`discard_final_line` configure the policy before the first update or pulse. A
kept child row remains in display order until the entire display becomes idle;
a discarded row is removed on finish. Repeated `finish` calls do nothing.

The formatter is invoked for every accepted update, pulse, and first finish.
Only terminal output is deduplicated when two non-final calls return identical
text. Output is written synchronously to standard error and flushed.

`put_line (message)` writes `message` followed by one newline without
overwriting active progress. The command clears the complete display block and
restores every cached row afterward. It does not invoke any formatter or change
`position`, `revision`, `is_started`, or `is_finished`.
When the display is idle, it writes an ordinary line. Empty, Unicode, and
multiline strings are accepted; embedded newlines are preserved, and the
command still appends its own final newline. Output failures propagate to the
caller and may leave partially written terminal output.

## `PB_DISPLAY`

`make` creates an idle terminal display. Passing it to constructors ending in
`_in` coordinates unrelated bars and iterable cursors in one ordered terminal
block. `PB_BAR.new_child` derives the display from its parent, so callers do not
pass both values.

`put_line (message)` is equivalent to calling `put_line` on any associated bar
or iterable. A display performs synchronous writes to standard error and is a
single-thread ownership boundary; it contains no locks or background worker.

## `PB_PROGRESS`

Each formatter receives a frozen snapshot with:

- `position: INTEGER_64`;
- `revision: INTEGER_64`;
- `has_total: BOOLEAN`;
- `total: INTEGER_64`, available when `has_total`;
- `fraction: REAL_64` and `percentage: INTEGER`, available when `has_total`;
- `is_complete: BOOLEAN`;
- `is_final: BOOLEAN`.

For a known total of zero, `fraction = 1.0`, `percentage = 100`, and
`is_complete` is true. Unknown snapshots do not expose fraction, percentage, or
total: their preconditions make accidental division by an absent total visible
during development.

`revision` describes logical refresh requests, not time. It starts at one after
the first update or pulse. A final snapshot retains the current revision.

## `PB_ITERABLE [G]`

`make (source)` and `make_with_formatter (source, formatter)` retain an
`ITERABLE [G]` with a private display. `make_in (display, source)` and
`make_in_with_formatter (display, source, formatter)` use an existing display.
`new_cursor` creates a fresh source cursor, progress bar, and display line.

If the source dynamically conforms to `FINITE [G]`, its current `count` becomes
the cursor's known total. Otherwise the cursor uses unknown mode. The wrapper
does not require every iterable to pretend it has a count.

The cursor delegates `item` and `after` directly. Its `forth` first advances
the source cursor, then reports one completed item, and finishes when the source
cursor reaches `after`. Consequently the bar represents completed loop bodies.

`put_line` writes through the wrapper's display. Logical progress state remains
private to each cursor, and interleaved cursors retain independent stable rows.
`keeps_final_line`, `keep_final_line`, and `discard_final_line` configure future
cursors. A cursor copies the current policy when it is created; later changes
to the wrapper do not change that cursor.

## `PB_RANGE`

`PB_RANGE` is a `PB_ITERABLE [INTEGER]` backed by an `INTEGER_INTERVAL`.
Creation procedures are:

- `make_from_to (from, to)` for the default formatter;
- `make_from_to_with_formatter (from, to, formatter)` for a supplied formatter
  callback;
- `make_from_to_in (from, to, display)` for a supplied display;
- `make_from_to_in_with_formatter (from, to, display, formatter)` for both a
  supplied display and formatter.

Both bounds are inclusive. Equal bounds produce one item. When `from > to`, the
range is empty and its fresh cursor renders and finishes known `0 / 0` progress.
Every traversal otherwise has the same independent-bar and completed-loop-body
semantics as `PB_ITERABLE [G]`.

`PB_RANGE` inherits `put_line` from `PB_ITERABLE [INTEGER]`.

The cardinality of a non-empty range must fit in `INTEGER`, matching the
`INTEGER_INTERVAL` and `FINITE.count` contract. The range validates this using
wider arithmetic so that the check itself does not overflow near the limits of
`INTEGER`.

## `PB_FORMATTERS`

All formatter features return this contract:

```eiffel
FUNCTION [
    TUPLE [progress: PB_PROGRESS],
    READABLE_STRING_GENERAL
]
```

The renderer immediately copies the returned text into a `STRING_32`. A
formatter may therefore reuse its own result buffer after the call. Formatter
exceptions propagate to the caller; the library does not replace application
failure policy. A formatter result must be one physical line: carriage returns
and line feeds violate the display contract. Use `put_line` for multiline text.

The graphical built-ins use a fixed width of 30 cells. `basic` and `standard`
are ASCII. `unicode` is opt-in because terminal encoding support belongs to the
application environment.

## Terminal behavior

The legacy single-line path uses carriage return and space padding, preserving
its original emitted sequences. A shared multiline display uses ECMA-48 cursor
up/down and erase-line sequences to update rows and repaint structural changes.
`put_line` repaints the full cached frame after the message.

Terminal output is synchronous and flushed after each emitted sequence. One
display is intended for one thread. Separate displays do not coordinate output;
bars and iterable wrappers coordinate only when they share a display or have a
parent-child relationship.

The implementation counts Eiffel characters, not terminal display columns.
Custom formatters that use combining characters, emoji, tabs, or wide glyphs
should account for their terminal's display-width rules themselves.
