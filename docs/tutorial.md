# Tutorial

## Known work

```eiffel
local
    bar: PB_PROGRESS_BAR
do
    create bar.make_with_total (10)
    bar.render -- Optional initial display.
    from until bar.has_finished loop
        do_work
        bar.advance
    end
end
```

Advance only after completing work. Use `advance_by (count)` for a batch. Reaching
or exceeding the total finishes the bar. A zero-total bar starts unfinished and
finishes on its first update or an explicit call to `finish`.

## Unknown work

```eiffel
create bar.make_unknown
from until source_exhausted loop
    do_work
    bar.advance
end
bar.finish
```

Unknown progress displays a counter and must be finished explicitly. To let the
library advance the bar while an iterable is traversed, use `PB_WRAPPED_BAR [G]`:

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

For a finite iterable, the wrapper uses its count as the total. Otherwise, it
uses the unknown-total form and requires an explicit `finish` after traversal.

## Grouped work

Create all bars, install any custom renderers, and create a
`PB_MULTIPLE_PROGRESS_RENDERER` over them before any output. Update the bars in
any order; all rows stay visible and completion is independent. Use `put_line`
on a grouped bar to print messages above the block.

The [quick-start application](../examples/quick_start/application.e) contains
an iterable-backed bar and a progress message. Run it with `just run`.
