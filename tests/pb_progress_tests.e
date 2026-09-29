class PB_PROGRESS_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_known_progress_and_completion
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (3)
			create output.make
			output.extend (bar)
			assert_booleans_equal ("initial total is known", True, bar.has_total)
			assert_strings_equal ("initial limit", "3", bar.progress_limit.out)
			assert_strings_equal ("initial progress", "0", bar.absolute_progress.out)
			assert_booleans_equal ("initial bar is open", False, bar.has_finished)
			bar.advance
			assert_strings_equal ("one completed unit", "1", bar.absolute_progress.out)
			assert_booleans_equal ("one unit leaves bar open", False, bar.has_finished)
			output.reset
			bar.advance_by (2)
			assert_strings_equal ("completed progress", "3", bar.absolute_progress.out)
			assert_booleans_equal ("completed bar", True, bar.has_finished)
			assert_true ("one final frame contains percentage", output.captured.has_substring ("100%%"))
			assert_true ("one final frame ends with newline", output.captured.has_substring ("%N"))
			output.reset
			bar.advance
			bar.advance_by (-2)
			bar.finish
			assert_strings_equal ("completion remains at total", "3", bar.absolute_progress.out)
			assert_booleans_equal ("completion remains permanent", True, bar.has_finished)
			assert_strings_equal ("completed updates are silent", "", output.captured.to_string_8)
		end

	test_unknown_progress_and_explicit_finish
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_unknown
			create output.make
			output.extend (bar)
			assert_booleans_equal ("unknown total", False, bar.has_total)
			assert_strings_equal ("unknown progress limit", {INTEGER_64}.max_value.out, bar.progress_limit.out)
			bar.advance_by (7)
			assert_strings_equal ("unknown progress", "7", bar.absolute_progress.out)
			assert_booleans_equal ("unknown remains open", False, bar.has_finished)
			assert_true ("unknown display", not output.captured.is_empty)
			output.reset
			bar.finish
			assert_strings_equal ("finish retains actual work", "7", bar.absolute_progress.out)
			assert_booleans_equal ("finish closes unknown bar", True, bar.has_finished)
			assert_true ("finished line is emitted", not output.captured.is_empty)
			assert_true ("finished line ends with newline", output.captured.has_substring ("%N"))
		end

	test_signed_updates_and_overshoot
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (10)
			create output.make
			output.extend (bar)
			bar.advance_by (7)
			bar.advance_by (-3)
			assert_strings_equal ("backward update", "4", bar.absolute_progress.out)
			bar.advance_by ({INTEGER_64}.min_value)
			assert_strings_equal ("lower bound", "0", bar.absolute_progress.out)
			assert_booleans_equal ("lower bound remains open", False, bar.has_finished)
			bar.advance_by ({INTEGER_64}.max_value)
			assert_strings_equal ("upper bound", "10", bar.absolute_progress.out)
			assert_booleans_equal ("upper bound completes", True, bar.has_finished)
		end

	test_known_overflow_saturates
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total ({INTEGER_64}.max_value)
			create output.make
			output.extend (bar)
			bar.advance_by ({INTEGER_64}.max_value - 1)
			bar.advance_by (10)
			assert_strings_equal ("overflow reaches total", {INTEGER_64}.max_value.out, bar.absolute_progress.out)
			assert_booleans_equal ("known overflow completes", True, bar.has_finished)
		end

	test_unknown_overflow_stays_open
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_unknown
			create output.make
			output.extend (bar)
			bar.advance_by ({INTEGER_64}.max_value - 1)
			bar.advance_by (10)
			bar.advance
			assert_strings_equal ("unknown saturation", {INTEGER_64}.max_value.out, bar.absolute_progress.out)
			assert_booleans_equal ("unknown saturation remains open", False, bar.has_finished)
			bar.advance_by ({INTEGER_64}.min_value)
			assert_strings_equal ("can move back from maximum", "0", bar.absolute_progress.out)
		end

	test_zero_total_finishes_on_update
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (0)
			create output.make
			output.extend (bar)
			assert_booleans_equal ("construction does not finish", False, bar.has_finished)
			bar.advance
			assert_booleans_equal ("empty work completes", True, bar.has_finished)
			assert_strings_equal ("empty work progress", "0", bar.absolute_progress.out)
			assert_true ("empty final frame contains percentage", output.captured.has_substring ("100%%"))
			assert_true ("empty final frame ends with newline", output.captured.has_substring ("%N"))
		end

	test_negative_total_rejected
		do
			assert_exception ("negative total", agent create_negative_total)
		end

	test_progress_characteristics
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (4)
			bar.advance_by (2)
			assert_doubles_equal_with_tolerance ("ratio", 0.5, bar.progress_ratio, 0.0001)
			assert_integers_equal ("percentage", 50, bar.progress_percentage.to_integer_32)
		end

	test_zero_total_characteristics
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (0)
			assert_doubles_equal_with_tolerance ("zero ratio", 1.0, bar.progress_ratio, 0.0001)
			assert_integers_equal ("zero percentage", 100, bar.progress_percentage.to_integer_32)
		end

	test_unknown_characteristics_rejected
		do
			assert_exception ("unknown ratio", agent query_unknown_ratio)
		end

	test_finish_before_updates
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (10)
			create output.make
			output.extend (bar)
			bar.finish
			assert_booleans_equal ("explicit finish", True, bar.has_finished)
			assert_strings_equal ("explicit finish progress", "0", bar.absolute_progress.out)
			assert_true ("zero final frame contains percentage", output.captured.has_substring ("0%%"))
			assert_true ("zero final frame ends with newline", output.captured.has_substring ("%N"))
		end

	test_set_total_preserves_progress
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_unknown
			bar.advance_by (3)
			bar.set_total (10)
			assert_booleans_equal ("total becomes known", True, bar.has_total)
			assert_strings_equal ("new total", "10", bar.progress_limit.out)
			assert_strings_equal ("progress is preserved", "3", bar.absolute_progress.out)
			assert_booleans_equal ("converted bar remains open", False, bar.has_finished)
		end

	test_set_absolute_progress_does_not_render
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (10)
			create output.make
			output.extend (bar)
			bar.set_absolute_progress (4)
			assert_strings_equal ("progress is set", "4", bar.absolute_progress.out)
			assert_booleans_equal ("setting progress leaves bar open", False, bar.has_finished)
			assert_strings_equal ("setting progress is silent", "", output.captured.to_string_8)
		end

feature {NONE} -- Contract probes

	create_negative_total
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (-2)
		end

	query_unknown_ratio
		local
			bar: PB_PROGRESS_BAR
			ratio: REAL_64
		do
			create bar.make_unknown
			ratio := bar.progress_ratio
		end

end
