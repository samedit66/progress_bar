# progress_bar

Terminal progress for Eiffel. Void-safe, ELKS-only, with synchronous output to
standard error and support for EiffelStudio and Gobo.

## Quick start

Automatic numbered steps with [`PB_STEP_BAR`](src/iteration/pb_step_bar.e):

```eiffel
create steps.make_with_total (100)
across steps as step loop
    do_work (step) -- INTEGER, from 1 through 100.
end
```

An existing source with [`PB_ITERABLE [G]`](src/iteration/pb_iterable.e):

```eiffel
create progress.make_over (items)
across progress as item loop
    process (item)
end
```

Manual progress with [`PB_BAR`](src/bar/pb_bar.e):

```eiffel
create bar.make_with_total (100)
from bar.start until bar.is_finished loop
    do_work
    bar.forth
end
```

Use `make_unknown` and an explicit `finish` when the total is unknown.
`forth_by (delta)` and `set_progress (value)` support relative and absolute updates.

## Nested loops

Share the outer display; no explicit display construction is needed:

```eiffel
create files.make_with_total (3)
create parts.make_with_total (10)
parts.set_display (files.display)

across files as file_number loop
    across parts as part_number loop
        process_part (file_number, part_number)
    end
end
```

Each traversal gets its own row. By default, the first active row keeps its final
text; rows started while others are active disappear when finished.

## Installation and documentation

Add the repository to your application and reference `progress_bar.ecf`:

```xml
<library name="progress_bar" location="vendor/progress_bar/progress_bar.ecf" readonly="true"/>
```

- [Tutorial](docs/tutorial.md): setup, manual updates, traversal, and sharing displays.
- [API reference](docs/reference.md): contracts, lifecycle, rendering, and limitations.
- [Formatters](docs/formatters.md): agents using [`PB_PROGRESS`](src/progress/pb_progress.e) and [`PB_FORMATTERS`](src/formatter/pb_formatters.e).
- [Migration](docs/migration.md): changes from the previous API.
- [Quick-start application](examples/quick_start/application.e): complete executable examples.
- [Display](src/internal/pb_display.e), [row handle](src/internal/pb_display_line.e), [renderer](src/internal/pb_terminal_renderer.e), and [iteration cursor](src/iteration/pb_iteration_cursor.e): implementation details.

## Development

CI uses Gobo 26.06 and EiffelStudio 25.12 on Linux, macOS, and Windows.
`make test` runs both test suites; `make check` runs both analyzers;
`make format` formats Eiffel sources. `make gobo` or `make ise` runs the example.
