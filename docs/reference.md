# API reference

## PB_PROGRESS_BAR

| Feature | Behavior |
| --- | --- |
| `make_with_total (total: INTEGER_64)` | Create a bar with the given total; `-1` denotes an unknown total |
| `make_unknown` | Create a bar with an unknown total; equivalent to `make_with_total (-1)` |
| `advance` | Add one completed unit |
| `advance_by (delta: INTEGER_64)` | Signed update, saturated between zero and the total or INTEGER_64 maximum without overflow |
| `finish` | Finish at the current position and render the final state once |
| `render` | Ask the renderer to show the current state without changing progress |
| `set_renderer (renderer)` | Replace the renderer; configure before first output and before grouping |
| `put_line (text)` | Delegate a message to the renderer |
| `absolute_progress` | Accepted progress, initially zero |
| `has_total` | Whether total is known |
| `total` | Stored total; `-1` denotes an unknown total |
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
it uses `-1` and the bar remains unfinished until `finish` is called explicitly.
The inherited `advance`, `advance_by`, and `finish` features are hidden from
clients; iteration drives progress through `forth`.

## Renderers

`PB_PROGRESS_RENDERER` defines `format_line (bar): STRING_32` and supplies single-line
rendering. `PB_BASIC_PROGRESS_RENDERER` displays `[current/total]` or `[current/?]`.
`PB_UNICODE_PROGRESS_RENDERER` displays a 20-cell bar with eighth-cell resolution
and a whole percentage; unknown totals fall back to `[current/?]`.

The additional built-in renderers are inspired by
[verigak/progress](https://github.com/verigak/progress):

- `PB_CHARGING_PROGRESS_RENDERER` uses solid blocks and a percentage;
- `PB_SQUARES_PROGRESS_RENDERER` uses filled and empty squares;
- `PB_CIRCLES_PROGRESS_RENDERER` uses filled and empty circles;
- `PB_PIXEL_PROGRESS_RENDERER` uses braille pixels and a counter;
- `PB_MOON_SPINNER_RENDERER` uses moon phases for indeterminate work.
- `PB_TIMING_RENDERER` decorates any renderer with elapsed time and ETA.

Create the timing decorator around the desired renderer:

```eiffel
bar.set_renderer (create {PB_TIMING_RENDERER}.make (
    create {PB_UNICODE_PROGRESS_RENDERER}))
```

It displays elapsed time and ETA as `HH:MM:SS`. Unknown totals and bars with
zero progress display `--:--:--` for ETA.

A single-line renderer remembers its last text and completion state. Give each bar
its own instance. It pads shorter output to erase the previous tail and terminates
the final line with a newline. Messages clear and restore the last line. After
completion, that renderer ignores `render` and `put_line`.

The protected `emit (text: READABLE_STRING_GENERAL)` method writes to stdout.
Descendants may override it to redirect or capture output.

## PB_MULTIPLE_PROGRESS_RENDERER

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
