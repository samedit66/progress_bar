# Original API sketch

Preserved from the quick-start working copy before implementing the revised API.
This is design history, not a compilable example; see [the tutorial](tutorial.md)
for the implemented interface.

```eiffel
local
		simple_bar: PB_SIMPLE_BAR
		items: ARRAYED_LIST [STRING]
		bar: PB_BAR [STRING] -- Bar definition requires a type parameter.
		unknown_bar: PB_BAR [INTEGER]
	do
		-- Let's make a bar with 100 steps and iterate over it.
	    create simple_bar.make_with_total (100) -- Make a bar with 100 steps.

		-- Design note: `make_with_total` calls the described below `make_over`
		-- with an iterable of integers from 1 to 100.

		across
			simple_bar
		as
			step -- It's an integer from 1 to 100.
		loop
			do_work (step) -- Do some work here.
			-- The bar updates itself!
		end

		-- Now let's make a bar that iterates over an iterable.
		items := << "parse", "analyze", "emit" >>
		create bar.make_over (items)

		-- Design note: here goes a tricky part how to determine the total number of steps.
		-- The bar will try to get the count from the iterable (by conforming to `FINITE`).
		-- If it can't, it will use an unknown total.

		across -- Walk through the progress.
			bar
		as
			item -- It's an a string from the arrayed list.
		loop
			do_other_work (item) -- Do some work here.
		end

		-- Finally let's take a look at the bar with unknown total. This is useful when you don't know how many steps there are.
		create unknown_bar.make_unknown -- Bar starts rendering immediately, but it doesn't know how many steps there are. It will show a spinner instead of a progress bar.
		from
		until
			unknown_bar.is_finished
		loop
			do_some_other_work -- Do some work here.

			if some_condition (unknown_bar.progress) then
				unknown_bar.finish -- Force the bar to finish.
			else
				unknown_bar.advance -- Advance the bar by one step.
				-- It also supports `advance_by (delta)` to advance by a specific number of steps and
				-- `set_progress (new_progress)` to set the progress to a specific value.
			end
		end

		-- You may also set up a custom formatter for the bar.
		-- `set_line_formatter (a_formatter)` sets a formatter for the bar's line.
	end
```
