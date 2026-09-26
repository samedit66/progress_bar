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
                Result.append_string_general (" / " + bar.progress_limit.out)
            end
        end
end
```

Install it before displaying the bar:

```eiffel
bar.set_renderer (create {PB_FILES_RENDERER})
```

`format_line` returns one physical line without carriage returns or newlines.
Check `has_total` before using `progress_limit` as a displayed total. Use
`has_finished` if final text should differ from active text. Return a fresh string:
the single-line renderer may pad and retain the returned string.

The built-in `PB_STANDARD_PROGRESS_RENDERER` supports configurable width, fill and
empty characters, percentage or counter output, description, elapsed time, and ETA.
Use `PB_SPINNER_PROGRESS_RENDERER` for indeterminate work; its phases and counter
are configurable.

Common standard styles can be selected without configuring characters manually:

```eiffel
bar.set_renderer ({PB_RENDERER_PRESETS}.squares)
```

Preset features create a fresh renderer for every call. A renderer owns output
state and must not be shared between bars.

A renderer owns output state, so create a separate instance for each bar. Set the
renderer before adding the bar to `PB_PROGRESS_GROUP`. The group retains
the original renderer as a formatter and calls it whenever *any* row updates.
Changing a grouped bar's renderer does not merely change its format: it disconnects
that bar from the formatter captured by the group.
