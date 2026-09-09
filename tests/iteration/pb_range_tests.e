note

	description:

		"Tests for inclusive integer range progress traversal."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_RANGE_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_inclusive_range
			-- Visit both bounds and report the inclusive item count.
		local
			range: PB_RANGE
			visited: ARRAYED_LIST [INTEGER]
		do
			reset_capture
			create range.make_from_to (1, 100)
			range.set_formatter (agent capture)
			create visited.make (100)
			across
				range
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

	test_single_item_range
			-- Visit one item when both bounds are equal.
		local
			range: PB_RANGE
			visited: INTEGER
		do
			reset_capture
			create range.make_from_to (5, 5)
			range.set_formatter (agent capture)
			across
				range
			as
				value
			loop
				visited := value
			end
			assert_integers_equal ("single value", 5, visited)
			assert_true ("single final progress", attached last_progress as progress and then progress.total = 1 and then progress.position = 1 and then progress.is_final)
		end

	test_empty_reversed_range
			-- Treat reversed bounds as a known empty range.
		local
			range: PB_RANGE
			body_calls: INTEGER
		do
			reset_capture
			create range.make_from_to (5, 4)
			range.set_formatter (agent capture)
			across
				range
			as
				value
			loop
				body_calls := body_calls + value
			end
			assert_integers_equal ("empty body", 0, body_calls)
			assert_true ("empty traversal is silent", last_progress = Void)
		end

	test_negative_bounds
			-- Preserve order across negative and positive bounds.
		local
			range: PB_RANGE
			visited: ARRAYED_LIST [INTEGER]
		do
			reset_capture
			create range.make_from_to (-2, 2)
			range.set_formatter (agent capture)
			create visited.make (5)
			across
				range
			as
				value
			loop
				visited.extend (value)
			end
			assert_integers_equal ("negative count", 5, visited.count)
			assert_integers_equal ("negative lower", -2, visited.first)
			assert_integers_equal ("positive upper", 2, visited.last)
		end

	test_polymorphic_repeated_traversal
			-- Use a range as an iterable and give each traversal fresh progress state.
		local
			progress: PB_ITERABLE [INTEGER]
			sum: INTEGER
		do
			reset_capture
			create {PB_RANGE} progress.make_from_to (1, 3)
			progress.set_formatter (agent capture)
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
			assert_integers_equal ("two range sums", 12, sum)
			assert_integers_equal ("two initial states", 2, initial_count)
			assert_integers_equal ("two final states", 2, final_count)
		end

	test_small_ranges_at_integer_limits
			-- Calculate small cardinalities without overflowing near integer limits.
		local
			lower_range: PB_RANGE
			upper_range: PB_RANGE
			visited: INTEGER
		do
			reset_capture
			create lower_range.make_from_to ({INTEGER}.min_value, {INTEGER}.min_value + 2)
			lower_range.set_formatter (agent capture)
			across
				lower_range
			as
				value
			loop
				visited := visited + 1
			end
			create upper_range.make_from_to ({INTEGER}.max_value - 2, {INTEGER}.max_value)
			upper_range.set_formatter (agent capture)
			across
				upper_range
			as
				value
			loop
				visited := visited + 1
			end
			assert_integers_equal ("limit item count", 6, visited)
		end

	test_put_line_during_range
			-- Write a message while preserving inherited range traversal.
		local
			range: PB_RANGE
			sum: INTEGER
		do
			reset_capture
			create range.make_from_to (1, 2)
			range.set_formatter (agent capture)
			across
				range
			as
				value
			loop
				sum := sum + value
				range.put_line ("range item")
			end
			assert_integers_equal ("range sum", 3, sum)
			assert_true ("range final progress", attached last_progress as progress and then progress.position = 2 and then progress.is_final)
		end

	test_range_uses_supplied_display
			-- Coordinate range progress with other lines through a supplied display.
		local
			display: PB_TEST_DISPLAY
			range: PB_RANGE
		do
			create display.make
			create range.make_from_to_in (1, 2, display)
			range.set_formatter (agent capture)
			assert_true ("display retained", range.display = display)
		end

feature {NONE} -- Capture

	last_progress: detachable PB_PROGRESS
			-- Most recent progress passed to `capture`.

	initial_count: INTEGER
			-- Number of non-final zero-position snapshots.

	final_count: INTEGER
			-- Number of final snapshots.

	reset_capture
			-- Forget captured range traversal states.
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
