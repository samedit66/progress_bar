class PB_PROGRESS_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_known_progress_and_completion
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (3)
			create output.make
			bar.set_renderer (output)
			assert_true ("initial state", bar.has_total and bar.total = 3 and bar.absolute_progress = 0 and not bar.has_finished)
			bar.advance
			assert_true ("one completed unit", bar.absolute_progress = 1 and not bar.has_finished)
			output.reset
			bar.advance_by (2)
			assert_true ("completed", bar.absolute_progress = 3 and bar.has_finished)
			assert_equal ("one final frame", {STRING_32} "%R[3/3]%N", output.captured)
			output.reset
			bar.advance
			bar.advance_by (-2)
			bar.finish
			assert_true ("completion is permanent", bar.absolute_progress = 3 and bar.has_finished and output.captured.is_empty)
		end

	test_unknown_progress_and_explicit_finish
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_unknown
			create output.make
			bar.set_renderer (output)
			assert_false ("unknown total", bar.has_total)
			assert_true ("unknown total sentinel", bar.total = -1)
			bar.advance_by (7)
			assert_true ("unknown remains open", bar.absolute_progress = 7 and not bar.has_finished)
			assert_equal ("unknown display", {STRING_32} "%R[7/?]", output.captured)
			output.reset
			bar.finish
			assert_true ("finish retains actual work", bar.absolute_progress = 7 and bar.has_finished)
			assert_equal ("finished line", {STRING_32} "%R[7/?]%N", output.captured)
		end

	test_signed_updates_and_overshoot
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (10)
			create output.make
			bar.set_renderer (output)
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
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total ({INTEGER_64}.max_value)
			create output.make
			bar.set_renderer (output)
			bar.advance_by ({INTEGER_64}.max_value - 1)
			bar.advance_by (10)
			assert_true ("overflow reaches total", bar.absolute_progress = {INTEGER_64}.max_value and bar.has_finished)
		end

	test_unknown_overflow_stays_open
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_unknown
			create output.make
			bar.set_renderer (output)
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
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (0)
			create output.make
			bar.set_renderer (output)
			assert_false ("construction does not finish", bar.has_finished)
			bar.advance
			assert_true ("empty work completes", bar.has_finished and bar.absolute_progress = 0)
			assert_equal ("empty final frame", {STRING_32} "%R[0/0]%N", output.captured)
		end

	test_negative_total_rejected
		do
			assert_exception ("negative total", agent create_negative_total)
		end

	test_finish_before_updates
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (10)
			create output.make
			bar.set_renderer (output)
			bar.finish
			assert_true ("explicit finish at actual position", bar.has_finished and bar.absolute_progress = 0)
			assert_equal ("zero final frame", {STRING_32} "%R[0/10]%N", output.captured)
		end

feature {NONE} -- Contract probes

	create_negative_total
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (-2)
		end

end
