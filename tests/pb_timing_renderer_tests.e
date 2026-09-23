class PB_TIMING_RENDERER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_known_progress_has_eta
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_TIMING_RENDERER
			line: STRING_32
		do
			create bar.make_with_total (10)
			create renderer.make (create {PB_BASIC_PROGRESS_RENDERER})
			bar.set_renderer (renderer)
			bar.advance_by (1)
			line := renderer.format_line (bar)
			assert_true ("elapsed shown", line.has_substring ("00:00:00"))
			assert_true ("eta shown", line.has_substring (" ETA "))
		end

	test_unknown_progress_has_no_eta
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_TIMING_RENDERER
			line: STRING_32
		do
			create bar.make_unknown
			create renderer.make (create {PB_BASIC_PROGRESS_RENDERER})
			line := renderer.format_line (bar)
			assert_true ("unknown eta", line.has_substring (" ETA --:--:--"))
		end

end
