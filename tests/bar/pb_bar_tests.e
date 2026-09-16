note

	description:

		"Tests for manual progress lifecycle and formatter invocation."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_BAR_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_known_progress
			-- Update and finish progress with a known total.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_with_total (10)
			bar.set_line_formatter (agent capture)
			assert_true ("total known", bar.has_total)
			assert_true ("total", bar.total = 10)
			bar.set_progress (4)
			assert_true ("position", bar.progress = 4)
			assert_true ("started", bar.is_started)
			assert_true ("revision", last_revision = 1)
			assert_true ("snapshot known", attached last_progress as progress and then progress.has_total)
			bar.finish
			assert_true ("finished", bar.is_finished)
			assert_true ("final snapshot", attached last_progress as progress and then progress.is_final)
			assert_integers_equal ("update and finish callbacks", 2, callback_count)
			bar.finish
			assert_integers_equal ("second finish is no-op", 2, callback_count)
		end

	test_unknown_progress
			-- Update and pulse progress whose total is unknown.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown
			bar.set_line_formatter (agent capture)
			assert_false ("total unknown", bar.has_total)
			bar.set_progress (7)
			bar.pulse
			assert_true ("position unchanged by pulse", bar.progress = 7)
			assert_true ("revision includes pulse", last_revision = 2)
			assert_true ("snapshot unknown", attached last_progress as progress and then not progress.has_total)
			bar.finish
			assert_true ("unknown final snapshot", attached last_progress as progress and then progress.is_final)
		end

	test_formatter_called_when_text_is_unchanged
			-- Invoke the formatter for every logical refresh request.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown
			bar.set_line_formatter (agent capture_constant)
			bar.set_progress (1)
			bar.set_progress (2)
			bar.pulse
			assert_integers_equal ("every request formatted", 3, callback_count)
			bar.finish
			assert_integers_equal ("finish formatted", 4, callback_count)
		end

	test_put_line_preserves_progress
			-- Write messages throughout the lifecycle without changing progress.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown
			bar.set_line_formatter (agent capture)
			bar.put_line ("before")
			assert_false ("not started by message", bar.is_started)
			assert_integers_equal ("no callback before start", 0, callback_count)
			bar.set_progress (3)
			bar.put_line ("during")
			assert_true ("position preserved", bar.progress = 3)
			assert_true ("revision preserved", last_revision = 1)
			assert_integers_equal ("no callback during message", 1, callback_count)
			bar.finish
			bar.put_line ("after")
			assert_true ("remains finished", bar.is_finished)
			assert_true ("final position preserved", bar.progress = 3)
			assert_true ("final revision preserved", last_revision = 1)
			assert_integers_equal ("no callback after finish", 2, callback_count)
		end

feature -- Simplified API tests

	test_absolute_bounds_and_completion
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			reset_capture
			create display.make
			create bar.make_with_total (100)
			bar.set_display (display)
			bar.set_line_formatter (agent capture)
			assert_true ("initial value", bar.progress = 0)
			assert_true ("lazy", display.captured.is_empty and callback_count = 0)
			bar.set_progress (40)
			bar.set_progress (40)
			assert_true ("absolute", bar.progress = 40)
			bar.set_progress (-1)
			assert_true ("lower clamp", bar.progress = 0 and not bar.is_finished)
			bar.set_progress (101)
			assert_true ("upper clamp closes", bar.progress = 100 and bar.is_finished)
			assert_true ("one final snapshot", final_callback_count = 1)
			assert_true ("final value", attached last_progress as p and then p.is_final and then p.position = 100)
		end

	test_advance_bounds_and_integer_extremes
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_with_total ({INTEGER_64}.max_value)
			bar.set_display (display)
			bar.set_progress (40)
			bar.forth_by (-10)
			assert_true ("relative correction", bar.progress = 30)
			bar.forth_by ({INTEGER_64}.min_value)
			assert_true ("minimum delta", bar.progress = 0)
			bar.set_progress ({INTEGER_64}.max_value - 1)
			bar.forth_by ({INTEGER_64}.max_value)
			assert_true ("overflow safely completes", bar.is_finished and bar.progress = {INTEGER_64}.max_value)
			create bar.make_with_total (100)
			bar.set_display (display)
			bar.set_progress (95)
			bar.forth_by (10)
			assert_true ("ordinary overshoot", bar.is_finished and bar.progress = 100)
			create bar.make_with_total (100)
			bar.set_display (display)
			bar.forth_by (100)
			assert_true ("exact maximum", bar.is_finished)
		end

	test_unknown_advance_does_not_complete
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_unknown
			bar.set_display (display)
			bar.forth_by (1)
			bar.forth_by ({INTEGER_64}.max_value)
			assert_true ("unknown saturates without completion", not bar.is_finished and bar.progress = {INTEGER_64}.max_value)
			bar.forth_by ({INTEGER_64}.min_value)
			assert_true ("unknown lower bound", bar.progress = 0)
			bar.finish
		end

	test_finished_commands_are_silent
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
			old_revision: INTEGER_64
		do
			reset_capture
			create display.make
			create bar.make_with_total (10)
			bar.set_display (display)
			bar.discard_final_line
			bar.set_line_formatter (agent capture)
			bar.set_progress (4)
			bar.finish
			old_revision := last_revision
			display.reset
			bar.set_progress (0)
			bar.forth_by (100)
			bar.pulse
			bar.set_line_formatter (agent capture_constant)
			bar.keep_final_line
			bar.discard_final_line
			bar.put_line ("ignored")
			bar.finish
			assert_true ("all commands silent", display.captured.is_empty and callback_count = 2)
			assert_true ("closed state retained", bar.is_finished and bar.progress = 4 and last_revision = old_revision and not bar.keeps_final_line)
		end

	test_formatter_changes_apply_on_next_update
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_unknown
			bar.set_display (display)
			bar.set_line_formatter (agent capture_constant)
			bar.set_progress (1)
			display.reset
			bar.set_line_formatter (agent capture)
			assert_true ("setting does not print", display.captured.is_empty)
			bar.set_progress (2)
			assert_true ("shorter frame erases tail", display.captured.same_string ("%R2   %R2"))
			bar.finish
		end

	test_zero_total_leaves_no_pending_display_line
		local
			bar, next_bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			reset_capture
			create display.make
			create bar.make_with_total (0)
			bar.set_display (display)
			bar.set_line_formatter (agent capture)
			bar.forth_by (1)
			bar.finish
			assert_true ("zero is finished and silent", bar.is_finished and display.captured.is_empty and callback_count = 0)
			create next_bar.make_with_total (1)
			next_bar.set_display (display)
			next_bar.forth
			assert_true ("no pending line prevents final newline", display.captured.ends_with ("%N"))
		end

feature -- Pulse equivalence

	test_pulse_matches_zero_advance
			-- Preserve state and exact spinner output at zero, at the limit, and after finish.
		local
			pulsed, advanced: PB_BAR
			pulse_display, advance_display: PB_TEST_DISPLAY
		do
			create pulse_display.make
			create advance_display.make
			create pulsed.make_unknown
			pulsed.set_display (pulse_display)
			create advanced.make_unknown
			advanced.set_display (advance_display)
			pulsed.pulse
			advanced.forth_by (0)
			assert_true ("first pulse starts without progress", pulsed.is_started and pulsed.progress = 0)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.pulse
			advanced.forth_by (0)
			assert_true ("second pulse changes spinner", pulse_display.captured.has_substring ("-  0"))
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.set_progress ({INTEGER_64}.max_value)
			advanced.set_progress ({INTEGER_64}.max_value)
			pulsed.pulse
			advanced.forth_by (0)
			assert_true ("limit stays open", pulsed.progress = {INTEGER_64}.max_value and not pulsed.is_finished)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.finish
			advanced.finish
			pulse_display.reset
			advance_display.reset
			pulsed.pulse
			advanced.forth_by (0)
			assert_true ("finished pulse silent", pulse_display.captured.is_empty)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
		end

	test_pulse_keeps_known_total_contract
			-- Reject an active known bar, but ignore a pulse after known completion.
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			reset_capture
			create display.make
			create bar.make_with_total (1)
			bar.set_display (display)
			bar.set_line_formatter (agent capture)
			assert_exception ("active known pulse rejected", agent bar.pulse)
			assert_true ("rejected pulse unchanged", bar.progress = 0 and last_revision = 0 and display.captured.is_empty)
			bar.forth_by (1)
			display.reset
			bar.pulse
			assert_true ("known finished pulse ignored", bar.is_finished and last_revision = 1 and display.captured.is_empty)
			reset_capture
			create bar.make_with_total (0)
			bar.set_display (display)
			bar.set_line_formatter (agent capture)
			bar.pulse
			assert_true ("zero total pulse ignored", bar.is_finished and last_revision = 0 and display.captured.is_empty)
		end

feature {NONE} -- Equivalence assertions

	assert_same_pulse_state (pulsed, advanced: PB_BAR; pulse_display, advance_display: PB_TEST_DISPLAY)
			-- Compare public state and the complete emitted terminal sequence.
		do
			assert_true ("same position", pulsed.progress = advanced.progress)
			assert_true ("same lifecycle", pulsed.is_started = advanced.is_started and pulsed.is_finished = advanced.is_finished)
			assert_true ("same output", pulse_display.captured.same_string (advance_display.captured))
		end

feature {NONE} -- Capture

	last_revision: INTEGER_64
			-- Last revision received through the public formatter contract.
		do
			if attached last_progress as snapshot then
				Result := snapshot.revision
			end
		end

	last_progress: detachable PB_PROGRESS
			-- Most recent progress passed to a formatter.

	final_callback_count: INTEGER

	callback_count: INTEGER
			-- Number of formatter invocations.

	reset_capture
			-- Forget previously captured formatter calls.
		do
			last_progress := Void
			callback_count := 0
			final_callback_count := 0
		end

	capture (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` and return its position.
		do
			last_progress := a_progress
			if a_progress.is_final then
				final_callback_count := final_callback_count + 1
			end
			callback_count := callback_count + 1
			create Result.make (16)
			Result.append_integer_64 (a_progress.position)
		end

	capture_constant (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` and always return the same line.
		do
			last_progress := a_progress
			if a_progress.is_final then
				final_callback_count := final_callback_count + 1
			end
			callback_count := callback_count + 1
			Result := "same"
		end

end
