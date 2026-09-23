class DEMO_APPLICATION

create

	make

feature {NONE} -- Initialization

	make
		do
			show_bar (create {PB_BASIC_PROGRESS_RENDERER}, "Basic")
			show_bar (create {PB_UNICODE_PROGRESS_RENDERER}, "Unicode")
			show_bar (create {PB_CHARGING_PROGRESS_RENDERER}, "Charging")
			show_bar (create {PB_SQUARES_PROGRESS_RENDERER}, "Squares")
			show_bar (create {PB_CIRCLES_PROGRESS_RENDERER}, "Circles")
			show_bar (create {PB_PIXEL_PROGRESS_RENDERER}, "Pixel")
			io.put_new_line
			show_spinner_bar
			show_message_bar
			show_nested_bars
		end

feature {NONE} -- Implementation

	show_bar (a_renderer: PB_PROGRESS_RENDERER; a_name: STRING)
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (20)
			bar.set_renderer (a_renderer)
			bar.put_line (a_name)
			from
			until
				bar.has_finished
			loop
				bar.advance
				pause
			end
		end

	show_spinner_bar
			-- Show a moon spinner bar.
		local
			bar: PB_PROGRESS_BAR
			i: INTEGER
		do
			create bar.make_unknown
			bar.set_renderer (create {PB_MOON_SPINNER_RENDERER})
			from until i = 7 loop
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
			group: PB_MULTIPLE_PROGRESS_RENDERER
			i: INTEGER
		do
			create outer.make_with_total (6)
			create inner.make_with_total (60)
			create group.make (<<outer, inner>>)
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
