class PB_TIMING_FORMATTER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_known_progress_has_eta
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_with_total (10)
			create formatter.make
			formatter.set_show_elapsed (True)
			bar.set_formatter (formatter)
			bar.advance
			line := formatter.format (bar)
			assert_true ("elapsed shown", line.has_substring ("00:00:00"))
			assert_true ("eta shown", line.has_substring (" ETA "))
			assert_true ("bar reports eta", bar.has_eta)
		end

	test_unknown_progress_has_no_eta
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			create formatter.make
			line := formatter.format (bar)
			assert_false ("unknown eta", line.has_substring ("ETA"))
			assert_false ("unknown has no eta", bar.has_eta)
		end

	test_countdown_handles_unknown_progress
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Processing")
			create formatter.make
			formatter.set_show_phases (False)
			formatter.set_show_remaining (True)
			line := formatter.format (bar)
			assert_true ("unknown countdown", line.same_string ("Processing ? left"))
		end

end
