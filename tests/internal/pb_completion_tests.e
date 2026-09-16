note

	description:

		"Characterization of subtree completion order and partial formatter failure."


class PB_COMPLETION_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_completion_order_with_closed_and_independent_lines
		local
			display: PB_TEST_DISPLAY
			before, root, left, left_leaf, closed_child, right, right_leaf, after_bar: PB_BAR
			events: STRING_32
		do
			create events.make_empty
			create display.make
			create before.make_with_total (10)
			before.set_display (display)
			create root.make_with_total (10)
			root.set_display (display)
			create left.make_child (root, 10)
			create left_leaf.make_child (left, 10)
			create closed_child.make_child (left, 10)
			create right.make_child (root, 10)
			create right_leaf.make_child (right, 10)
			create after_bar.make_with_total (10)
			after_bar.set_display (display)
			root.set_line_formatter (agent record_final (?, "root", events, False))
			left.set_line_formatter (agent record_final (?, "left", events, False))
			left_leaf.set_line_formatter (agent record_final (?, "left_leaf", events, False))
			closed_child.set_line_formatter (agent record_final (?, "closed", events, False))
			right.set_line_formatter (agent record_final (?, "right", events, False))
			right_leaf.set_line_formatter (agent record_final (?, "right_leaf", events, False))
			closed_child.finish
			events.wipe_out
			root.finish
			assert_true ("reverse display order, descendants before parents", events.same_string ("right_leaf right left_leaf left root "))
			assert_true ("all descendants closed", root.is_finished and left.is_finished and left_leaf.is_finished and right.is_finished and right_leaf.is_finished)
			assert_true ("unrelated lines preserved", not before.is_finished and not after_bar.is_finished)
			before.finish
			after_bar.finish
		end

	test_formatter_failure_preserves_partial_completion
		local
			display: PB_TEST_DISPLAY
			root, first, last: PB_BAR
			events: STRING_32
		do
			create events.make_empty
			create display.make
			create root.make_with_total (10)
			root.set_display (display)
			create first.make_child (root, 10)
			create last.make_child (root, 10)
			root.set_line_formatter (agent record_final (?, "root", events, False))
			first.set_line_formatter (agent record_final (?, "first", events, True))
			last.set_line_formatter (agent record_final (?, "last", events, False))
			first.set_progress (2)
			last.set_progress (3)
			assert_exception ("formatter failure propagates", agent root.finish)
			assert_true ("failure interrupts the existing order", events.same_string ("last first "))
			assert_true ("completed sibling stays closed", last.is_finished and last.progress = 3)
			assert_true ("failed child and parent stay open", not first.is_finished and not root.is_finished and root.has_open_children)
			assert_true ("failed child's progress retained", first.progress = 2)
			first.set_line_formatter (agent record_final (?, "first", events, False))
			events.wipe_out
			root.finish
			assert_true ("retry skips completed sibling", events.same_string ("first root "))
			assert_true ("remaining subtree closes", first.is_finished and root.is_finished)
		end

feature {NONE} -- Capture

	record_final (progress: PB_PROGRESS; a_name: STRING_32; events: STRING_32; fail_on_final: BOOLEAN): STRING_32
			-- Record final callbacks, optionally raising before the line can close.
		local
			failure: DEVELOPER_EXCEPTION
		do
			Result := a_name.twin
			if progress.is_final then
				events.append (a_name)
				events.append_character (' ')
				if fail_on_final then
					create failure
					failure.raise
				end
			end
		end

end
