# API reference

## PB_PROGRESS_BAR

| Feature | Behavior |
| --- | --- |
| `make_with_total (total)` | Create a bar with a non-negative total |
| `make_unknown` | Create a bar without a known total |
| `advance` / `advance_by (delta)` | Change progress within its bounds |
| `finish` | Finish and render the current state |
| `render` | Redraw the attached display |
| `put_line (text)` | Print a message above the display |
| `set_formatter (formatter)` | Choose the formatter for this bar |
| `set_description (text)` | Set the text before the progress |
| `set_total (total)` | Set the bar's known total |
| `set_absolute_progress (progress)` | Set progress without rendering |
| `absolute_progress` | Current progress |
| `progress_limit` | Total, or `INTEGER_64.max_value` when unknown |
| `has_total` / `has_finished` | Current lifecycle state |
| `progress_ratio` / `progress_percentage` | Normalized progress for known totals |
| `elapsed_seconds` / `eta_seconds` | Timing measurements |

Known totals finish automatically at the limit. Unknown bars require an
explicit `finish`. Progress updates are saturated at zero and the limit.

## PB_DISPLAY

`PB_DISPLAY` owns terminal output for a fixed ordered set of bars:

```eiffel
local
    display: PB_DISPLAY
do
    create display.make
    display.extend (first)
    display.extend (second)
    first.advance
end
```

Every update redraws all attached rows. `put_line` prints above the rows and
restores them. `emit (text)` is a protected extension point for redirecting or
capturing output. Display calls are synchronous and must be made sequentially.

## PB_FORMATTER

`PB_FORMATTER` formats one bar and contains all presentation settings: width,
fill and empty characters, phases, percentage, remaining work, count, and
elapsed time. Known-total bars use 30 cells by default. Timing is enabled by
default. Use
`set_show_phases_for_known` or `set_show_phases_for_unknown` to select phase
output, and `set_show_timing (False)` to omit timing.
`format (bar): STRING_32` returns one physical line without writing output.

`PB_FORMATTER_PRESETS` provides fresh configured instances such as `squares`,
`unicode`, `moon_spinner`, `counter`, `countdown`, and `stack`. Counter,
countdown, and spinner presets omit timing; `stack` retains the standard timing
setting.

## PB_WRAPPED_BAR

`PB_WRAPPED_BAR [G]` combines an iterable with a progress bar. Finite iterables
use their count; unknown-size iterables require explicit completion.
