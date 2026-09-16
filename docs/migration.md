# API migration

The manual and automatic interfaces are separate. This is a source-breaking API
revision; old names are removed rather than retained as parallel alternatives.

| Previous API | Current API |
| --- | --- |
| `PB_BAR.make (total)` | `PB_BAR.make_with_total (total)` |
| `bar.update (value)` | `bar.set_progress (value)` |
| `bar.advance (1)` | `bar.forth` |
| `bar.advance (delta)` | `bar.forth_by (delta)` |
| `bar.position` | `bar.progress` |
| `set_formatter (agent)` | `set_line_formatter (agent)` |
| `PB_ITERABLE.make (source)` | `PB_ITERABLE.make_over (source)` |
| `make_in (display, ...)`, `make_unknown_in (display)` | Ordinary constructor, then `set_display (display)` |
| `PB_RANGE.make_from_to (1, total)` | `PB_STEP_BAR.make_with_total (total)` |
| Other `PB_RANGE` bounds | `PB_ITERABLE [INTEGER].make_over` with an `INTEGER_INTERVAL` |

`PB_BAR` is not generic or iterable. `PB_STEP_BAR` inherits `PB_ITERABLE [INTEGER]`,
not `PB_BAR`. Existing formatter agents and `PB_PROGRESS.position` are unchanged.

## Displays and lifecycle

Use `second.set_display (first.display)` to share output without explicitly creating
`PB_DISPLAY`. Ordinary construction no longer registers a pending row. `start`
shows initial progress; updates can still start lazily. Repeated `start` is harmless.
Move display configuration before start. Existing cursors retain their display when
an iterable's configuration changes.

The default final-line policy is now automatic: keep the first active row, discard
rows started while another is open. To preserve all results as before, call
`keep_final_line` on each bar before start, or on the iterable before its traversals.

The advanced manual `make_child` constructor retains its parent-ownership behavior,
including starting a lazy parent and registering pending children. Its final row
now disappears by default. A child cannot change its display.

Known-total completion, signed clamping, unknown `pulse`, explicit early `finish`,
and formatter exception propagation remain supported. `finish` preserves actual
progress. Use manual progress for cancellation/exception cleanup; automatic cursors
only guarantee closure upon exhaustion.

See the [tutorial](tutorial.md) and [reference](reference.md) for complete examples
and contracts. The [original sketch](api-sketch.md) is preserved as design history.
