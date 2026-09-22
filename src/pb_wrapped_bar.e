class PB_WRAPPED_BAR [G]
	-- A bar wrapped around some iterable.

inherit

	ITERABLE [G]

	PB_PROGRESS_BAR
		export
			{NONE}
				advance,
				advance_by,
				finish
		end

create

	wrap

feature {NONE}

	wrap (a_iterable: ITERABLE [G])
			-- Wraps a progress bar around the given iterable.
			-- Automatically finds out whether the given `a_iterable` is a descendant of `FINITE`,
			-- and if it is, creates a bar with a known total.
		do
			original_iterable := a_iterable
			make_with_total (guess_count (a_iterable))
		end

feature -- Access

	new_cursor: PB_ITERATION_CURSOR [G]
		do
			create Result.make (original_iterable, Current)
		end

feature {NONE} -- Implementation

	original_iterable: ITERABLE [G]

	guess_count (a_iterable: ITERABLE [G]): INTEGER_32
		do
			if attached {FINITE [G]} a_iterable as finite then
				Result := finite.count
			else
				Result := -1
			end
		ensure
			meaningful_count: Result >= -1
		end

end
