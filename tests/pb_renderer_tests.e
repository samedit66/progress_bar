class PB_RENDERER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_render_without_advancing
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (10)
			create output.make
			bar.set_renderer (output)
			bar.render
			assert_equal ("initial display", {STRING_32} "%R[0/10]", output.captured)
			assert_true ("render preserves state", bar.absolute_progress = 0 and not bar.has_finished)
		end

	test_shorter_line_erases_previous_tail
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_unknown
			create output.make
			bar.set_renderer (output)
			bar.advance_by (100)
			output.reset
			bar.advance_by (-99)
			assert_equal ("old digits erased", {STRING_32} "%R[1/?]  ", output.captured)
		end

	test_message_restores_progress_line
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_with_total (10)
			create output.make
			bar.set_renderer (output)
			bar.advance_by (4)
			output.reset
			bar.put_line ("Hello")
			assert_equal ("erase, message, restore", {STRING_32} "%R      %RHello%N[4/10]", output.captured)
			assert_true ("message does not advance", bar.absolute_progress = 4 and not bar.has_finished)
			bar.finish
			output.reset
			bar.put_line ("After finish")
			bar.render
			assert_true ("finished renderer is silent", output.captured.is_empty)
		end

	test_message_before_first_render
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_unknown
			create output.make
			bar.set_renderer (output)
			bar.put_line ("Starting")
			assert_equal ("no phantom progress row", {STRING_32} "Starting%N", output.captured)
		end

	test_unicode_fractional_cell
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
			formatter: PB_UNICODE_PROGRESS_RENDERER
			expected: STRING_32
		do
			create bar.make_with_total (160)
			create output.make
			bar.set_renderer (output)
			bar.advance
			create formatter
			create expected.make_filled ('%/9617/', 19)
			expected.prepend_string_general ("[%/9615/")
			expected.append_string_general ("] 0%%")
			assert_equal ("one eighth cell", expected, formatter.format_line (bar))
			bar.advance_by (159)
			create expected.make_filled ('%/9608/', 20)
			expected.prepend_character ('[')
			expected.append_string_general ("] 100%%")
			assert_equal ("full bar", expected, formatter.format_line (bar))
		end

	test_unicode_zero_and_unknown
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_UNICODE_PROGRESS_RENDERER
			expected: STRING_32
		do
			create formatter
			create bar.make_unknown
			assert_equal ("unknown fallback", {STRING_32} "[0/?]", formatter.format_line (bar))
			create bar.make_with_total (0)
			create expected.make_filled ('%/9608/', 20)
			expected.prepend_character ('[')
			expected.append_string_general ("] 100%%")
			assert_equal ("empty total is full", expected, formatter.format_line (bar))
		end

end
