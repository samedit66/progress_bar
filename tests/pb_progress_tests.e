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
			assert_true ("initial state", bar.has_total and bar.progress_limit = 3 and bar.absolute_progress = 0 and not bar.has_finished)
			bar.advance
			assert_true ("one completed unit", bar.absolute_progress = 1 and not bar.has_finished)
			output.reset
			bar.advance_by (2)
			assert_true ("completed", bar.absolute_progress = 3 and bar.has_finished)
			assert_true ("one final frame", output.captured.has_substring ("100%%") and output.captured.has_substring ("%N"))
			output.reset
			bar.advance
			bar.advance_by (-2)
			bar.finish
			assert_true ("completion is permanent", bar.absolute_progress = 3 and bar.has_finished and output.captured.is_empty)
		end

	test_unknown_progress_and_explicit_finish
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_unknown
			create output.make
			output.extend (bar)
			assert_false ("unknown total", bar.has_total)
			assert_true ("unknown progress limit", bar.progress_limit = {INTEGER_64}.max_value)
			bar.advance_by (7)
			assert_true ("unknown remains open", bar.absolute_progress = 7 and not bar.has_finished)
			assert_true ("unknown display", not output.captured.is_empty)
			output.reset
			bar.finish
			assert_true ("finish retains actual work", bar.absolute_progress = 7 and bar.has_finished)
			assert_true ("finished line", not output.captured.is_empty and output.captured.has_substring ("%N"))
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
			assert_true ("backward update", bar.absolute_progress = 4)
			bar.advance_by ({INTEGER_64}.min_value)
			assert_true ("lower bound", bar.absolute_progress = 0 and not bar.has_finished)
			bar.advance_by ({INTEGER_64}.max_value)
			assert_true ("upper bound completes", bar.absolute_progress = 10 and bar.has_finished)
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
			assert_true ("overflow reaches total", bar.absolute_progress = {INTEGER_64}.max_value and bar.has_finished)
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
			assert_true ("saturated but unfinished", bar.absolute_progress = {INTEGER_64}.max_value and not bar.has_finished)
			bar.advance_by ({INTEGER_64}.min_value)
			assert_true ("can move back from maximum", bar.absolute_progress = 0)
		end

	test_zero_total_finishes_on_update
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (0)
			create output.make
			output.extend (bar)
			assert_false ("construction does not finish", bar.has_finished)
			bar.advance
			assert_true ("empty work completes", bar.has_finished and bar.absolute_progress = 0)
			assert_true ("empty final frame", output.captured.has_substring ("100%%") and output.captured.has_substring ("%N"))
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
			assert_true ("ratio", (bar.progress_ratio - 0.5).abs < 0.0001)
			assert_true ("percentage", bar.progress_percentage = 50)
		end

	test_zero_total_characteristics
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (0)
			assert_true ("zero ratio", bar.progress_ratio = 1.0)
			assert_true ("zero percentage", bar.progress_percentage = 100)
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
			assert_true ("explicit finish at actual position", bar.has_finished and bar.absolute_progress = 0)
			assert_true ("zero final frame", output.captured.has_substring ("0%%") and output.captured.has_substring ("%N"))
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
