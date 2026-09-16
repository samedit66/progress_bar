# API reference

## `PB_BAR`

[Class source](../src/bar/pb_bar.e). One manually controlled operation, without a
generic parameter or collection interface. It does not inherit `ITERABLE` or `LINEAR`.

### Creation and configuration

- `make_with_total (total: INTEGER_64)` requires a nonnegative total.
- `make_unknown` creates progress without a total.
- `display: PB_DISPLAY` returns the existing display without allocation or output.
- `set_display (display)` selects a shared display before the bar starts. It rejects
  finished nonempty bars and explicit children. Zero-total bars remain configurable
  for display sharing, but never register a row.
- `set_line_formatter (formatter)` changes the next refresh's formatter without
  rendering or changing the progress/revision. Finished bars ignore this command.
- `keep_final_line` and `discard_final_line` override automatic retention before
  the bar starts. Finished bars ignore both commands.

Ordinary constructors create a private display but no registered row and no output.
The advanced `make_child` constructor has different ownership semantics below.

### Progress and lifecycle

| Feature | Contract |
| --- | --- |
| `start` | Render initial progress once; repeated calls never reset or reopen the bar |
| `forth` | Add one completed unit, starting lazily if necessary |
| `forth_by (delta: INTEGER_64)` | Signed relative update with overflow-safe clamping |
| `set_progress (value: INTEGER_64)` | Absolute update, clamped to zero and the known total |
| `finish` | Close at actual progress, without adding work or claiming completion |
| `pulse` | Refresh unknown progress without adding work; requires unknown total while active |
| `progress: INTEGER_64` | Last accepted absolute value, initially zero |
| `has_total`, `total: INTEGER_64` | `total` requires `has_total` |
| `is_started` | An initial render, update, or pulse has been accepted |
| `is_finished` | Operation has irreversibly terminated |
| `revision: INTEGER_64` | Number of accepted progress updates, including initial start and pulses |

Known progress automatically finishes at its total. The completing update formats
one final snapshot, without an intermediate non-final snapshot. Unknown progress
saturates at `INTEGER_64.max_value` but does not automatically finish.

A zero total creates an already finished, silent bar; no row or formatter call is
needed. `finish` before `start` on a nonempty bar renders a final snapshot at zero,
without an initial frame or incrementing revision. In that case `is_started` remains
false, but the finished bar still cannot move to another display.

Finished bars ignore progress commands, `start`, formatting/retention changes, and
`put_line`. `set_display` is a setup operation with the preconditions above.
Repeated `finish` is harmless. There is no reset, `item`, or `after` on a manual bar.

### Explicit manual children

`make_child (parent, total)` retains the existing opt-in ownership behavior:

- parent must be unfinished;
- a nonempty child starts a lazy parent and immediately registers a pending row
  below the parent's descendants, even before the child's own first update;
- an empty child is silent and does not start the parent;
- children use their parent's display and cannot replace it;
- child final rows are discarded by default, unless explicitly retained;
- finishing a parent closes its open descendants, deepest first, at their actual
  values; independent bars on the same display stay open;
- `is_child` reports explicit ownership and `has_open_children` reports unfinished
  descendants, including registered pending children;
- child updates do not automatically advance the parent.

Use ordinary constructors and `set_display` for coordinated output without this
ownership relationship. Automatic iterable traversals do not infer parent ownership.

## `PB_ITERABLE [G]`

[Class source](../src/iteration/pb_iterable.e). Inherits `ITERABLE [G]`.

`make_over (source: ITERABLE [G])` retains the caller-owned source and creates one
private display for future traversals. Construction is silent. `new_cursor` returns
a fresh `ITERATION_CURSOR [G]` and starts its private bar; `across` needs no setup call.
The wrapper exposes no manual lifecycle or progress commands.

Each cursor copies the current display reference, formatter agent, and retention
configuration. Changing `set_display`, `set_line_formatter`, `keep_final_line`, or
`discard_final_line` affects only future cursors. `has_line_policy` indicates whether
retention was explicitly chosen; `keeps_final_line` describes that explicit choice.
Without an explicit choice, retention is determined when the cursor starts.

The total is `FINITE [G].count` when the source conforms, otherwise unknown.
No counting pass is performed. Size changes during traversal are unsupported.
The source itself must support the requested repeat or concurrent traversals.

The [cursor](../src/iteration/pb_iteration_cursor.e) delegates `item` and `after`.
Its `forth` advances the source, reports one completed body, and closes at source
exhaustion. Queries do not update progress. Empty finite sources produce no output;
unknown empty sources start and then explicitly finish at zero.

Every traversal has independent state. Exceptions propagate. An exception or early
loop exit does not automatically close its row: use a manual bar when explicit
cleanup or cancellation is needed. Do not rely on garbage collection for output.

`put_line` writes through the wrapper's current display, independent of traversal
lifetime. If you change the wrapper's display while old cursors are active, messages
sent through the wrapper use the new display too.

## `PB_STEP_BAR`

[Class source](../src/iteration/pb_step_bar.e). Specializes `PB_ITERABLE [INTEGER]`.

`make_with_total (total: INTEGER)` requires `total >= 0`. Each traversal yields
`1 .. total`; its internal completed-work counter starts at zero. A zero total is
silent. Storage is constant-size, using an `INTEGER_INTERVAL`, not an item list.
All iterable configuration is inherited. Unknown manual work belongs to `PB_BAR`.
For arbitrary integer bounds, pass an `INTEGER_INTERVAL` to `PB_ITERABLE.make_over`.

## Rendering and `PB_DISPLAY`

[Display source](../src/internal/pb_display.e),
[row handle](../src/internal/pb_display_line.e),
[terminal renderer](../src/internal/pb_terminal_renderer.e).

The display owns the ordered terminal block; each bar retains a stable row handle.
Ordinary bars register on first rendering. Unstarted ordinary bars do not keep the
display busy. Explicit children are the pending-row exception described above.

A private display is the default. To coordinate output, call
`second.set_display (first.display)` before starting. Separate display instances do
not coordinate even if they write to the same terminal. Explicit display creation
is available but not required for the common case.

### Row retention

Without an override, a bar starting on an idle display keeps its final row. A bar
starting while another row is open discards its final row. This rule is based on
active rows, not syntactic nesting; use `keep_final_line` for overlapping independent
operations whose results should both remain visible.

The choice is fixed at the first render, so later closure of other rows cannot
change it. Explicit children discard by default. Retained completed rows remain
in their ordered positions while other rows are active. When the display becomes
idle, retained text is committed with a final newline and the registry is cleared.
Discarded rows are removed from the registry immediately, avoiding accumulation
across repeated inner loops. A discarded final frame is formatted but cleared;
there is no artificial delay to make its final percentage visible.

### Refresh and messages

Every accepted progress update synchronously invokes the bar's formatter. The
display updates the affected row using cached neighboring text. Addition/removal
of rows repaints the managed block. Identical non-final text skips the terminal
write but does not skip formatter invocation. Repeated `start`/`finish` and commands
on finished bars do not produce refreshes.

`put_line (message)` clears the block, writes the message, and restores cached rows,
without advancing progress or calling formatters. `PB_DISPLAY.put_line` works even
when no bar is active; manual bars stop forwarding messages after completion.

Output goes to standard error and is flushed synchronously. Multiline rendering
requires ECMA-48 cursor movement and erase-line support. One display is intended
for one thread; there is no timer, background worker, or automatic terminal detection.
Text widths use Eiffel character counts, not terminal display columns. Wide glyphs,
combining characters, tabs, and line wrapping need application-level care.

Formatter and output failures propagate. State updates, row registration, subtree
completion, and terminal writes are not transactional; failures may leave partially
completed work or output. No automatic retry or exception-swallowing is added.

## Formatter types

[`PB_PROGRESS`](../src/progress/pb_progress.e) remains an immutable snapshot with
`position`, `revision`, `has_total`, guarded `total`, `fraction`, `percentage`,
`is_complete`, and `is_final`. Snapshot `position` corresponds to `PB_BAR.progress`.
For known zero totals, the fraction is 1 and percentage is 100.

[`PB_FORMATTERS`](../src/formatter/pb_formatters.e) supplies agents with this type:

```eiffel
FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
```

A formatter returns one physical line without carriage returns or newlines. The
renderer copies it, so the formatter may reuse its buffer after returning.
Built-ins are `basic`, `standard (label, unit, post_label)`, `unicode`, `compact`,
`counter`, and `minimal`. See [custom formatters](formatters.md).
