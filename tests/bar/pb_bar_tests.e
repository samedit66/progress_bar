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
			create bar.make (10)
			bar.set_formatter (agent capture)
			assert_true ("total known", bar.has_total)
			assert_true ("total", bar.total = 10)
			bar.update (4)
			assert_true ("position", bar.position = 4)
			assert_true ("started", bar.is_started)
			assert_true ("revision", bar.revision = 1)
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
			bar.set_formatter (agent capture)
			assert_false ("total unknown", bar.has_total)
			bar.update (7)
			bar.pulse
			assert_true ("position unchanged by pulse", bar.position = 7)
			assert_true ("revision includes pulse", bar.revision = 2)
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
			bar.set_formatter (agent capture_constant)
			bar.update (1)
			bar.update (2)
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
			bar.set_formatter (agent capture)
			bar.put_line ("before")
			assert_false ("not started by message", bar.is_started)
			assert_integers_equal ("no callback before start", 0, callback_count)
			bar.update (3)
			bar.put_line ("during")
			assert_true ("position preserved", bar.position = 3)
			assert_true ("revision preserved", bar.revision = 1)
			assert_integers_equal ("no callback during message", 1, callback_count)
			bar.finish
			bar.put_line ("after")
			assert_true ("remains finished", bar.is_finished)
			assert_true ("final position preserved", bar.position = 3)
			assert_true ("final revision preserved", bar.revision = 1)
			assert_integers_equal ("no callback after finish", 2, callback_count)
		end

	test_make_child_starts_lazy_parent_once
			-- Start a lazy parent once when creating its first child.
		local
			parent, first_child, second_child: PB_BAR
		do
			reset_capture
			create parent.make (2)
			parent.set_formatter (agent capture)
			create first_child.make_child (parent, 3)
			assert_true ("parent started", parent.is_started)
			assert_true ("parent position preserved", parent.position = 0)
			assert_true ("parent revision advanced", parent.revision = 1)
			assert_integers_equal ("parent rendered once", 1, callback_count)
			assert_true ("child shares display", first_child.display = parent.display)
			assert_true ("child total", first_child.total = 3)
			assert_false ("child remains configurable", first_child.is_started)
			first_child.discard_final_line
			create second_child.make_child (parent, 4)
			assert_true ("parent revision unchanged", parent.revision = 1)
			assert_integers_equal ("parent not rendered again", 1, callback_count)
			first_child.finish
			second_child.finish
			parent.finish
		end

	test_finished_parent_rejects_make_child
			-- Reject child creation after the parent has finished.
		local
			parent: PB_BAR
		do
			create parent.make (1)
			parent.finish
			assert_exception ("finished parent", agent create_child (parent))
		end

feature -- Simplified API tests

	test_absolute_bounds_and_completion
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			reset_capture
			create display.make
			create bar.make_in (display, 100)
			bar.set_formatter (agent capture)
			assert_true ("initial value", bar.position = 0)
			assert_true ("lazy", display.captured.is_empty and callback_count = 0)
			bar.update (40)
			bar.update (40)
			assert_true ("absolute", bar.position = 40)
			bar.update (-1)
			assert_true ("lower clamp", bar.position = 0 and not bar.is_finished)
			bar.update (101)
			assert_true ("upper clamp closes", bar.position = 100 and bar.is_finished)
			assert_true ("one final snapshot", final_callback_count = 1)
			assert_true ("final value", attached last_progress as p and then p.is_final and then p.position = 100)
		end

	test_advance_bounds_and_integer_extremes
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_in (display, {INTEGER_64}.max_value)
			bar.update (40)
			bar.advance (-10)
			assert_true ("relative correction", bar.position = 30)
			bar.advance ({INTEGER_64}.min_value)
			assert_true ("minimum delta", bar.position = 0)
			bar.update ({INTEGER_64}.max_value - 1)
			bar.advance ({INTEGER_64}.max_value)
			assert_true ("overflow safely completes", bar.is_finished and bar.position = {INTEGER_64}.max_value)
			create bar.make_in (display, 100)
			bar.update (95)
			bar.advance (10)
			assert_true ("ordinary overshoot", bar.is_finished and bar.position = 100)
			create bar.make_in (display, 100)
			bar.advance (100)
			assert_true ("exact maximum", bar.is_finished)
		end

	test_unknown_advance_does_not_complete
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_unknown_in (display)
			bar.advance (1)
			bar.advance ({INTEGER_64}.max_value)
			assert_true ("unknown saturates without completion", not bar.is_finished and bar.position = {INTEGER_64}.max_value)
			bar.advance ({INTEGER_64}.min_value)
			assert_true ("unknown lower bound", bar.position = 0)
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
			create bar.make_in (display, 10)
			bar.discard_final_line
			bar.set_formatter (agent capture)
			bar.update (4)
			bar.finish
			old_revision := bar.revision
			display.reset
			bar.update (0)
			bar.advance (100)
			bar.pulse
			bar.set_formatter (agent capture_constant)
			bar.keep_final_line
			bar.discard_final_line
			bar.put_line ("ignored")
			bar.finish
			assert_true ("all commands silent", display.captured.is_empty and callback_count = 2)
			assert_true ("closed state retained", bar.is_finished and bar.position = 4 and bar.revision = old_revision and not bar.keeps_final_line)
		end

	test_formatter_changes_apply_on_next_update
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_unknown_in (display)
			bar.set_formatter (agent capture_constant)
			bar.update (1)
			display.reset
			bar.set_formatter (agent capture)
			assert_true ("setting does not print", display.captured.is_empty)
			bar.update (2)
			assert_true ("shorter frame erases tail", display.captured.same_string ("%R2   %R2"))
			bar.finish
		end

	test_parent_completion_stops_entire_subtree
		local
			parent, child, grandchild, sibling: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create parent.make_in (display, 10)
			create child.make_child (parent, 20)
			create grandchild.make_child (child, 30)
			create sibling.make_in (display, 5)
			child.update (2)
			grandchild.update (3)
			parent.set_formatter (agent capture)
			child.set_formatter (agent capture)
			grandchild.set_formatter (agent capture)
			reset_capture
			parent.update (10)
			assert_true ("whole subtree closed", parent.is_finished and child.is_finished and grandchild.is_finished)
			assert_true ("actual values retained", child.position = 2 and grandchild.position = 3)
			assert_true ("each final formatted once", callback_count = 3 and final_callback_count = 3)
			assert_true ("independent sibling remains open", not sibling.is_finished)
			display.reset
			child.advance (18)
			grandchild.finish
			parent.finish
			assert_true ("closed subtree silent", display.captured.is_empty)
			sibling.advance (5)
			assert_true ("display commits after sibling", display.captured.ends_with ("%N"))
		end

	test_forced_parent_finish_closes_pending_children
		local
			parent, child: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create parent.make_unknown_in (display)
			create child.make_child (parent, 5)
			child.discard_final_line
			parent.update (2)
			parent.finish
			assert_true ("forced close", parent.is_finished and child.is_finished)
			assert_true ("pending actual value", child.position = 0 and not child.is_started)
			assert_true ("unknown actual value", parent.position = 2)
			assert_true ("discarded child not retained", not display.captured.has_substring ("0 / 5"))
		end

	test_zero_total_leaves_no_pending_display_line
		local
			bar, parent, child: PB_BAR
			display: PB_TEST_DISPLAY
		do
			reset_capture
			create display.make
			create bar.make_in (display, 0)
			bar.set_formatter (agent capture)
			bar.advance (1)
			bar.finish
			assert_true ("zero is finished and silent", bar.is_finished and display.captured.is_empty and callback_count = 0)
			create parent.make_in (display, 1)
			create child.make_child (parent, 0)
			assert_true ("empty child is silent", child.is_finished and not parent.is_started and display.captured.is_empty)
			assert_false ("empty child not registered as open", parent.has_open_children)
			parent.advance (1)
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
			create pulsed.make_unknown_in (pulse_display)
			create advanced.make_unknown_in (advance_display)
			pulsed.pulse
			advanced.advance (0)
			assert_true ("first pulse starts without progress", pulsed.is_started and pulsed.position = 0 and pulsed.revision = 1)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.pulse
			advanced.advance (0)
			assert_true ("second pulse increments revision", pulsed.revision = 2)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.update ({INTEGER_64}.max_value)
			advanced.update ({INTEGER_64}.max_value)
			pulsed.pulse
			advanced.advance (0)
			assert_true ("limit stays open", pulsed.position = {INTEGER_64}.max_value and not pulsed.is_finished)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
			pulsed.finish
			advanced.finish
			pulse_display.reset
			advance_display.reset
			pulsed.pulse
			advanced.advance (0)
			assert_true ("finished pulse silent", pulse_display.captured.is_empty)
			assert_same_pulse_state (pulsed, advanced, pulse_display, advance_display)
		end

	test_pulse_keeps_known_total_contract
			-- Reject an active known bar, but ignore a pulse after known completion.
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_in (display, 1)
			assert_exception ("active known pulse rejected", agent bar.pulse)
			assert_true ("rejected pulse unchanged", bar.position = 0 and bar.revision = 0 and display.captured.is_empty)
			bar.advance (1)
			display.reset
			bar.pulse
			assert_true ("known finished pulse ignored", bar.is_finished and bar.revision = 1 and display.captured.is_empty)
			create bar.make_in (display, 0)
			bar.pulse
			assert_true ("zero total pulse ignored", bar.is_finished and bar.revision = 0 and display.captured.is_empty)
		end

feature {NONE} -- Equivalence assertions

	assert_same_pulse_state (pulsed, advanced: PB_BAR; pulse_display, advance_display: PB_TEST_DISPLAY)
			-- Compare public state and the complete emitted terminal sequence.
		do
			assert_true ("same position", pulsed.position = advanced.position)
			assert_true ("same revision", pulsed.revision = advanced.revision)
			assert_true ("same lifecycle", pulsed.is_started = advanced.is_started and pulsed.is_finished = advanced.is_finished)
			assert_true ("same output", pulse_display.captured.same_string (advance_display.captured))
		end

feature {NONE} -- Capture

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

	create_child (a_parent: PB_BAR)
			-- Attempt to create a child of `a_parent`.
		local
			child: PB_BAR
		do
			create child.make_child (a_parent, 1)
		end

end
