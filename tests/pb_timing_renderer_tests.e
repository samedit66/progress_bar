class PB_PROGRESS_TIMING_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_known_progress_has_eta
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_STANDARD_PROGRESS_RENDERER
			line: STRING_32
		do
			create bar.make_with_total (10)
			create renderer.make
			bar.set_renderer (renderer)
			bar.advance
			line := renderer.format_line (bar)
			assert_true ("elapsed shown", line.has_substring ("00:00:00"))
			assert_true ("eta shown", line.has_substring (" ETA "))
			assert_true ("bar reports eta", bar.has_eta)
		end

	test_unknown_progress_has_no_eta
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_SPINNER_PROGRESS_RENDERER
			line: STRING_32
		do
			create bar.make_unknown
			create renderer.make
			line := renderer.format_line (bar)
			assert_false ("unknown eta", line.has_substring ("ETA"))
			assert_false ("unknown has no eta", bar.has_eta)
		end

	test_countdown_handles_unknown_progress
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_SPINNER_PROGRESS_RENDERER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Processing")
			create renderer.make
			renderer.set_show_phase (False)
			renderer.set_show_remaining (True)
			line := renderer.format_line (bar)
			assert_true ("unknown countdown", line.same_string ("Processing ? left"))
		end

end
