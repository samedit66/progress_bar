note

	description:

		"Tests for inclusive integer steps progress traversal."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_STEP_BAR_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_inclusive_steps
			-- Visit both bounds and report the inclusive item count.
		local
			steps: PB_STEP_BAR
			visited: ARRAYED_LIST [INTEGER]
		do
			reset_capture
			create steps.make_with_total (100)
			steps.set_line_formatter (agent capture)
			create visited.make (100)
			across
				steps
			as
				value
			loop
				visited.extend (value)
			end
			assert_integers_equal ("inclusive count", 100, visited.count)
			assert_integers_equal ("inclusive lower", 1, visited.first)
			assert_integers_equal ("inclusive upper", 100, visited.last)
			assert_true ("inclusive final progress", attached last_progress as progress and then progress.has_total and then progress.total = 100 and then progress.position = 100 and then progress.is_final)
		end

	test_single_item_steps
			-- Visit one item when both bounds are equal.
		local
			steps: PB_STEP_BAR
			visited: INTEGER
		do
			reset_capture
			create steps.make_with_total (1)
			steps.set_line_formatter (agent capture)
			across
				steps
			as
				value
			loop
				visited := value
			end
			assert_integers_equal ("single value", 1, visited)
			assert_true ("single final progress", attached last_progress as progress and then progress.total = 1 and then progress.position = 1 and then progress.is_final)
		end

	test_empty_reversed_steps
			-- Treat reversed bounds as a known empty steps.
		local
			steps: PB_STEP_BAR
			body_calls: INTEGER
		do
			reset_capture
			create steps.make_with_total (0)
			steps.set_line_formatter (agent capture)
			across
				steps
			as
				value
			loop
				body_calls := body_calls + value
			end
			assert_integers_equal ("empty body", 0, body_calls)
			assert_true ("empty traversal is silent", last_progress = Void)
		end

	test_polymorphic_repeated_traversal
			-- Use a steps as an iterable and give each traversal fresh progress state.
		local
			progress: PB_ITERABLE [INTEGER]
			sum: INTEGER
		do
			reset_capture
			create {PB_STEP_BAR} progress.make_with_total (3)
			progress.set_line_formatter (agent capture)
			across
				progress
			as
				value
			loop
				sum := sum + value
			end
			across
				progress
			as
				value
			loop
				sum := sum + value
			end
			assert_integers_equal ("two steps sums", 12, sum)
			assert_integers_equal ("two initial states", 2, initial_count)
			assert_integers_equal ("two final states", 2, final_count)
		end

	test_large_total_is_lazy
			-- A large step count does not allocate a collection of that size.
		local
			steps: PB_STEP_BAR
			display: PB_TEST_DISPLAY
		do
			create steps.make_with_total ({INTEGER}.max_value)
			create display.make
			steps.set_display (display)
			assert_true ("construction silent", display.captured.is_empty)
		end

	test_put_line_during_steps
			-- Write a message while preserving inherited steps traversal.
		local
			steps: PB_STEP_BAR
			sum: INTEGER
		do
			reset_capture
			create steps.make_with_total (2)
			steps.set_line_formatter (agent capture)
			across
				steps
			as
				value
			loop
				sum := sum + value
				steps.put_line ("steps item")
			end
			assert_integers_equal ("steps sum", 3, sum)
			assert_true ("steps final progress", attached last_progress as progress and then progress.position = 2 and then progress.is_final)
		end

	test_steps_uses_supplied_display
			-- Coordinate steps progress with other lines through a supplied display.
		local
			display: PB_TEST_DISPLAY
			steps: PB_STEP_BAR
		do
			create display.make
			create steps.make_with_total (2)
			steps.set_display (display)
			steps.set_line_formatter (agent capture)
			assert_true ("display retained", steps.display = display)
		end

feature {NONE} -- Capture

	last_progress: detachable PB_PROGRESS
			-- Most recent progress passed to `capture`.

	initial_count: INTEGER
			-- Number of non-final zero-position snapshots.

	final_count: INTEGER
			-- Number of final snapshots.

	reset_capture
			-- Forget captured steps traversal states.
		do
			last_progress := Void
			initial_count := 0
			final_count := 0
		end

	capture (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` and return a stable test line.
		do
			last_progress := a_progress
			if a_progress.is_final then
				final_count := final_count + 1
			elseif a_progress.position = 0 then
				initial_count := initial_count + 1
			end
			create Result.make (16)
			Result.append_integer_64 (a_progress.position)
		end

end
