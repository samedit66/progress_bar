# Reference

## `PB_BAR`

Creation procedures:

- `make (total)` creates known progress with the ASCII `basic` formatter;
- `make_unknown` creates unknown progress with the same agent's spinner mode;
- `make_in (display, total)` creates known progress in an existing display;
- `make_unknown_in (display)` creates unknown progress in an existing display;
- `make_child (parent, total)` creates known progress nested below an active parent.

`set_formatter (formatter)` replaces the agent for the next refresh without
printing, changing progress, or changing `revision`. Creation does not print,
except that a non-empty child starts its lazy parent to establish display order.
Formatter-only constructor variants have been removed.

`position: INTEGER_64` starts at zero and returns the last accepted absolute value.
Known totals must be non-negative. A zero total creates an already finished,
silent bar with no registered display row and no formatter callbacks.

`update (value)` sets the absolute position, clamped to zero and, for known progress,
to its total. `advance (delta)` applies a signed increment through the same update
path. Clamping happens before addition can overflow. Unknown progress saturates at
`INTEGER_64.max_value` without automatically completing. Accepted updates mark the
bar started and advance `revision`, even when the value is unchanged.

Reaching or exceeding a known total completes the bar automatically. The completing
update invokes the formatter once with `is_final = True`, without an intermediate
non-final snapshot. `pulse` advances only `revision`; it requires an unknown total
while active. After completion every command is a no-op, including `pulse`,
`put_line`, configuration, and repeated `finish`. Queries remain usable.

`finish` stops the bar at its actual value. Both forced and automatic completion
finish all open descendants, deepest first, without changing their progress values
or revisions. Each receives its final formatter callback and retention policy.
Unrelated bars sharing the display remain open. No bar can resume after completion;
creating a child of a finished parent violates the creation precondition.

`display` identifies the coordinating `PB_DISPLAY`. A child shares its parent's
display and has a stable position after the parent and its existing descendants.
A non-empty child starts a lazy parent once; an empty child remains silent and does
not start the parent. Child updates do not advance the parent.
`has_open_children` includes every unfinished descendant.

`keeps_final_line` is true by default. `keep_final_line` and `discard_final_line`
configure the policy before the first update or pulse; finished bars ignore them.
A kept child row remains in order until the display becomes idle; a discarded row
is removed on completion.

The formatter is invoked for every accepted update, pulse, and first finish.
Only terminal output is deduplicated for identical non-final text. Output is
synchronous, written to standard error, and flushed.

`put_line (message)` on an active bar writes above the managed display block and
restores cached rows without changing progress or invoking formatters. After bar
completion it does nothing; use `display.put_line` for messages independent of a
bar's lifetime. Empty, Unicode, and multiline messages are supported. Output and
formatter failures propagate and may leave partial output or partially completed
subtrees; commands do not promise atomic completion across I/O failures.

## `PB_DISPLAY`

`make` creates an idle terminal display. Passing it to constructors ending in
`_in` coordinates unrelated bars and iterable cursors in one ordered terminal
block. `PB_BAR.make_child` derives the display from its parent, so callers do
not pass both values.

`put_line (message)` writes regardless of bar lifetime, including when idle.
Active bars and iterable wrappers delegate their `put_line` calls to it. A display performs synchronous writes to standard error and is a
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

`make (source)` retains an `ITERABLE [G]` with a private display.
`make_in (display, source)` uses an existing display. `set_formatter` configures
the agent for future cursors. `new_cursor` creates a fresh source cursor and bar,
with a display line only when the known total is nonzero.

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
to the wrapper do not change that cursor. The same copying rule applies to the
formatter. Empty finite traversals are silent and invoke no formatter; unknown
empty traversals still finish explicitly once their cursor reports exhaustion.

## `PB_RANGE`

`PB_RANGE` is a `PB_ITERABLE [INTEGER]` backed by an `INTEGER_INTERVAL`.
Creation procedures are `make_from_to (from, to)` and
`make_from_to_in (from, to, display)`. Use inherited `set_formatter` for custom
formatting of future cursors.

Both bounds are inclusive. Equal bounds produce one item. When `from > to`, the
range is empty and its fresh cursor is already finished without output.
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
