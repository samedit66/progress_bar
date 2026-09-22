class DEMO_APPLICATION

create

	make

feature {NONE} -- Initialization

	make
		local
			bar: PB_PROGRESS_BAR
			wrapped: PB_WRAPPED_BAR [STRING]
			first, second: PB_PROGRESS_BAR
			group: PB_MULTIPLE_PROGRESS_RENDERER
		do
			show_bar (create {PB_BASIC_PROGRESS_RENDERER}, "Basic")
			show_bar (create {PB_UNICODE_PROGRESS_RENDERER}, "Unicode")
			show_bar (create {PB_CHARGING_PROGRESS_RENDERER}, "Charging")
			show_bar (create {PB_SQUARES_PROGRESS_RENDERER}, "Squares")
			show_bar (create {PB_CIRCLES_PROGRESS_RENDERER}, "Circles")
			show_bar (create {PB_PIXEL_PROGRESS_RENDERER}, "Pixel")
			create bar.make_unknown
			bar.set_renderer (create {PB_MOON_SPINNER_RENDERER})
			bar.advance_by (3)
			pause
			bar.finish
			create wrapped.wrap (<<"one", "two", "three">>)
			across
				wrapped
			as
				item
			loop
				wrapped.put_line ("Processed: " + item)
				pause
			end
			create first.make_with_total (3)
			create second.make_with_total (5)
			create group.make (<<first, second>>)
			from
			until
				first.has_finished and second.has_finished
			loop
				if not first.has_finished then
					first.advance
				end
				if not second.has_finished then
					second.advance
				end
				pause
			end
		end

feature {NONE} -- Implementation

	show_bar (a_renderer: PB_PROGRESS_RENDERER; a_name: STRING)
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (10)
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

	pause
			-- Leave enough time between frames for terminal recording.
		do
			{EXECUTION_ENVIRONMENT}.sleep (100_000_000)
		end

end
