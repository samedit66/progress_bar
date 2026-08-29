note

	description:

		"Tests for inclusive integer range progress traversal."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_RANGE_TESTS

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
			create range.make_from_to_with_formatter (
				1,
				100,
				agent capture
			)
			create visited.make (100)
			across
				range
			as
				value
			loop
				visited.extend (value)
			end
			assert_integers_equal (
				"inclusive count",
				100,
				visited.count
			)
			assert_integers_equal (
				"inclusive lower",
				1,
				visited.first
			)
			assert_integers_equal (
				"inclusive upper",
				100,
				visited.last
			)
			assert_true (
				"inclusive final progress",
				attached last_progress as progress and then
					progress.has_total and then
					progress.total = 100 and then
					progress.position = 100 and then
					progress.is_final
			)
		end

	test_single_item_range
			-- Visit one item when both bounds are equal.
		local
			range: PB_RANGE
			visited: INTEGER
		do
			reset_capture
			create range.make_from_to_with_formatter (
				5,
				5,
				agent capture
			)
			across
				range
			as
				value
			loop
				visited := value
			end
			assert_integers_equal (
				"single value",
				5,
				visited
			)
			assert_true (
				"single final progress",
				attached last_progress as progress and then
					progress.total = 1 and then
					progress.position = 1 and then
					progress.is_final
			)
		end

	test_empty_reversed_range
			-- Treat reversed bounds as a known empty range.
		local
			range: PB_RANGE
			body_calls: INTEGER
		do
			reset_capture
			create range.make_from_to_with_formatter (
				5,
				4,
				agent capture
			)
			across
				range
			as
				value
			loop
				body_calls :=
					body_calls +
						value
			end
			assert_integers_equal (
				"empty body",
				0,
				body_calls
			)
			assert_true (
				"empty final progress",
				attached last_progress as progress and then
					progress.has_total and then
					progress.total = 0 and then
					progress.position = 0 and then
					progress.is_complete and then
					progress.is_final
			)
		end

	test_negative_bounds
			-- Preserve order across negative and positive bounds.
		local
			range: PB_RANGE
			visited: ARRAYED_LIST [INTEGER]
		do
			reset_capture
			create range.make_from_to_with_formatter (
				-2,
				2,
				agent capture
			)
			create visited.make (5)
			across
				range
			as
				value
			loop
				visited.extend (value)
			end
			assert_integers_equal (
				"negative count",
				5,
				visited.count
			)
			assert_integers_equal (
				"negative lower",
				-2,
				visited.first
			)
			assert_integers_equal (
				"positive upper",
				2,
				visited.last
			)
		end

	test_polymorphic_repeated_traversal
			-- Use a range as an iterable and give each traversal fresh progress state.
		local
			progress: PB_ITERABLE [INTEGER]
			sum: INTEGER
		do
			reset_capture
			create {PB_RANGE} progress.make_from_to_with_formatter (
				1,
				3,
				agent capture
			)
			across
				progress
			as
				value
			loop
				sum :=
					sum +
						value
			end
			across
				progress
			as
				value
			loop
				sum :=
					sum +
						value
			end
			assert_integers_equal (
				"two range sums",
				12,
				sum
			)
			assert_integers_equal (
				"two initial states",
				2,
				initial_count
			)
			assert_integers_equal (
				"two final states",
				2,
				final_count
			)
		end

	test_small_ranges_at_integer_limits
			-- Calculate small cardinalities without overflowing near integer limits.
		local
			lower_range: PB_RANGE
			upper_range: PB_RANGE
			visited: INTEGER
		do
			reset_capture
			create lower_range.make_from_to_with_formatter (
				{INTEGER}.min_value,
				{INTEGER}.min_value +
					2,
				agent capture
			)
			across
				lower_range
			as
				value
			loop
				visited :=
					visited +
						1
			end
			create upper_range.make_from_to_with_formatter (
				{INTEGER}.max_value -
					2,
				{INTEGER}.max_value,
				agent capture
			)
			across
				upper_range
			as
				value
			loop
				visited :=
					visited +
						1
			end
			assert_integers_equal (
				"limit item count",
				6,
				visited
			)
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
				final_count :=
					final_count +
						1
			elseif a_progress.position = 0 then
				initial_count :=
					initial_count +
						1
			end
			create Result.make (16)
			Result.append_integer_64 (a_progress.position)
		end

end
