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
			assert_true ("initial display", output.captured.has_substring ("[                    ] 0%%"))
			assert_true ("render preserves state", bar.absolute_progress = 0 and not bar.has_finished)
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
			assert_true ("message is emitted", output.captured.has_substring ("Hello%N"))
			assert_true ("progress line is restored", output.captured.has_substring ("[########            ] 40%%"))
			assert_true ("message does not advance", bar.absolute_progress = 4 and not bar.has_finished)
			bar.finish
			output.reset
			bar.put_line ("After finish")
			bar.render
			assert_true ("finished renderer is silent", output.captured.is_empty)
		end

	test_standard_renderer_settings
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_STANDARD_PROGRESS_RENDERER
		do
			create bar.make_with_total (4)
			create renderer.make
			renderer.set_width (4)
			renderer.set_fill_character ('=')
			renderer.set_empty_character ('-')
			renderer.set_show_percentage (False)
			bar.set_renderer (renderer)
			bar.advance_by (2)
			assert_true ("configured bar", renderer.format_line (bar).has_substring ("[==--] 2/4"))
		end

	test_renderer_presets_create_independent_renderers
		local
			first, second: PB_STANDARD_PROGRESS_RENDERER
			bar: PB_PROGRESS_BAR
		do
			first := {PB_RENDERER_PRESETS}.squares
			second := {PB_RENDERER_PRESETS}.squares
			assert_true ("fresh preset instances", first /= second)
			create bar.make_with_total (2)
			bar.set_renderer (first)
			bar.advance
			assert_true ("square preset", first.format_line (bar).has_substring ("%/9635/"))
		end

	test_spinner_renderer
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_SPINNER_PROGRESS_RENDERER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Loading")
			create renderer.make
			renderer.set_phases ("ab")
			line := renderer.format_line (bar)
			assert_true ("description and first phase", line.same_string ("Loading a"))
			bar.advance
			line := renderer.format_line (bar)
			assert_true ("next phase", line.same_string ("Loading b"))
			renderer.set_show_count (True)
			renderer.set_show_elapsed (True)
			line := renderer.format_line (bar)
			assert_true ("optional details", line.has_substring ("Loading b 1 00:00:00"))
		end

	test_spinner_presets
		local
			bar: PB_PROGRESS_BAR
			renderer: PB_SPINNER_PROGRESS_RENDERER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Loading")
			create renderer.make
			line := renderer.format_line (bar)
			assert_true ("default moon spinner", line.same_string ("Loading %/9681/"))
			renderer := {PB_RENDERER_PRESETS}.moon_spinner
			line := renderer.format_line (bar)
			assert_true ("moon preset", line.same_string ("Loading %/9681/"))
			renderer := {PB_RENDERER_PRESETS}.spinner
			line := renderer.format_line (bar)
			assert_true ("ascii preset", line.same_string ("Loading -"))
			renderer := {PB_RENDERER_PRESETS}.pie_spinner
			assert_true ("pie preset", renderer.format_line (bar).same_string ("Loading %/9719/"))
			renderer := {PB_RENDERER_PRESETS}.line_spinner
			assert_true ("line preset", renderer.format_line (bar).same_string ("Loading %/9146/"))
			renderer := {PB_RENDERER_PRESETS}.pixel_spinner
			assert_true ("pixel preset", renderer.format_line (bar).same_string ("Loading %/10494/"))
		end

	test_unknown_progress_uses_counter
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_RENDERER
		do
			create bar.make_unknown
			create output.make
			bar.set_renderer (output)
			bar.advance_by (7)
			assert_true ("unknown counter", output.captured.has_substring ("[7/?]"))
			assert_true ("unknown remains open", not bar.has_finished)
		end

end
