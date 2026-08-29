# Reference

## `PB_BAR`

Creation procedures:

- `make (total)` creates known progress with the ASCII `basic` formatter;
- `make_with_formatter (total, formatter)` creates known formatted progress;
- `make_unknown` creates unknown progress with the default formatter;
- `make_unknown_with_formatter (formatter)` creates unknown formatted
  progress.

Known totals and positions must be non-negative. `update (position)` replaces
the absolute position, marks the bar started, advances `revision`, and invokes
the formatter. A known position may exceed its total; percentage and fraction
remain capped at complete.

`pulse` is valid only for unknown progress. It advances `revision` without
changing `position`, allowing a spinner or another revision-based formatter to
change frame.

`finish` invokes the formatter with `is_final = True`, clears any remainder of
the previous terminal line, and writes a newline. Repeated calls do nothing.

The formatter is invoked for every accepted update, pulse, and first finish.
Only terminal output is deduplicated when two non-final calls return identical
text. Output is written synchronously to standard error and flushed.

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
`ITERABLE [G]`. `new_cursor` creates a fresh source cursor and progress bar.

If the source dynamically conforms to `FINITE [G]`, its current `count` becomes
the cursor's known total. Otherwise the cursor uses unknown mode. The wrapper
does not require every iterable to pretend it has a count.

The cursor delegates `item` and `after` directly. Its `forth` first advances
the source cursor, then reports one completed item, and finishes when the source
cursor reaches `after`. Consequently the bar represents completed loop bodies.

## `PB_RANGE`

`PB_RANGE` is a `PB_ITERABLE [INTEGER]` backed by an `INTEGER_INTERVAL`.
Creation procedures are:

- `make_from_to (from, to)` for the default formatter;
- `make_from_to_with_formatter (from, to, formatter)` for a supplied formatter
  callback.

Both bounds are inclusive. Equal bounds produce one item. When `from > to`, the
range is empty and its fresh cursor renders and finishes known `0 / 0` progress.
Every traversal otherwise has the same independent-bar and completed-loop-body
semantics as `PB_ITERABLE [G]`.

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
failure policy.

The graphical built-ins use a fixed width of 30 cells. `basic` and `standard`
are ASCII. `unicode` is opt-in because terminal encoding support belongs to the
application environment.

## Terminal behavior

Rendering uses carriage return to replace the current line. When a new line is
shorter, the renderer overwrites the remaining cells with spaces and returns
the cursor to the end of the new line. `finish` performs the same cleanup before
writing a newline.

The implementation counts Eiffel characters, not terminal display columns.
Custom formatters that use combining characters, emoji, tabs, or wide glyphs
should account for their terminal's display-width rules themselves.
