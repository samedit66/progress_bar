class PB_MULTIPLE_RENDERER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_group_preserves_order_and_independent_progress
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_PROGRESS_GROUP
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_renderer (create {PB_STANDARD_PROGRESS_RENDERER}.make)
			second.set_renderer (create {PB_STANDARD_PROGRESS_RENDERER}.make)
			create output.make (<<first, second>>)
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
			unicode_renderer: PB_STANDARD_PROGRESS_RENDERER
			output: PB_CAPTURE_PROGRESS_GROUP
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_renderer (create {PB_STANDARD_PROGRESS_RENDERER}.make)
			create unicode_renderer.make
			unicode_renderer.set_fill_character ('=')
			unicode_renderer.set_empty_character ('.')
			second.set_renderer (unicode_renderer)
			create output.make (<<first, second>>)
			first.advance
			assert_true ("basic formatter kept", output.format_line (first).has_substring ("50%%"))
			assert_equal ("unicode formatter kept", unicode_renderer.format_line (second), output.format_line (second))
			assert_true ("unicode row actually emitted", output.captured.has_substring (unicode_renderer.format_line (second)))
		end

	test_message_above_all_rows
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_PROGRESS_GROUP
		do
			create first.make_unknown
			create second.make_with_total (3)
			first.set_renderer (create {PB_STANDARD_PROGRESS_RENDERER}.make)
			second.set_renderer (create {PB_STANDARD_PROGRESS_RENDERER}.make)
			create output.make (<<first, second>>)
			first.advance
			output.reset
			second.put_line ("Working")
			assert_true ("message is emitted", output.captured.has_substring ("Working%N"))
			assert_true ("unknown row is restored", output.captured.has_substring ("[1/?]"))
			assert_true ("known row is restored", output.captured.has_substring ("0%%"))
			assert_true ("positions unchanged", first.absolute_progress = 1 and second.absolute_progress = 0)
		end

	test_empty_group_rejected
		do
			assert_exception ("at least one bar required", agent create_empty_group)
		end

feature {NONE} -- Contract probes

	create_empty_group
		local
			output: PB_CAPTURE_PROGRESS_GROUP
			bars: ARRAY [PB_PROGRESS_BAR]
		do
			create bars.make_empty
			create output.make (bars)
		end

end
