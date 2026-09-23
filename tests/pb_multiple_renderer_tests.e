class PB_MULTIPLE_RENDERER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_group_preserves_order_and_independent_progress
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_MULTIPLE_RENDERER
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
			second.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
			create output.make (<<first, second>>)
			assert_true ("construction is silent", output.captured.is_empty)
			first.advance
			assert_equal ("ordered initial rows", {STRING_32} "%R[1/2]%/27/[K%N%R[0/3]%/27/[K%N%R", output.captured)
			output.reset
			first.advance
			assert_true ("only first completes", first.has_finished and not second.has_finished and second.absolute_progress = 0)
			assert_equal ("one final group redraw", {STRING_32} "%/27/[2A%R[2/2]%/27/[K%N%R[0/3]%/27/[K%N%R", output.captured)
			output.reset
			second.advance_by (3)
			assert_true ("both complete independently", first.has_finished and second.has_finished)
			assert_true ("finished first row retained", output.captured.has_substring ({STRING_32} "[2/2]"))
			assert_true ("second final row", output.captured.has_substring ({STRING_32} "[3/3]"))
			output.reset
			first.finish
			second.advance
			assert_true ("completed updates are silent", output.captured.is_empty)
		end

	test_group_retains_original_formatters
		local
			first, second: PB_PROGRESS_BAR
			unicode_renderer: PB_UNICODE_PROGRESS_RENDERER
			output: PB_CAPTURE_MULTIPLE_RENDERER
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			first.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
			create unicode_renderer
			second.set_renderer (unicode_renderer)
			create output.make (<<first, second>>)
			first.advance
			assert_equal ("basic formatter kept", {STRING_32} "[1/2]", output.format_line (first))
			assert_equal ("unicode formatter kept", unicode_renderer.format_line (second), output.format_line (second))
			assert_true ("unicode row actually emitted", output.captured.has_substring (unicode_renderer.format_line (second)))
		end

	test_message_above_all_rows
		local
			first, second: PB_PROGRESS_BAR
			output: PB_CAPTURE_MULTIPLE_RENDERER
		do
			create first.make_unknown
			create second.make_with_total (3)
			first.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
			second.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
			create output.make (<<first, second>>)
			first.advance
			output.reset
			second.put_line ("Working")
			assert_equal ("erase block, message, restore rows", {STRING_32} "%/27/[2A%R%/27/[2K%N%R%/27/[2K%N%/27/[2A%RWorking%N%R[1/?]%/27/[K%N%R[0/3]%/27/[K%N%R", output.captured)
			assert_true ("positions unchanged", first.absolute_progress = 1 and second.absolute_progress = 0)
		end

	test_empty_group_rejected
		do
			assert_exception ("at least one bar required", agent create_empty_group)
		end

feature {NONE} -- Contract probes

	create_empty_group
		local
			output: PB_CAPTURE_MULTIPLE_RENDERER
			bars: ARRAY [PB_PROGRESS_BAR]
		do
			create bars.make_empty
			create output.make (bars)
		end

end
