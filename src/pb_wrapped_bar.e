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
			-- Wrap a progress bar around `a_iterable`.
			-- Finite iterables create a known-total bar; other iterables create an
			-- unknown-total bar that must be finished explicitly after traversal.
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
			-- Create a cursor that advances this bar with each `forth` call.
		do
			create Result.make (original_iterable, Current)
		end

feature {NONE} -- Implementation

	original_iterable: ITERABLE [G]

end
