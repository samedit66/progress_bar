note

	description:
		"Tests for built-in progress formatter agents."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_FORMATTERS_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_basic_known
			-- Format a known position using the basic formatter.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
		do
			create formatters
			selected_formatter := formatters.basic
			create bar.make_with_formatter (10, agent capture)
			bar.update (5)
			assert_true ("bar", attached last_text as text and then text.has_substring ("[###############---------------]"))
			assert_true ("percentage", attached last_text as text and then text.has_substring ("50%%"))
			assert_true ("counter", attached last_text as text and then text.has_substring ("5 / 10"))
			bar.finish
		end

	test_unknown_spinner_and_final
			-- Advance a spinner and remove it from the final line.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
		do
			create formatters
			selected_formatter := formatters.basic
			create bar.make_unknown_with_formatter (agent capture)
			bar.update (3)
			assert_true ("first update spinner", attached last_text as text and then text.starts_with ("/"))
			bar.pulse
			assert_true ("pulse spinner", attached last_text as text and then text.starts_with ("-"))
			bar.finish
			assert_true ("final has no spinner", attached last_text as text and then text.same_string ("3"))
		end

	test_standard_copies_affixes
			-- Keep formatter affixes independent from mutable caller strings.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
			label: STRING_32
			unit: STRING_32
			post_label: STRING_32
		do
			create formatters
			label := "Compiling"
			unit := "classes"
			post_label := "ready"
			selected_formatter := formatters.standard (label, unit, post_label)
			label.wipe_out
			unit.wipe_out
			post_label.wipe_out
			create bar.make_with_formatter (4, agent capture)
			bar.update (1)
			assert_true ("copied label", attached last_text as text and then text.starts_with ("Compiling"))
			assert_true ("copied unit", attached last_text as text and then text.has_substring ("classes"))
			assert_true ("copied post label", attached last_text as text and then text.ends_with ("ready"))
			bar.finish
		end

	test_unicode
			-- Use Unicode block characters in the Unicode formatter.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
		do
			create formatters
			selected_formatter := formatters.unicode
			create bar.make_with_formatter (2, agent capture)
			bar.update (1)
			assert_true ("full block", attached last_text as text and then text.has_code (0x2588))
			assert_true ("empty block", attached last_text as text and then text.has_code (0x2591))
			bar.finish
		end

feature {NONE} -- Capture

	selected_formatter: detachable FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Built-in formatter under test.

	last_text: detachable STRING_32
			-- Most recent text returned by `selected_formatter`.

	capture (a_progress: PB_PROGRESS): STRING_32
			-- Apply `selected_formatter` and retain a copy of its result.
		local
			formatted: READABLE_STRING_GENERAL
		do
			check attached selected_formatter as formatter then
				formatted := formatter.item ([a_progress])
				create Result.make_from_string_general (formatted)
				last_text := Result.twin
			end
		end

end

