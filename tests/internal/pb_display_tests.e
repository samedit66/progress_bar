note

	description:

		"Tests for coordinated multiline progress display behavior."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_DISPLAY_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_private_single_line_sequences_are_preserved
			-- Keep the original carriage-return protocol when only one row is used.
		local
			display: PB_TEST_DISPLAY
			bar: PB_BAR
		do
			create display.make
			create bar.make_with_total (2)
			bar.set_display (display)
			bar.set_line_formatter (agent position_text)
			bar.set_progress (1)
			assert_true ("redraw sequence", display.captured.same_string ("%Rfirst 1"))
			display.reset
			bar.finish
			assert_true ("finish sequence", display.captured.same_string ("%Rfirst 1%N"))
		end

	test_shared_rows_update_independently
			-- Render a second below its first and update either line independently.
		local
			display: PB_TEST_DISPLAY
			first, second: PB_BAR
		do
			create display.make
			create first.make_with_total (2)
			first.set_display (display)
			first.set_line_formatter (agent position_text)
			first.start
			create second.make_with_total (1)
			second.set_display (first.display)
			second.set_progress (0)
			assert_true ("shared display", second.display = first.display)
			assert_true ("both lines repainted", display.captured.has_substring ("first 0%N%R[") and then display.captured.has_substring ("0 / 1"))
			display.reset
			first.set_progress (1)
			assert_true ("first update moves up", display.captured.has_substring ({STRING_32} "%/27/[1A"))
			assert_false ("second not reformatted", display.captured.has_substring ("0 / 1"))
			second.finish
			first.finish
		end

	test_put_line_repaints_complete_frame
			-- Preserve every active line around a multiline message.
		local
			display: PB_TEST_DISPLAY
			first, second: PB_BAR
		do
			create display.make
			create first.make_with_total (1)
			first.set_display (display)
			first.set_line_formatter (agent position_text)
			first.start
			create second.make_with_total (1)
			second.set_display (first.display)
			second.set_progress (0)
			display.reset
			first.put_line ("first%Nsecond")
			assert_true ("message retained", display.captured.has_substring ("first%Nsecond"))
			assert_true ("first restored", display.captured.has_substring ("first 0"))
			assert_true ("second restored", display.captured.has_substring ("0 / 1"))
			second.finish
			first.finish
		end

	test_unchanged_line_does_not_emit
			-- Avoid terminal output when a refreshed line has unchanged text.
		local
			display: PB_TEST_DISPLAY
			bar: PB_BAR
		do
			create display.make
			create bar.make_unknown
			bar.set_display (display)
			bar.set_line_formatter (agent constant_text)
			bar.set_progress (1)
			display.reset
			bar.set_progress (2)
			assert_true ("no duplicate output", display.captured.is_empty)
			bar.finish
		end

	test_discarded_second_is_removed
			-- Remove a second's final row while leaving its first active.
		local
			display: PB_TEST_DISPLAY
			first, second: PB_BAR
		do
			create display.make
			create first.make_with_total (1)
			first.set_display (display)
			first.set_line_formatter (agent position_text)
			first.start
			create second.make_with_total (1)
			second.set_display (first.display)
			second.discard_final_line
			second.set_progress (0)
			display.reset
			second.set_progress (1)
			assert_false ("policy", second.keeps_final_line)
			assert_true ("first repainted", display.captured.has_substring ("first 0"))
			assert_false ("second removed", display.captured.has_substring ("1 / 1"))
			first.finish
		end

	test_three_rows_follow_start_order
			-- Keep three independent rows in their start order.
		local
			display: PB_TEST_DISPLAY
			first, second, third: PB_BAR
			first_index, second_index, third_index: INTEGER
		do
			create display.make
			create first.make_with_total (1)
			first.set_display (display)
			first.set_line_formatter (agent position_text)
			first.start
			create second.make_with_total (2)
			second.set_display (first.display)
			second.set_progress (0)
			second.start
			create third.make_with_total (3)
			third.set_display (second.display)
			display.reset
			third.set_progress (0)
			first_index := display.captured.substring_index ("first 0", 1)
			second_index := display.captured.substring_index ("0 / 2", first_index + 1)
			third_index := display.captured.substring_index ("0 / 3", second_index + 1)
			assert_true ("start order", first_index > 0 and then second_index > first_index and then third_index > second_index)
			third.finish
			second.finish
			first.finish
		end

feature {NONE} -- Formatting

	position_text (a_progress: PB_PROGRESS): STRING_32
			-- Parent line showing position.
		do
			create Result.make (16)
			Result.append_string_general ("first ")
			Result.append_integer_64 (a_progress.position)
		end

	constant_text (a_progress: PB_PROGRESS): STRING_32
			-- Stable line independent of `a_progress`.
		do
			Result := "same"
		end

end
