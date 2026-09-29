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
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			bar.advance
			line := formatter.format (bar)
			assert_false ("elapsed hidden", line.has_substring ("00:00:00"))
			formatter.set_show_timing (True)
			line := formatter.format (bar)
			assert_true ("elapsed shown", line.has_substring ("00:00:00"))
			assert_true ("eta shown", line.has_substring (" ETA "))
			assert_booleans_equal ("bar reports eta", True, bar.has_eta)
		end

	test_unknown_progress_has_no_eta
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			create formatter.make
			formatter.set_show_timing (True)
			line := formatter.format (bar)
			assert_false ("unknown eta", line.has_substring ("ETA"))
			assert_booleans_equal ("unknown has no eta", False, bar.has_eta)
		end

end
