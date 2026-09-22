# Custom formatting

Inherit `PB_PROGRESS_RENDERER` and implement the `format_line` feature:

```eiffel
class PB_FILES_RENDERER
inherit
    PB_PROGRESS_RENDERER
feature
    format_line (bar: PB_PROGRESS_BAR): STRING_32
        do
            Result := "Files: " + bar.absolute_progress.out
            if bar.has_total then
                Result.append_string_general (" / " + bar.total.out)
            end
        end
end
```

Install it before displaying the bar:

```eiffel
bar.set_renderer (create {PB_FILES_RENDERER})
```

`format_line` returns one physical line without carriage returns or newlines.
Check `has_total` before using `total` in a known/unknown display. Use
`has_finished` if final text should differ from active text. Return a fresh string:
the single-line renderer may pad and retain the returned string.

The built-in renderers are inspired by the styles in
[verigak/progress](https://github.com/verigak/progress):

| Renderer | Style |
| --- | --- |
| `PB_BASIC_PROGRESS_RENDERER` | ASCII counter, `[current/total]` or `[current/?]` |
| `PB_UNICODE_PROGRESS_RENDERER` | Partial-block Unicode bar and percentage |
| `PB_CHARGING_PROGRESS_RENDERER` | Solid blocks and percentage |
| `PB_SQUARES_PROGRESS_RENDERER` | Filled/empty squares and percentage |
| `PB_CIRCLES_PROGRESS_RENDERER` | Filled/empty circles and percentage |
| `PB_PIXEL_PROGRESS_RENDERER` | Braille-pixel bar and counter |
| `PB_MOON_SPINNER_RENDERER` | Moon-phase spinner driven by progress updates |

The block renderers show a filled bar for a known total and fall back to a
counter for an unknown total. The moon spinner is intended for indeterminate
work and advances its phase as `absolute_progress` changes.

A renderer owns output state, so create a separate instance for each bar. Set the
renderer before adding the bar to `PB_MULTIPLE_PROGRESS_RENDERER`. The group retains
the original renderer as a formatter and calls it whenever *any* row updates.
Changing a grouped bar's renderer does not merely change its format: it disconnects
that bar from the formatter captured by the group.
