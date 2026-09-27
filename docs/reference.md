# API reference

## PB_PROGRESS_BAR

| Feature | Behavior |
| --- | --- |
| `make_with_total (total: INTEGER_64)` | Create a bar with the given non-negative total |
| `make_unknown` | Create a bar without a known total |
| `advance` | Add one completed unit |
| `advance_by (delta: INTEGER_64)` | Signed update, saturated between zero and `progress_limit` without overflow |
| `finish` | Finish at the current position and render the final state once |
| `render` | Ask the renderer to show the current state without changing progress |
| `set_renderer (renderer)` | Replace the renderer; configure before first output and before grouping |
| `put_line (text)` | Delegate a message to the renderer |
| `absolute_progress` | Accepted progress, initially zero |
| `has_total` | Whether `progress_limit` is a known total |
| `progress_limit` | Maximum possible progress; `{INTEGER_64}.max_value` for unknown work |
| `progress_ratio` | Known progress normalized to `0.0 .. 1.0` |
| `progress_percentage` | Known progress as an integer percentage from `0` to `100` |
| `description` | Text displayed before the progress bar |
| `set_description (text)` | Set the text displayed before the progress bar |
| `elapsed_seconds` | Whole seconds elapsed since bar creation |
| `has_eta` / `eta_seconds` | Whether an ETA is available and its estimated value |
| `has_finished` | Whether finish has occurred |
| `renderer` | Current renderer |

Reaching a known total finishes automatically with one final render. Unknown work
never finishes automatically, even at INTEGER_64 maximum. Explicit finish preserves
actual progress. Subsequent `advance`, `advance_by`, and `finish` calls do nothing.
A zero total starts unfinished and completes on the first update or explicit finish.

## PB_WRAPPED_BAR

`PB_WRAPPED_BAR [G]` combines `ITERABLE [G]`, `ITERATION_CURSOR [G]`, and
`PB_PROGRESS_BAR`. Create it with `wrap (iterable)`. It advances the progress bar
as the cursor moves through the iterable:

```eiffel
local
    bar: PB_WRAPPED_BAR [STRING]
do
    create bar.wrap (<< "first", "second", "third" >>)
    across bar as item loop
        do_work (item)
    end
end
```

For a finite iterable, `wrap` uses its count as the total. For other iterables,
it uses an unknown progress limit and the bar remains unfinished until `finish`
is called explicitly.
The inherited `advance`, `advance_by`, and `finish` features are hidden from
clients; iteration drives progress through `forth`.

## Renderers

`PB_PROGRESS_RENDERER` defines `format_line (bar): STRING_32` and supplies single-line
rendering. `PB_STANDARD_PROGRESS_RENDERER` is the configurable renderer used by
default. It supports description, fill and empty characters, width, percentage or
counter output, elapsed time, and ETA.

For unknown work, use `PB_SPINNER_PROGRESS_RENDERER`. It displays a configurable
phase next to the description. The current counter and elapsed time are optional;
ETA is not displayed because it is unavailable for unknown work. This follows the
common separation between bars and spinners used by
[verigak/progress](https://github.com/verigak/progress).

The standard renderer can be configured directly:

```eiffel
create renderer.make
renderer.set_fill_character ('=')
renderer.set_empty_character ('.')
renderer.set_width (30)
bar.set_renderer (renderer)
```

Common styles are available as fresh renderer instances through
`PB_RENDERER_PRESETS`:

```eiffel
bar.set_renderer ({PB_RENDERER_PRESETS}.squares)
bar.set_renderer ({PB_RENDERER_PRESETS}.circles)
bar.set_renderer ({PB_RENDERER_PRESETS}.pixels)
bar.set_renderer ({PB_RENDERER_PRESETS}.unicode)
```

Spinner presets are available as fresh instances:

```eiffel
bar.set_renderer ({PB_RENDERER_PRESETS}.spinner)       -- ASCII: -\|/
bar.set_renderer ({PB_RENDERER_PRESETS}.pie_spinner)  -- ◷◶◵◴
bar.set_renderer ({PB_RENDERER_PRESETS}.moon_spinner)  -- ◑◒◐◓
bar.set_renderer ({PB_RENDERER_PRESETS}.line_spinner)  -- ⎺⎻⎼⎽⎼⎻
bar.set_renderer ({PB_RENDERER_PRESETS}.pixel_spinner) -- Braille phases
```

`PB_SPINNER_PROGRESS_RENDERER.make` uses the `moon_spinner` phases by default.
Its default output is compact, for example `Loading ◑`. Use
`set_show_count (True)` and `set_show_elapsed (True)` to include the current
count and elapsed time when needed. Each preset call creates a new renderer.

Compact value presets are also available:

```eiffel
bar.set_renderer ({PB_RENDERER_PRESETS}.counter)   -- Processing 42
bar.set_renderer ({PB_RENDERER_PRESETS}.countdown)  -- Processing 8 left
bar.set_renderer ({PB_RENDERER_PRESETS}.stack)      -- Processing ▃
```

`counter` shows the current count, `countdown` shows remaining known work, and
`stack` shows the progress ratio as one of the stack phases `▁▂▃▄▅▆▇█`.
Unknown progress is rendered as `? left` by `countdown` and as the normal
unknown-total form by `stack`.

Each preset call creates a new renderer. Do not share one renderer between bars.

It displays elapsed time and ETA as `HH:MM:SS`. Unknown totals and bars with
zero progress display `--:--:--` for ETA.

A single-line renderer remembers its last text and completion state. Give each bar
its own instance. It pads shorter output to erase the previous tail and terminates
the final line with a newline. Messages clear and restore the last line. After
completion, that renderer ignores `render` and `put_line`.

The protected `emit (text: READABLE_STRING_GENERAL)` method writes to stdout.
Descendants may override it to redirect or capture output.

## PB_PROGRESS_GROUP

`make (bars: ITERABLE [PB_PROGRESS_BAR])` requires a nonempty iterable. Supply
**distinct bars before their first display**, with their desired renderers already
installed. Construction preserves those renderers for formatting and replaces the
bar renderers with the group. No output occurs during construction.

Updates format and redraw every row in the original order. Finishing one bar does
not finish others. All final rows stay in the group. `put_line` erases the group,
prints a message, and redraws it, including when called after all bars finish.
Grouping uses only the original renderers' `format_line`; their custom `render`
implementations are not invoked. Do not regroup bars or replace their renderers
while the group is in use. The group has no add/remove or release operation.

## Limits

Calls must be sequential and made by one thread. Grouped output requires terminal
cursor movement and erase-line support. Lines must fit the terminal width and the
whole group must fit its height. Character counts do not measure the terminal
width of wide glyphs, combining characters, tabs, or escape sequences.

All output is synchronous, with no refresh timer, throttling, terminal detection,
or automatic flushing. Formatters are called for every render, including all rows
on each group update and on group messages. Avoid side effects in `format_line`:
it receives the live bar, and a render need not mean that this bar advanced.

Exceptions propagate. Updates and output are not transactional: notably, `finish`
sets `has_finished` before rendering, so a failing final render leaves the bar
finished. There is no automatic cleanup on exceptions or early loop exit. Use the
provided message operation instead of interleaving unrelated terminal output while
a group remains in use.
