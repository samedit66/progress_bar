class DEMO_APPLICATION

create

	make

feature {NONE} -- Initialization

	make
		do
			show_bar ("Default", '#', ' ')
			show_bar ("Blocks", '%/9608/', '%/9617/')
			show_bar ("Dots", '%/9673/', '%/9711/')
			show_bar ("Squares", '%/9635/', '%/9634/')
			io.put_new_line
			show_spinner_bar
			show_message_bar
			show_nested_bars
		end

feature {NONE} -- Implementation

	show_bar (a_name: STRING; a_fill, a_empty: CHARACTER_32)
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
		do
			create bar.make_with_total (20)
			create formatter.make
			formatter.set_fill_character (a_fill)
			formatter.set_empty_character (a_empty)
			bar.set_description (a_name)
			bar.set_formatter (formatter)
			from
			until
				bar.has_finished
			loop
				bar.advance
				pause
			end
		end

	show_spinner_bar
			-- Show a phase-based spinner bar.
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			i: INTEGER
		do
			create bar.make_unknown
			bar.set_description ("Loading")
			create formatter.make
			formatter.set_show_phases_for_unknown (True)
			bar.set_formatter (formatter)
			from
			until
				i = 7
			loop
				bar.advance
				pause
				i := i + 1
			end
			bar.finish
			io.put_new_line
		end

	show_message_bar
			-- Show messages while a longer operation is in progress.
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (50)
			from
			until
				bar.has_finished
			loop
				bar.advance
				if bar.absolute_progress \\ 10 = 0 then
					bar.put_line ("Processed batch " + bar.absolute_progress.out + "/50")
				end
				pause
			end
			io.put_new_line
		end

	show_nested_bars
			-- Show an outer operation advancing around a longer inner operation.
		local
			outer, inner: PB_PROGRESS_BAR
			display: PB_DISPLAY
			i: INTEGER
		do
			create outer.make_with_total (6)
			create inner.make_with_total (60)
			create display.make
			display.extend (outer)
			display.extend (inner)
			from
				i := 1
			until
				inner.has_finished
			loop
				inner.advance
				if i \\ 10 = 0 then
					outer.advance
				end
				i := i + 1
				pause
			end
			io.put_new_line
		end

	pause
			-- Leave enough time between frames for terminal recording.
		do
			{EXECUTION_ENVIRONMENT}.sleep (100_000_000)
		end

end
