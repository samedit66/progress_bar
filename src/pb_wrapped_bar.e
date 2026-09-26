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
			if attached {FINITE [G]} a_iterable as finite then
				make_with_total (finite.count)
			else
				make_unknown
			end
		end

feature -- Access

	new_cursor: PB_ITERATION_CURSOR [G]
		do
			create Result.make (original_iterable, Current)
		end

feature {NONE} -- Implementation

	original_iterable: ITERABLE [G]

end
