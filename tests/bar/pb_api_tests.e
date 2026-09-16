note

	description:

		"Lifecycle, shared-display, and nested traversal contracts for the public API."


class PB_API_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Manual lifecycle

	test_start_and_forth
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_with_total (2)
			bar.set_display (display)
			assert_true ("construction has no row", display.registered_line_count = 0 and display.captured.is_empty)
			bar.start
			assert_true ("start renders zero", bar.progress = 0 and display.registered_line_count = 1)
			display.reset
			bar.start
			assert_true ("repeat start is silent", display.captured.is_empty)
			bar.forth
			assert_true ("one completed step", bar.progress = 1 and not bar.is_finished)
			bar.forth
			assert_true ("last step closes", bar.progress = 2 and bar.is_finished)
			display.reset
			bar.start
			bar.forth
			bar.finish
			assert_true ("never reopens", display.captured.is_empty and bar.progress = 2)
		end

	test_display_changes_before_start_only
		local
			bar: PB_BAR
			first, second: PB_TEST_DISPLAY
		do
			create first.make
			create second.make
			create bar.make_unknown
			bar.set_display (first)
			bar.set_display (second)
			bar.start
			assert_true ("old display remains unused", first.captured.is_empty and first.registered_line_count = 0)
			assert_true ("new display owns row", bar.display = second and second.registered_line_count = 1)
			assert_exception ("cannot move active row", agent bar.set_display (first))
			bar.finish
			assert_exception ("cannot move finished row", agent bar.set_display (first))
		end

	test_shared_display_does_not_imply_parenthood
		local
			first, second, idle: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create first.make_unknown
			first.set_display (display)
			create second.make_unknown
			second.set_display (first.display)
			create idle.make_unknown
			idle.set_display (first.display)
			first.start
			second.start
			assert_true ("automatic retention", first.keeps_final_line and not second.keeps_final_line)
			first.finish
			assert_false ("second remains independent", second.is_finished)
			second.forth
			second.finish
			assert_true ("unstarted bar does not keep display busy", display.registered_line_count = 0)
			assert_true ("idle bar still usable", not idle.is_started and not idle.is_finished)
			idle.forth
			assert_true ("next operation keeps its result", idle.keeps_final_line)
			idle.finish
		end

	test_zero_total_can_share_display
		local
			bar: PB_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create bar.make_with_total (0)
			bar.set_display (display)
			bar.start
			bar.forth
			assert_true ("empty stays silent", bar.is_finished and bar.display = display and display.registered_line_count = 0 and display.captured.is_empty)
		end

feature -- Automatic traversal

	test_nested_steps_release_inner_rows
		local
			outer_steps, inner_steps: PB_STEP_BAR
			display: PB_TEST_DISPLAY
			visited: INTEGER
		do
			create display.make
			create outer_steps.make_with_total (3)
			outer_steps.set_display (display)
			outer_steps.set_line_formatter (agent outer_text)
			create inner_steps.make_with_total (2)
			inner_steps.set_display (outer_steps.display)
			inner_steps.set_line_formatter (agent inner_text)
			across
				outer_steps
			as
				outer_step
			loop
				assert_true ("only outer row before inner loop", display.registered_line_count = 1)
				across
					inner_steps
				as
					inner_step
				loop
					assert_true ("two coordinated rows", display.registered_line_count = 2)
					assert_true ("inner starts from one", inner_step >= 1 and inner_step <= 2)
					visited := visited + 1
					display.reset
				end
				assert_true ("inner row released", display.registered_line_count = 1)
				assert_false ("inner final text discarded", display.captured.has_substring ("inner 2"))
				assert_true ("outer body not yet counted", display.captured.has_substring ("outer " + (outer_step - 1).out))
				display.reset
			end
			assert_integers_equal ("all work performed", 6, visited)
			assert_true ("only outer final retained", display.captured.same_string ("%Router 3%N"))
			assert_true ("display idle", display.registered_line_count = 0)
		end

	test_iterable_display_is_copied_per_cursor
		local
			steps: PB_STEP_BAR
			first, second: PB_TEST_DISPLAY
			old_cursor, new_cursor: ITERATION_CURSOR [INTEGER]
		do
			create first.make
			create second.make
			create steps.make_with_total (1)
			steps.set_display (first)
			old_cursor := steps.new_cursor
			steps.set_display (second)
			new_cursor := steps.new_cursor
			first.reset
			second.reset
			old_cursor.forth
			assert_true ("old cursor retains display", not first.captured.is_empty and second.captured.is_empty)
			first.reset
			new_cursor.forth
			assert_true ("future cursor uses new display", first.captured.is_empty and not second.captured.is_empty)
		end

	test_explicit_keep_preserves_inner_result
		local
			outer_bar: PB_BAR
			inner_steps: PB_STEP_BAR
			display: PB_TEST_DISPLAY
		do
			create display.make
			create outer_bar.make_unknown
			outer_bar.set_display (display)
			outer_bar.start
			create inner_steps.make_with_total (1)
			inner_steps.set_display (outer_bar.display)
			inner_steps.keep_final_line
			inner_steps.set_line_formatter (agent inner_text)
			across
				inner_steps
			as
				step
			loop
				display.reset
			end
			assert_true ("retained result", display.registered_line_count = 2 and display.captured.has_substring ("inner 1"))
			outer_bar.finish
		end

feature {NONE} -- Formatting

	outer_text (p: PB_PROGRESS): STRING_32
		do
			Result := {STRING_32} "outer " + p.position.out
		end

	inner_text (p: PB_PROGRESS): STRING_32
		do
			Result := {STRING_32} "inner " + p.position.out
		end

end
