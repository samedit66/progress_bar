note

	description: "Tests for progress-reporting iterable traversal."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_ITERABLE_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_known_traversal
			-- Preserve order and report the count of a finite source.
		local
			source: ARRAYED_LIST [INTEGER]
			iterable: PB_ITERABLE [INTEGER]
			visited: ARRAYED_LIST [INTEGER]
		do
			reset_capture
			create source.make (3)
			source.extend (4)
			source.extend (5)
			source.extend (6)
			create iterable.make_with_formatter (source, agent capture)
			create visited.make (3)
			across iterable as value loop
				visited.extend (value)
			end
			assert_integers_equal ("all items", 3, visited.count)
			assert_integers_equal ("first", 4, visited.i_th (1))
			assert_integers_equal ("last", 6, visited.i_th (3))
			assert_true ("known final", attached last_progress as progress and then
				progress.has_total and then progress.total = 3 and then
				progress.position = 3 and then progress.is_final)
		end

	test_unknown_traversal
			-- Use unknown progress when the source exposes no FINITE count.
		local
			source: ARRAYED_LIST [INTEGER]
			unknown: PB_UNKNOWN_ITERABLE [INTEGER]
			iterable: PB_ITERABLE [INTEGER]
			sum: INTEGER
		do
			reset_capture
			create source.make (2)
			source.extend (7)
			source.extend (8)
			create unknown.make (source)
			create iterable.make_with_formatter (unknown, agent capture)
			across iterable as value loop
				sum := sum + value
			end
			assert_integers_equal ("items retained", 15, sum)
			assert_true ("unknown final", attached last_progress as progress and then
				not progress.has_total and then progress.position = 2 and then progress.is_final)
		end

	test_empty_traversal
			-- Finish a known zero-sized traversal without entering its body.
		local
			source: ARRAYED_LIST [INTEGER]
			iterable: PB_ITERABLE [INTEGER]
			body_calls: INTEGER
		do
			reset_capture
			create source.make (0)
			create iterable.make_with_formatter (source, agent capture)
			across iterable as value loop
				body_calls := body_calls + value
			end
			assert_integers_equal ("body not entered", 0, body_calls)
			assert_true ("empty complete", attached last_progress as progress and then
				progress.has_total and then progress.total = 0 and then
				progress.is_complete and then progress.is_final)
		end

	test_each_traversal_has_fresh_state
			-- Start every cursor at position zero and finish it independently.
		local
			source: ARRAYED_LIST [INTEGER]
			iterable: PB_ITERABLE [INTEGER]
			ignored: INTEGER
		do
			reset_capture
			create source.make (1)
			source.extend (1)
			create iterable.make_with_formatter (source, agent capture)
			across iterable as value loop
				ignored := ignored + value
			end
			across iterable as value loop
				ignored := ignored + value
			end
			assert_integers_equal ("two final states", 2, final_count)
			assert_integers_equal ("two initial states", 2, initial_count)
		end

feature {NONE} -- Capture

	last_progress: detachable PB_PROGRESS
			-- Most recent formatter argument.

	initial_count: INTEGER
			-- Number of non-final zero-position snapshots.

	final_count: INTEGER
			-- Number of final snapshots.

	reset_capture
			-- Forget captured traversal states.
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
