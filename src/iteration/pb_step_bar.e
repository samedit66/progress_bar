note

	description:

		"Progress over numbered steps from one through a known total."


class PB_STEP_BAR

inherit

	PB_ITERABLE [INTEGER]

create

	make_with_total

feature {NONE} -- Initialization

	make_with_total (a_total: INTEGER)
			-- Create lazy, repeatable traversal of steps `1 .. a_total`.
		require
			total_non_negative: a_total >= 0
		local
			steps: INTEGER_INTERVAL
		do
			create steps.make (1, a_total)
			make_over (steps)
		end

end
