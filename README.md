<div align="center">

# progress_bar

[![ISE Eiffel](https://img.shields.io/badge/toolchain-ISE%20Eiffel-17365D)](https://www.eiffel.com/)
[![Gobo Eiffel](https://img.shields.io/badge/toolchain-Gobo%20Eiffel-8B5A2B)](https://www.gobosoft.com/)
[![CI](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml)

Terminal progress for Eiffel. Void-safe, ELKS-only, with synchronous output to
standard error and support for EiffelStudio and Gobo.

</div>

## Quick start

Use `PB_BAR` to report completed work with manual progress updates:

```eiffel
local
    bar: PB_BAR
do
    create bar.make_with_total (10)
    from bar.start until bar.is_finished loop
        do_work
        bar.forth
    end
end
```

Replace `do_work` with your operation. Reaching the total finishes the bar.

Use `PB_ITERABLE [G]`, inspired by Python's [tqdm](https://github.com/tqdm/tqdm),
to wrap an existing iterable:

```eiffel
local
    bar: PB_ITERABLE [STRING]
    items: ARRAY [STRING]
do
    items := << "this", "and that", "and also that" >>
    create bar.make_over (items)

    across bar as item loop
        do_work (item) -- `item` is a string from `items`.
    end
end
```

Use `PB_STEP_BAR` to iterate over numbered steps with automatic progress updates:

```eiffel
local
    bar: PB_STEP_BAR
do
    create bar.make_with_total (100)

    across bar as step loop
        do_work (step) -- `step` is an integer from 1 to 100.
    end
end
```

To show several progress bars at once, share a `PB_DISPLAY` between them:

```eiffel
local
    outer_bar: PB_STEP_BAR
    inner_bar: PB_STEP_BAR
do
    create outer_bar.make_with_total (100)

    across outer_bar as outer_step loop
        create inner_bar.make_with_total (20)
        inner_bar.set_display (outer_bar.display) -- Share the outer bar's display.

        across inner_bar as inner_step loop
            -- ...
        end
    end
end
```

## Public API at a glance

| Type | Features |
| --- | --- |
| `PB_BAR` | `make_with_total`, `make_unknown`; `start`, `forth`, `forth_by`, `set_progress`, `pulse`, `finish`; `progress`, `has_total`, `total`, `is_started`, `is_finished`, `keeps_final_line` |
| `PB_ITERABLE [G]` | `make_over`, `new_cursor` (used by `across`) |
| `PB_STEP_BAR` | `make_with_total`; inherits iterable behavior for `INTEGER` steps |
| All three | `display`, `set_display`, `set_line_formatter`, `keep_final_line`, `discard_final_line`, `put_line` |

Formatter agents receive an immutable `PB_PROGRESS` snapshot; `PB_FORMATTERS`
provides built-in agents through class features such as
`{PB_FORMATTERS}.basic_formatter`. No factory object is needed. Inherit
`PB_FORMATTERS` for short calls such as `basic_formatter`; the
[quick-start application](examples/quick_start/application.e) demonstrates this.
See [formatter usage and migration](docs/formatters.md) for the breaking rename
from `basic`, `standard`, and the other old factory names.

## Installation and documentation

Add the repository to your application and reference `progress_bar.ecf`:

```xml
<library name="progress_bar" location="vendor/progress_bar/progress_bar.ecf" readonly="true"/>
```

- [Tutorial](docs/tutorial.md): setup, manual updates, traversal, and sharing displays.
- [API reference](docs/reference.md): contracts, lifecycle, rendering, and limitations.
- [Formatters](docs/formatters.md): agents using [`PB_PROGRESS`](src/progress/pb_progress.e) and [`PB_FORMATTERS`](src/formatter/pb_formatters.e).
- [Quick-start application](examples/quick_start/application.e): complete executable examples.
- [Display](src/internal/pb_display.e), [row handle](src/internal/pb_display_line.e), [renderer](src/internal/pb_terminal_renderer.e), and [iteration cursor](src/iteration/pb_iteration_cursor.e): implementation details.

## Development

CI uses Gobo 26.06 and EiffelStudio 25.12 on Linux, macOS, and Windows.
`make test` runs both test suites; `make check` runs both analyzers;
`make format` formats Eiffel sources. `make gobo` or `make ise` runs the example.
`make test-ise-finalized` tests the finalized EiffelStudio build with assertions retained.
