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

Known totals use a cell bar by default. Set `set_show_percentage (False)` to
show `count/total`, or `set_show_remaining (True)` to show remaining work.
Set `set_show_phases (True)` to show one phase character instead of cells.

Unknown totals use phase characters by default. Set `set_show_count (True)` to
include the current count. `set_show_elapsed (True)` appends elapsed time;
known-total bars also show ETA when progress is positive.

`PB_FORMATTER_PRESETS` creates independent configured formatters:

```eiffel
bar.set_formatter ({PB_FORMATTER_PRESETS}.squares)
bar.set_formatter ({PB_FORMATTER_PRESETS}.moon_spinner)
bar.set_formatter ({PB_FORMATTER_PRESETS}.counter)
bar.set_formatter ({PB_FORMATTER_PRESETS}.countdown)
bar.set_formatter ({PB_FORMATTER_PRESETS}.stack)
```

To define another presentation, inherit `PB_FORMATTER` and implement
`format (bar: PB_PROGRESS_BAR): STRING_32`. Return one physical line and leave
terminal output to `PB_DISPLAY`.
