# Custom formatters

A formatter is an Eiffel function agent from one immutable `PB_PROGRESS`
snapshot to display text:

```eiffel
FUNCTION [
    TUPLE [progress: PB_PROGRESS],
    READABLE_STRING_GENERAL
]
```

No formatter base class is required. A routine agent is enough for local
presentation, while a dedicated object can retain state for measurements that
span updates.

## Pure formatter algorithm

A pure formatter can be implemented with this sequence:

1. Append the label owned by the formatter.
2. Branch on `progress.has_total`.
3. For known progress, derive visual fill from `fraction` or use `percentage`.
4. For unknown progress, select a frame from `revision` and display `position`.
5. Suppress animation-only decoration when `is_final`.
6. Append the unit and trailing label.
7. Return a new string, or a buffer that may be reused after the call returns.

For example:

```eiffel
format_files (a_progress: PB_PROGRESS): STRING_32
        -- Format file-count progress.
    do
        create Result.make (32)
        Result.append_string_general ("Files: ")
        Result.append_integer_64 (a_progress.position)
        if a_progress.has_total then
            Result.append_string_general (" / ")
            Result.append_integer_64 (a_progress.total)
        elseif not a_progress.is_final then
            Result.append_string_general (" ...")
        end
    end
```

Connect it directly:

```eiffel
create bar.make_unknown_with_formatter (agent format_files)
```

## Configured formatter object

When several bars share configuration, store that configuration in a normal
class and expose a formatting routine:

```eiffel
class MY_PROGRESS_FORMATTER

create
    make

feature -- Formatting

    format (a_progress: PB_PROGRESS): STRING_32
            -- Render `a_progress` using Current's configuration.
        do
            -- Append label, bar, counter, and unit.
        end

feature {NONE} -- Implementation

    label: STRING_32
    unit: STRING_32

end
```

Then pass the closed agent:

```eiffel
create formatter.make ("Indexing", "documents")
create bar.make_with_formatter (documents.count, agent formatter.format)
```

Copy caller-owned strings in `make` when later external mutation must not alter
the output. This is the same ownership rule used by `PB_FORMATTERS.standard`.

## Stateful formatter algorithm

A formatter object may also compare the current snapshot with state retained
from the previous call:

1. Read the new `position` and the object's previous sample.
2. Obtain any external measurement through the object's own dependency.
3. Derive the presentation value from the sample delta.
4. Build the line.
5. Commit the new sample only after the line has been built successfully.
6. Treat `is_final` explicitly and avoid animation-only output on the final
   line.

This supports rates, smoothed measurements, or ETA without adding time or any
domain dependency to `progress_bar`. The formatter object owns its clock,
sampling policy, and behavior when there is insufficient history.

Do not assume that identical terminal text means the formatter was skipped.
The library invokes the formatter on every logical refresh and deduplicates
only the resulting terminal write, so stateful formatters continue to observe
all updates.

## Units and scaling

Keep unit conversion inside the formatter. A byte formatter, for example,
should:

1. choose a scale from the largest value it must present;
2. use the same scale for position and total;
3. define whether prefixes are decimal or binary;
4. round only for display;
5. fall back to position-only output when the total is unknown.

The bar continues to receive raw absolute integers. This prevents presentation
rounding from affecting completion semantics.
