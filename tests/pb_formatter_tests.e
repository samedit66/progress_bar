class PB_FORMATTER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Tests

	test_render_without_advancing
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (10)
			create formatter.make
			formatter.set_width (10)
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			create output.make
			output.extend (bar)
			bar.render
			assert_strings_equal ("initial display", "%/27/[2K%/13/[          ] 0%%%N", output.captured.to_string_8)
			assert_strings_equal ("render progress", "0", bar.absolute_progress.out)
			assert_booleans_equal ("render leaves bar open", False, bar.has_finished)
		end

	test_message_restores_progress_line
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			output: PB_CAPTURE_DISPLAY
		do
			create bar.make_with_total (10)
			create formatter.make
			formatter.set_width (10)
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			create output.make
			output.extend (bar)
			bar.advance_by (4)
			output.reset
			bar.put_line ("Hello")
			assert_true ("message is emitted", output.captured.has_substring ("Hello%N"))
			assert_true ("progress line is restored", output.captured.has_substring ("[####      ] 40%%"))
			assert_strings_equal ("message progress", "4", bar.absolute_progress.out)
			assert_booleans_equal ("message leaves bar open", False, bar.has_finished)
			bar.finish
			output.reset
			bar.put_line ("After finish")
			bar.render
			assert_true ("finished display accepts messages", output.captured.has_substring ("After finish%N"))
		end

	test_standard_formatter_settings
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
		do
			create bar.make_with_total (4)
			create formatter.make
			formatter.set_show_phases_for_known (False)
			formatter.set_width (4)
			formatter.set_fill_character ('=')
			formatter.set_empty_character ('-')
			formatter.set_show_percentage (False)
			bar.set_formatter (formatter)
			bar.advance_by (2)
			formatter.set_show_timing (False)
			assert_strings_equal ("configured bar", "[==--] 2/4", formatter.format (bar).to_string_8)
		end

	test_configured_formatter_uses_cells
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
		do
			create bar.make_with_total (2)
			create formatter.make
			formatter.set_width (10)
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			bar.advance
			assert_strings_equal ("configured formatter uses cells", "[#####     ] 50%%", formatter.format (bar).to_string_8)
		end

	test_known_progress_keeps_configured_width
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
		do
			create bar.make_with_total (20)
			create formatter.make
			formatter.set_width (10)
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			bar.advance_by (16)
			assert_strings_equal ("bar width is stable", "[########  ] 80%%", formatter.format (bar).to_string_8)
		end

	test_formatter_presets_create_independent_formatters
		local
			first, second: PB_FORMATTER
			bar: PB_PROGRESS_BAR
		do
			first := {PB_FORMATTER_PRESETS}.squares
			second := {PB_FORMATTER_PRESETS}.squares
			assert_booleans_equal ("fresh preset instances", True, first /= second)
			create bar.make_with_total (2)
			bar.set_formatter (first)
			bar.advance
			assert_true ("square preset", first.format (bar).has_substring ("%/9635/"))
		end

	test_spinner_formatter
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Loading")
			create formatter.make
			formatter.set_phases ("ab")
			formatter.set_show_phases_for_unknown (True)
			formatter.set_show_timing (False)
			line := formatter.format (bar)
			assert_strings_equal ("description and first phase", "Loading a", line.to_string_8)
			bar.advance
			line := formatter.format (bar)
			assert_strings_equal ("next phase", "Loading b", line.to_string_8)
			formatter.set_show_count (True)
			line := formatter.format (bar)
			assert_strings_equal ("optional count", "Loading b 1", line.to_string_8)
		end

	test_spinner_presets
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Loading")
			create formatter.make
			line := formatter.format (bar)
			assert_true ("default formatter uses the default phase", line.has_substring ("Loading -"))
			assert_true ("default formatter includes timing", line.has_substring ("00:00:00"))
			formatter := {PB_FORMATTER_PRESETS}.moon_spinner
			line := formatter.format (bar)
			assert_true ("moon preset", line.same_string ("Loading %/9681/"))
			formatter := {PB_FORMATTER_PRESETS}.spinner
			line := formatter.format (bar)
			assert_true ("ascii preset", line.same_string ("Loading -"))
			formatter := {PB_FORMATTER_PRESETS}.pie_spinner
			assert_true ("pie preset", formatter.format (bar).same_string ("Loading %/9719/"))
			formatter := {PB_FORMATTER_PRESETS}.line_spinner
			assert_true ("line preset", formatter.format (bar).same_string ("Loading %/9146/"))
			formatter := {PB_FORMATTER_PRESETS}.pixel_spinner
			assert_true ("pixel preset", formatter.format (bar).same_string ("Loading %/10494/"))
		end

	test_compact_progress_presets
		local
			unknown_bar, known_bar: PB_PROGRESS_BAR
			counter, countdown: PB_FORMATTER
			stack: PB_FORMATTER
			line: STRING_32
		do
			create unknown_bar.make_unknown
			unknown_bar.set_description ("Processing")
			unknown_bar.advance_by (42)
			counter := {PB_FORMATTER_PRESETS}.counter
			line := counter.format (unknown_bar)
			assert_strings_equal ("counter preset", "Processing 42", line.to_string_8)
			create known_bar.make_with_total (10)
			known_bar.set_description ("Processing")
			known_bar.advance_by (3)
			countdown := {PB_FORMATTER_PRESETS}.countdown
			line := countdown.format (known_bar)
			assert_strings_equal ("countdown preset", "Processing 7 left", line.to_string_8)
			known_bar.set_formatter (countdown)
			known_bar.advance
			line := countdown.format (known_bar)
			assert_strings_equal ("countdown advances", "Processing 6 left", line.to_string_8)
			stack := {PB_FORMATTER_PRESETS}.stack
			line := stack.format (known_bar)
			assert_true ("stack preset", line.has_substring ("Processing %/9603/"))
		end

	test_unknown_progress_uses_counter
		local
			bar: PB_PROGRESS_BAR
			output: PB_CAPTURE_DISPLAY
			formatter: PB_FORMATTER
		do
			create bar.make_unknown
			create output.make
			output.extend (bar)
			create formatter.make
			formatter.set_show_phases_for_unknown (False)
			formatter.set_show_count (True)
			formatter.set_show_timing (False)
			bar.set_formatter (formatter)
			bar.advance_by (7)
			assert_true ("unknown counter", output.captured.has_substring ("7%N"))
			assert_booleans_equal ("unknown remains open", False, bar.has_finished)
		end

	test_unknown_progress_shows_remaining_placeholder
		local
			bar: PB_PROGRESS_BAR
			formatter: PB_FORMATTER
			line: STRING_32
		do
			create bar.make_unknown
			bar.set_description ("Processing")
			create formatter.make
			formatter.set_show_phases_for_unknown (False)
			formatter.set_show_remaining (True)
			formatter.set_show_timing (False)
			line := formatter.format (bar)
			assert_strings_equal ("unknown remaining placeholder", "Processing ? left", line.to_string_8)
		end

end
