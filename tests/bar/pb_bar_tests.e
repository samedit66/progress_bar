note

	description:

		"Tests for manual progress lifecycle and formatter invocation."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_BAR_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_known_progress
			-- Update and finish progress with a known total.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_with_formatter (
				10,
				agent capture
			)
			assert_true (
				"total known",
				bar.has_total
			)
			assert_true (
				"total",
				bar.total = 10
			)
			bar.update (4)
			assert_true (
				"position",
				bar.position = 4
			)
			assert_true (
				"started",
				bar.is_started
			)
			assert_true (
				"revision",
				bar.revision = 1
			)
			assert_true (
				"snapshot known",
				attached last_progress as progress and then
					progress.has_total
			)
			bar.finish
			assert_true (
				"finished",
				bar.is_finished
			)
			assert_true (
				"final snapshot",
				attached last_progress as progress and then
					progress.is_final
			)
			assert_integers_equal (
				"update and finish callbacks",
				2,
				callback_count
			)
			bar.finish
			assert_integers_equal (
				"second finish is no-op",
				2,
				callback_count
			)
		end

	test_unknown_progress
			-- Update and pulse progress whose total is unknown.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown_with_formatter (agent capture)
			assert_false (
				"total unknown",
				bar.has_total
			)
			bar.update (7)
			bar.pulse
			assert_true (
				"position unchanged by pulse",
				bar.position = 7
			)
			assert_true (
				"revision includes pulse",
				bar.revision = 2
			)
			assert_true (
				"snapshot unknown",
				attached last_progress as progress and then
					not progress.has_total
			)
			bar.finish
			assert_true (
				"unknown final snapshot",
				attached last_progress as progress and then
					progress.is_final
			)
		end

	test_formatter_called_when_text_is_unchanged
			-- Invoke the formatter for every logical refresh request.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown_with_formatter (agent capture_constant)
			bar.update (1)
			bar.update (2)
			bar.pulse
			assert_integers_equal (
				"every request formatted",
				3,
				callback_count
			)
			bar.finish
			assert_integers_equal (
				"finish formatted",
				4,
				callback_count
			)
		end

	test_put_line_preserves_progress
			-- Write messages throughout the lifecycle without changing progress.
		local
			bar: PB_BAR
		do
			reset_capture
			create bar.make_unknown_with_formatter (agent capture)
			bar.put_line ("before")
			assert_false (
				"not started by message",
				bar.is_started
			)
			assert_integers_equal (
				"no callback before start",
				0,
				callback_count
			)
			bar.update (3)
			bar.put_line ("during")
			assert_true (
				"position preserved",
				bar.position = 3
			)
			assert_true (
				"revision preserved",
				bar.revision = 1
			)
			assert_integers_equal (
				"no callback during message",
				1,
				callback_count
			)
			bar.finish
			bar.put_line ("after")
			assert_true (
				"remains finished",
				bar.is_finished
			)
			assert_true (
				"final position preserved",
				bar.position = 3
			)
			assert_true (
				"final revision preserved",
				bar.revision = 1
			)
			assert_integers_equal (
				"no callback after finish",
				2,
				callback_count
			)
		end

	test_make_child_starts_lazy_parent_once
			-- Start a lazy parent once when creating its first child.
		local
			parent, first_child, second_child: PB_BAR
		do
			reset_capture
			create parent.make_with_formatter (
				2,
				agent capture
			)
			create first_child.make_child (
				parent,
				3
			)
			assert_true (
				"parent started",
				parent.is_started
			)
			assert_true (
				"parent position preserved",
				parent.position = 0
			)
			assert_true (
				"parent revision advanced",
				parent.revision = 1
			)
			assert_integers_equal (
				"parent rendered once",
				1,
				callback_count
			)
			assert_true (
				"child shares display",
				first_child.display = parent.display
			)
			assert_true (
				"child total",
				first_child.total = 3
			)
			assert_false (
				"child remains configurable",
				first_child.is_started
			)
			first_child.discard_final_line
			create second_child.make_child (
				parent,
				4
			)
			assert_true (
				"parent revision unchanged",
				parent.revision = 1
			)
			assert_integers_equal (
				"parent not rendered again",
				1,
				callback_count
			)
			first_child.finish
			second_child.finish
			parent.finish
		end

	test_finished_parent_rejects_make_child
			-- Reject child creation after the parent has finished.
		local
			parent: PB_BAR
		do
			create parent.make (1)
			parent.finish
			assert_exception (
				"finished parent",
				agent create_child (parent)
			)
		end

feature {NONE} -- Capture

	last_progress: detachable PB_PROGRESS
			-- Most recent progress passed to a formatter.

	callback_count: INTEGER
			-- Number of formatter invocations.

	reset_capture
			-- Forget previously captured formatter calls.
		do
			last_progress := Void
			callback_count := 0
		end

	capture (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` and return its position.
		do
			last_progress := a_progress
			callback_count :=
				callback_count +
					1
			create Result.make (16)
			Result.append_integer_64 (a_progress.position)
		end

	capture_constant (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` and always return the same line.
		do
			last_progress := a_progress
			callback_count :=
				callback_count +
					1
			Result := "same"
		end

	create_child (a_parent: PB_BAR)
			-- Attempt to create a child of `a_parent`.
		local
			child: PB_BAR
		do
			create child.make_child (
				a_parent,
				1
			)
		end

end
