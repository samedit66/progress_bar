note

	description:

		"Tests for progress-reporting iterable traversal."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_ITERABLE_TESTS

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
			create iterable.make_with_formatter (
				source,
				agent capture
			)
			create visited.make (3)
			across
				iterable
			as
				value
			loop
				visited.extend (value)
			end
			assert_integers_equal (
				"all items",
				3,
				visited.count
			)
			assert_integers_equal (
				"first",
				4,
				visited.i_th (1)
			)
			assert_integers_equal (
				"last",
				6,
				visited.i_th (3)
			)
			assert_true (
				"known final",
				attached last_progress as progress and then
					progress.has_total and then
					progress.total = 3 and then
					progress.position = 3 and then
					progress.is_final
			)
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
			create iterable.make_with_formatter (
				unknown,
				agent capture
			)
			across
				iterable
			as
				value
			loop
				sum :=
					sum +
						value
			end
			assert_integers_equal (
				"items retained",
				15,
				sum
			)
			assert_true (
				"unknown final",
				attached last_progress as progress and then
					not progress.has_total and then
					progress.position = 2 and then
					progress.is_final
			)
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
			create iterable.make_with_formatter (
				source,
				agent capture
			)
			across
				iterable
			as
				value
			loop
				body_calls :=
					body_calls +
						value
			end
			assert_integers_equal (
				"body not entered",
				0,
				body_calls
			)
			assert_true (
				"empty complete",
				attached last_progress as progress and then
					progress.has_total and then
					progress.total = 0 and then
					progress.is_complete and then
					progress.is_final
			)
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
			create iterable.make_with_formatter (
				source,
				agent capture
			)
			across
				iterable
			as
				value
			loop
				ignored :=
					ignored +
						value
				iterable.put_line ("first traversal")
			end
			across
				iterable
			as
				value
			loop
				ignored :=
					ignored +
						value
				iterable.put_line ("second traversal")
			end
			assert_integers_equal (
				"two final states",
				2,
				final_count
			)
			assert_integers_equal (
				"two initial states",
				2,
				initial_count
			)
		end

	test_interleaved_traversals_share_display
			-- Keep independent traversal lines stable while cursors advance out of order.
		local
			display: PB_TEST_DISPLAY
			first_source, second_source: ARRAYED_LIST [INTEGER]
			first_iterable, second_iterable: PB_ITERABLE [INTEGER]
			first_cursor, second_cursor: ITERATION_CURSOR [INTEGER]
		do
			create display.make
			create first_source.make (1)
			first_source.extend (1)
			create second_source.make (1)
			second_source.extend (2)
			create first_iterable.make_in_with_formatter (
				display,
				first_source,
				agent first_text
			)
			create second_iterable.make_in_with_formatter (
				display,
				second_source,
				agent second_text
			)
			first_cursor := first_iterable.new_cursor
			second_cursor := second_iterable.new_cursor
			display.reset
			first_cursor.forth
			assert_true (
				"first final retained",
				display.captured.has_substring ("first 1")
			)
			assert_true (
				"second still visible",
				display.captured.has_substring ("second 0")
			)
			second_cursor.forth
			assert_true (
				"both exhausted",
				first_cursor.after and then
					second_cursor.after
			)
		end

	test_line_policy_is_copied_to_new_cursor
			-- Changing iterable policy affects only cursors created afterwards.
		local
			display: PB_TEST_DISPLAY
			source: ARRAYED_LIST [INTEGER]
			iterable: PB_ITERABLE [INTEGER]
			kept_cursor, discarded_cursor: ITERATION_CURSOR [INTEGER]
		do
			create display.make
			create source.make (1)
			source.extend (1)
			create iterable.make_in_with_formatter (
				display,
				source,
				agent first_text
			)
			kept_cursor := iterable.new_cursor
			iterable.discard_final_line
			display.reset
			kept_cursor.forth
			assert_true (
				"existing cursor keeps policy",
				display.captured.ends_with ("%N")
			)
			discarded_cursor := iterable.new_cursor
			display.reset
			discarded_cursor.forth
			assert_false (
				"future cursor discards line",
				display.captured.ends_with ("%N")
			)
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

	first_text (a_progress: PB_PROGRESS): STRING_32
			-- First traversal label.
		do
			create Result.make (16)
			Result.append_string_general ("first ")
			Result.append_integer_64 (a_progress.position)
		end

	second_text (a_progress: PB_PROGRESS): STRING_32
			-- Second traversal label.
		do
			create Result.make (16)
			Result.append_string_general ("second ")
			Result.append_integer_64 (a_progress.position)
		end

end
