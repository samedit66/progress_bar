note

	description:

		"Tests for built-in progress formatter agents."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_FORMATTERS_TESTS

inherit

	TS_TEST_CASE

	PB_FORMATTERS
		rename
			counter_formatter as progress_counter_formatter
		export
			{NONE} all
		end

create

	make_default

feature -- Test

	test_basic_known
			-- Format a known position using the basic formatter.
		local
			bar: PB_BAR
		do
			selected_formatter := {PB_FORMATTERS}.basic_formatter
			create bar.make_with_total (10)
			bar.set_line_formatter (agent capture)
			bar.set_progress (5)
			assert_true ("bar", attached last_text as text and then text.has_substring ("[###############---------------]"))
			assert_true ("percentage", attached last_text as text and then text.has_substring ("50%%"))
			assert_true ("counter", attached last_text as text and then text.has_substring ("5 / 10"))
			bar.finish
		end

	test_unknown_spinner_and_final
			-- Advance a spinner and remove it from the final line.
		local
			bar: PB_BAR
		do
			selected_formatter := {PB_FORMATTERS}.basic_formatter
			create bar.make_unknown
			bar.set_line_formatter (agent capture)
			bar.set_progress (3)
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
			label: STRING_32
			unit: STRING_32
			post_label: STRING_32
		do
			label := "Compiling"
			unit := "classes"
			post_label := "ready"
			selected_formatter := {PB_FORMATTERS}.standard_formatter (label, unit, post_label)
			label.wipe_out
			unit.wipe_out
			post_label.wipe_out
			create bar.make_with_total (4)
			bar.set_line_formatter (agent capture)
			bar.set_progress (1)
			assert_true ("copied label", attached last_text as text and then text.starts_with ("Compiling"))
			assert_true ("copied unit", attached last_text as text and then text.has_substring ("classes"))
			assert_true ("copied post label", attached last_text as text and then text.ends_with ("ready"))
			bar.finish
		end

	test_unicode
			-- Use Unicode block characters in the Unicode formatter.
		local
			bar: PB_BAR
		do
			selected_formatter := {PB_FORMATTERS}.unicode_formatter
			create bar.make_with_total (2)
			bar.set_line_formatter (agent capture)
			bar.set_progress (1)
			assert_true ("full block", attached last_text as text and then text.has_code (0x2588))
			assert_true ("empty block", attached last_text as text and then text.has_code (0x2591))
			bar.finish
		end

	test_inherited_formatters
			-- Inherited and qualified factories agree without importing helper names.
		local
			known, unknown, final_progress: PB_PROGRESS
		do
			known := captured_snapshot (5, 10, False)
			unknown := captured_snapshot (5, -1, False)
			final_progress := captured_snapshot (5, -1, True)
			across
				<<known, unknown, final_progress>>
			as
				snapshot
			loop
				assert_same_text ("basic", {PB_FORMATTERS}.basic_formatter.item ([snapshot]), basic_formatter.item ([snapshot]))
				assert_same_text ("unicode", {PB_FORMATTERS}.unicode_formatter.item ([snapshot]), unicode_formatter.item ([snapshot]))
				assert_same_text ("compact", {PB_FORMATTERS}.compact_formatter.item ([snapshot]), compact_formatter.item ([snapshot]))
				assert_same_text ("counter", {PB_FORMATTERS}.counter_formatter.item ([snapshot]), progress_counter_formatter.item ([snapshot]))
				assert_same_text ("minimal", {PB_FORMATTERS}.minimal_formatter.item ([snapshot]), minimal_formatter.item ([snapshot]))
				assert_same_text ("standard", {PB_FORMATTERS}.standard_formatter ("Files", "files", "done").item ([snapshot]), standard_formatter ("Files", "files", "done").item ([snapshot]))
			end
		end

	test_short_formats
			-- Preserve exact compact, counter, and minimal output at lifecycle boundaries.
		local
			progress: PB_PROGRESS
		do
			progress := captured_snapshot (5, 10, False)
			assert_same_text ("compact known", "50%%  5 / 10", compact_formatter.item ([progress]))
			assert_same_text ("counter known", "5 / 10", progress_counter_formatter.item ([progress]))
			assert_same_text ("minimal known", "50%%", minimal_formatter.item ([progress]))
			progress := captured_snapshot (5, -1, False)
			assert_same_text ("compact unknown", "/  5", compact_formatter.item ([progress]))
			assert_same_text ("counter unknown", "5", progress_counter_formatter.item ([progress]))
			assert_same_text ("minimal unknown", "/", minimal_formatter.item ([progress]))
			progress := captured_snapshot (5, -1, True)
			assert_same_text ("compact final", "5", compact_formatter.item ([progress]))
			assert_same_text ("counter final", "5", progress_counter_formatter.item ([progress]))
			assert_same_text ("minimal final", "5", minimal_formatter.item ([progress]))
		end

	test_configurations_are_independent
			-- Each factory call owns its affixes; rendering does not reuse output buffers.
		local
			first, second: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			progress: PB_PROGRESS
			first_text: READABLE_STRING_GENERAL
		do
			first := standard_formatter ("First", "items", "done")
			second := {PB_FORMATTERS}.standard_formatter ("Second", "files", "stopped")
			progress := captured_snapshot (5, -1, True)
			first_text := first.item ([progress])
			assert_same_text ("first configuration", "First  5 items  done", first_text)
			assert_same_text ("second configuration", "Second  5 files  stopped", second.item ([progress]))
			progress := captured_snapshot (6, -1, True)
			assert_same_text ("next output", "First  6 items  done", first.item ([progress]))
			assert_same_text ("previous output preserved", "First  5 items  done", first_text)
		end

feature {NONE} -- Inheritance checks

	counter: INTEGER = 7
			-- Application name that used to collide with a formatter factory.

	append_counter: INTEGER = 9
			-- Application name that used to collide with a hidden formatting helper.

	assert_same_text (a_tag: STRING; a_expected, a_actual: READABLE_STRING_GENERAL)
			-- Assert equal text across string representations.
		do
			assert_true (a_tag, a_expected.same_string (a_actual))
		end

feature {NONE} -- Snapshot capture

	last_snapshot: detachable PB_PROGRESS
			-- Snapshot received through the public bar API.

	captured_snapshot (a_position, a_total: INTEGER_64; a_final: BOOLEAN): PB_PROGRESS
			-- Snapshot from a fresh bar; negative total means unknown progress.
		local
			bar: PB_BAR
		do
			last_snapshot := Void
			if a_total < 0 then
				create bar.make_unknown
			else
				create bar.make_with_total (a_total)
			end
			bar.set_line_formatter (agent capture_snapshot)
			bar.set_progress (a_position)
			if a_final then
				bar.finish
			end
			check
				attached last_snapshot as snapshot
			then
				Result := snapshot
			end
			bar.finish
		end

	capture_snapshot (a_progress: PB_PROGRESS): STRING
			-- Retain the snapshot without rendering a progress label.
		do
			last_snapshot := a_progress
			Result := ""
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
			check
				attached selected_formatter as formatter
			then
				formatted := formatter.item ([a_progress])
				create Result.make_from_string_general (formatted)
				last_text := Result.twin
			end
		end

end
