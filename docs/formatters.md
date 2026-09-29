# Formatters

`PB_FORMATTER` converts a bar state into one physical line. It does not write
to the terminal. Configure one formatter and attach it with `set_formatter`:

```eiffel
local
    formatter: PB_FORMATTER
do
    create formatter.make
    formatter.set_width (30)
    formatter.set_fill_character ('=')
    formatter.set_empty_character ('.')
    bar.set_formatter (formatter)
end
```

Known totals use a 30-cell bar by default. Set `set_width` to change its width,
or `set_show_percentage (False)` to
show `count/total`, or `set_show_remaining (True)` to show remaining work.
Set `set_show_phases_for_known (True)` to show one phase character instead of
cells for a known total.

Unknown totals use phase characters by default. Set `set_show_count (True)` to
include the current count. Use `set_show_phases_for_unknown (False)` to hide
the phase character. Timing is enabled by default; use `set_show_timing (False)`
to hide elapsed time. Known-total bars also show ETA when progress is positive.

`PB_FORMATTER_PRESETS` creates independent configured formatters:

```eiffel
bar.set_formatter ({PB_FORMATTER_PRESETS}.squares)
bar.set_formatter ({PB_FORMATTER_PRESETS}.moon_spinner)
bar.set_formatter ({PB_FORMATTER_PRESETS}.counter)
bar.set_formatter ({PB_FORMATTER_PRESETS}.countdown)
bar.set_formatter ({PB_FORMATTER_PRESETS}.stack)
```

The `counter`, `countdown`, and spinner presets omit elapsed timing for compact
output. The `standard` and character presets retain the standard timing; call
`set_show_timing (False)` when a compact character bar is required.

To define another presentation, inherit `PB_FORMATTER` and implement
`format (bar: PB_PROGRESS_BAR): STRING_32`. Return one physical line and leave
terminal output to `PB_DISPLAY`.
