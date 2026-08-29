note

	description:
		"Tests for progress snapshot calculations."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_PROGRESS_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_known_fraction
			-- Calculate fraction and percentage for ordinary and overflowing progress.
		local
			bar: PB_BAR
		do
			create bar.make_with_formatter (8, agent capture)
			bar.update (2)
			assert_true ("snapshot captured", attached last_progress as progress and then progress.fraction = 0.25)
			assert_true ("percentage", attached last_progress as progress and then progress.percentage = 25)
			bar.update (12)
			assert_true ("fraction clipped", attached last_progress as progress and then progress.fraction = 1.0)
			assert_true ("complete", attached last_progress as progress and then progress.is_complete)
			bar.finish
		end

	test_known_empty_total
			-- Treat a known total of zero as already complete.
		local
			bar: PB_BAR
		do
			create bar.make_with_formatter (0, agent capture)
			bar.update (0)
			assert_true ("empty fraction", attached last_progress as progress and then progress.fraction = 1.0)
			assert_true ("empty percentage", attached last_progress as progress and then progress.percentage = 100)
			assert_true ("empty complete", attached last_progress as progress and then progress.is_complete)
			bar.finish
		end

	test_unknown_snapshot
			-- Preserve unknown total independently of its stored numeric representation.
		local
			bar: PB_BAR
		do
			create bar.make_unknown_with_formatter (agent capture)
			bar.update (0)
			assert_true ("unknown captured", attached last_progress as progress and then not progress.has_total)
			assert_true ("unknown not complete", attached last_progress as progress and then not progress.is_complete)
			bar.finish
		end

feature {NONE} -- Capture

	last_progress: detachable PB_PROGRESS
			-- Most recent progress passed to `capture`.

	capture (a_progress: PB_PROGRESS): STRING_32
			-- Capture `a_progress` for inspection.
		do
			last_progress := a_progress
			Result := "progress"
		end

end

