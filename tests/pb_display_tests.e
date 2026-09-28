class PB_DISPLAY_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_group_preserves_order_and_independent_progress
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_formatter (create {PB_FORMATTER}.make)
			second.set_formatter (create {PB_FORMATTER}.make)
			create output.make
			output.extend (first)
			output.extend (second)
			assert_true ("construction is silent", output.captured.is_empty)
			first.advance
			assert_true ("ordered initial rows", output.captured.has_substring ("50%%") and output.captured.has_substring ("0%%"))
			output.reset
			first.advance
			assert_true ("only first completes", first.has_finished and not second.has_finished and second.absolute_progress = 0)
			assert_true ("one final group redraw", output.captured.has_substring ("100%%") and output.captured.has_substring ("0%%"))
			output.reset
			second.advance_by (3)
			assert_true ("both complete independently", first.has_finished and second.has_finished)
			assert_true ("finished first row retained", output.captured.has_substring ({STRING_32} "100%%"))
			assert_true ("second final row", output.captured.has_substring ({STRING_32} "100%%"))
			output.reset
			first.finish
			second.advance
			assert_true ("completed updates are silent", output.captured.is_empty)
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
			assert_true ("unicode formatter kept", output.captured.has_substring (unicode_formatter.format (second)))
			assert_true ("unicode row actually emitted", output.captured.has_substring (unicode_formatter.format (second)))
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
			assert_true ("positions unchanged", first.absolute_progress = 1 and second.absolute_progress = 0)
		end

	test_empty_display_is_silent
		local
			output: PB_CAPTURE_DISPLAY
		do
			create output.make
			output.render
			assert_true ("empty display is silent", output.captured.is_empty)
		end

end
