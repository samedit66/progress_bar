class PB_DISPLAY_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_group_preserves_order_and_independent_progress
		local
			first, second: PB_PROGRESS_BAR
			first_position, second_position: INTEGER
			output: PB_CAPTURE_DISPLAY
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_formatter (create {PB_FORMATTER}.make)
			second.set_formatter (create {PB_FORMATTER}.make)
			create output.make
			output.extend (first)
			output.extend (second)
			assert_strings_equal ("construction is silent", "", output.captured.to_string_8)
			first.advance
			first_position := output.captured.substring_index ("50%%", 1)
			second_position := output.captured.substring_index ("0%%", 1)
			assert_true ("ordered initial rows", first_position > 0 and second_position > first_position)
			output.reset
			first.advance
			assert_booleans_equal ("only first completes", True, first.has_finished)
			assert_booleans_equal ("second remains open", False, second.has_finished)
			assert_strings_equal ("second remains at zero", "0", second.absolute_progress.out)
			assert_true ("one final group redraw", output.captured.has_substring ("100%%") and output.captured.has_substring ("0%%"))
			output.reset
			second.advance_by (3)
			assert_booleans_equal ("first completes independently", True, first.has_finished)
			assert_booleans_equal ("second completes independently", True, second.has_finished)
			assert_true ("finished first row retained", output.captured.has_substring ({STRING_32} "100%%"))
			output.reset
			first.finish
			second.advance
			assert_strings_equal ("completed updates are silent", "", output.captured.to_string_8)
		end

	test_group_retains_original_formatters
		local
			first, second: PB_PROGRESS_BAR
			unicode_formatter: PB_FORMATTER
			output: PB_CAPTURE_DISPLAY
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_formatter (create {PB_FORMATTER}.make)
			create unicode_formatter.make
			unicode_formatter.set_fill_character ('=')
			unicode_formatter.set_empty_character ('.')
			second.set_formatter (unicode_formatter)
			create output.make
			output.extend (first)
			output.extend (second)
			first.advance
			assert_true ("basic formatter kept", output.captured.has_substring ("50%%"))
			assert_true ("unicode formatter emitted", output.captured.has_substring (unicode_formatter.format (second)))
		end

	test_message_above_all_rows
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create first.make_unknown
			create second.make_with_total (3)
			first.set_formatter (create {PB_FORMATTER}.make)
			second.set_formatter (create {PB_FORMATTER}.make)
			create output.make
			output.extend (first)
			output.extend (second)
			first.advance
			output.reset
			second.put_line ("Working")
			assert_true ("message is emitted", output.captured.has_substring ("Working%N"))
			assert_true ("unknown row is restored", not output.captured.is_empty)
			assert_true ("known row is restored", output.captured.has_substring ("0%%"))
			assert_strings_equal ("first position unchanged", "1", first.absolute_progress.out)
			assert_strings_equal ("second position unchanged", "0", second.absolute_progress.out)
		end

	test_empty_display_is_silent
		local
			output: PB_CAPTURE_DISPLAY
		do
			create output.make
			output.render
			assert_strings_equal ("empty display is silent", "", output.captured.to_string_8)
		end

end
