<div align="center">

# progress_bar

[![ISE Eiffel](https://img.shields.io/badge/toolchain-ISE%20Eiffel-17365D)](https://www.eiffel.com/)
[![Gobo Eiffel](https://img.shields.io/badge/toolchain-Gobo%20Eiffel-8B5A2B)](https://www.gobosoft.com/)
[![CI](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/samedit66/progress_bar/actions/workflows/ci.yml)

Terminal progress for Eiffel. Void-safe, ELKS-only, with synchronous output to
standard error and support for EiffelStudio and Gobo.

</div>

## Quick start

This complete class uses [`PB_BAR`](src/bar/pb_bar.e),
[`PB_ITERABLE [G]`](src/iteration/pb_iterable.e), and
[`PB_STEP_BAR`](src/iteration/pb_step_bar.e), with no placeholder routines.
In a checkout of this repository, paste it into
[`examples/quick_start/application.e`](examples/quick_start/application.e), then
run `make gobo` or `make ise` from the repository root with the corresponding
toolchain installed. The included ECF already connects the library.

```eiffel
class APPLICATION

create

    make

feature {NONE} -- Initialization

    make
            -- Run complete examples of the public API.
        local
            bar: PB_BAR
            formatters: PB_FORMATTERS
            items: ARRAYED_LIST [STRING]
            progress: PB_ITERABLE [STRING]
            files, parts: PB_STEP_BAR
            processed_parts: INTEGER
        do
            -- 1. Manual progress: start displays zero; forth adds one and finishes at 10.
            -- Default formatter: ASCII progress bar, percentage, and completed/total count.
            create bar.make_with_total (10)
            from
                bar.start
            until
                bar.is_finished
            loop
                bar.forth
            end

            -- 2. Unknown total: updates animate a spinner; finish closes it explicitly.
            -- Default formatter: ASCII spinner and completed count.
            create bar.make_unknown
            bar.start
            bar.forth_by (4)
            bar.pulse
            bar.finish

            -- 3. Absolute progress: early finish preserves the actual value, 40/100.
            -- Optional custom formatting adds a label.
            create formatters
            create bar.make_with_total (100)
            bar.set_line_formatter (formatters.standard ("Stopped early", "items", ""))
            bar.set_progress (40)
            bar.finish

            -- 4. Existing items: across updates progress after each loop body.
            create items.make (3)
            items.extend ("parse")
            items.extend ("analyze")
            items.extend ("emit")
            create progress.make_over (items)
            progress.set_line_formatter (formatters.standard ("Pipeline", "stages", "done"))
            across
                progress
            as
                item
            loop
                progress.put_line ("Processed " + item)
            end

            -- 5. Numbered steps: share a display for nested loops.
            -- Each inner traversal gets a fresh row, removed when it finishes.
            create files.make_with_total (3)
            files.set_line_formatter (formatters.standard ("Files", "files", "done"))
            create parts.make_with_total (2)
            parts.set_display (files.display)
            parts.set_line_formatter (formatters.standard ("  Parts", "parts", "done"))
            across
                files
            as
                file_number
            loop
                across
                    parts
                as
                    part_number
                loop
                    processed_parts := processed_parts + 1
                    parts.put_line ("File " + file_number.out + ", part " + part_number.out)
                end
            end
            files.put_line ("Processed " + processed_parts.out + " parts")
        end

end
```

Step numbers (`file_number` and `part_number`) are `INTEGER`, starting at 1. Each traversal gets its own row.
By default, the first active row keeps its final text; rows started while others
are active disappear when finished. Use `keep_final_line` to retain them.
These small examples finish immediately; real work belongs before each manual
`forth` or inside the `across` body.

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
