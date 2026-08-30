note

	description:

		"Tests for coordinated multiline progress display behavior."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_DISPLAY_TESTS

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
			create bar.make_in_with_formatter (
				display,
				1,
				agent position_text
			)
			bar.update (1)
			assert_true (
				"redraw sequence",
				display.captured.same_string ("%Rparent 1")
			)
			display.reset
			bar.finish
			assert_true (
				"finish sequence",
				display.captured.same_string ("%Rparent 1%N")
			)
			assert_false (
				"closed query remains valid",
				bar.has_open_children
			)
		end

	test_child_uses_parent_display
			-- Render a child below its parent and update either line independently.
		local
			display: PB_TEST_DISPLAY
			parent, child: PB_BAR
		do
			create display.make
			create parent.make_in_with_formatter (
				display,
				2,
				agent position_text
			)
			create child.make_child (
				parent,
				1
			)
			child.update (0)
			assert_true (
				"shared display",
				child.display = parent.display
			)
			assert_true (
				"child active",
				parent.has_open_children
			)
			assert_true (
				"both lines repainted",
				display.captured.has_substring ("parent 0%N%R[") and then
					display.captured.has_substring ("0 / 1")
			)
			display.reset
			parent.update (1)
			assert_true (
				"parent update moves up",
				display.captured.has_substring ({STRING_32} "%/27/[1A")
			)
			assert_false (
				"child not reformatted",
				display.captured.has_substring ("0 / 1")
			)
			child.finish
			assert_false (
				"child closed",
				parent.has_open_children
			)
			parent.finish
		end

	test_put_line_repaints_complete_frame
			-- Preserve every active line around a multiline message.
		local
			display: PB_TEST_DISPLAY
			parent, child: PB_BAR
		do
			create display.make
			create parent.make_in_with_formatter (
				display,
				1,
				agent position_text
			)
			create child.make_child (
				parent,
				1
			)
			child.update (0)
			display.reset
			parent.put_line ("first%Nsecond")
			assert_true (
				"message retained",
				display.captured.has_substring ("first%Nsecond")
			)
			assert_true (
				"parent restored",
				display.captured.has_substring ("parent 0")
			)
			assert_true (
				"child restored",
				display.captured.has_substring ("0 / 1")
			)
			child.finish
			parent.finish
		end

	test_discarded_child_is_removed
			-- Remove a child's final row while leaving its parent active.
		local
			display: PB_TEST_DISPLAY
			parent, child: PB_BAR
		do
			create display.make
			create parent.make_in_with_formatter (
				display,
				1,
				agent position_text
			)
			create child.make_child (
				parent,
				1
			)
			child.discard_final_line
			child.update (1)
			display.reset
			child.finish
			assert_false (
				"policy",
				child.keeps_final_line
			)
			assert_true (
				"parent repainted",
				display.captured.has_substring ("parent 0")
			)
			assert_false (
				"child removed",
				display.captured.has_substring ("1 / 1")
			)
			parent.finish
		end

	test_deep_hierarchy_order
			-- Keep grandchildren directly below their ancestors in display order.
		local
			display: PB_TEST_DISPLAY
			parent, child, grandchild: PB_BAR
			parent_index, child_index, grandchild_index: INTEGER
		do
			create display.make
			create parent.make_in_with_formatter (
				display,
				1,
				agent position_text
			)
			create child.make_child (
				parent,
				2
			)
			child.update (0)
			create grandchild.make_child (
				child,
				3
			)
			display.reset
			grandchild.update (0)
			parent_index := display.captured.substring_index (
				"parent 0",
				1
			)
			child_index := display.captured.substring_index (
				"0 / 2",
				parent_index +
					1
			)
			grandchild_index := display.captured.substring_index (
				"0 / 3",
				child_index +
					1
			)
			assert_true (
				"depth-first order",
				parent_index >
					0 and then
					child_index >
						parent_index and then
					grandchild_index >
						child_index
			)
			assert_true (
				"parent sees deep descendant",
				parent.has_open_children
			)
			grandchild.finish
			child.finish
			parent.finish
		end

feature {NONE} -- Formatting

	position_text (a_progress: PB_PROGRESS): STRING_32
			-- Parent line showing position.
		do
			create Result.make (16)
			Result.append_string_general ("parent ")
			Result.append_integer_64 (a_progress.position)
		end

end
