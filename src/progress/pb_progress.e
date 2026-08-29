note

	description:
		"Immutable snapshot supplied to a progress formatter."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

frozen class PB_PROGRESS

create {PB_BAR}

	make_known,
	make_unknown

feature {NONE} -- Initialization

	make_known (a_current, a_total, a_revision: INTEGER_64; a_is_final: BOOLEAN)
			-- Create a snapshot with known `a_total`.
		require
			current_non_negative: a_current >= 0
			total_non_negative: a_total >= 0
			revision_non_negative: a_revision >= 0
		do
			position := a_current
			stored_total := a_total
			revision := a_revision
			is_final := a_is_final
			has_total := True
		ensure
			position_set: position = a_current
			total_set: total = a_total
			revision_set: revision = a_revision
			final_set: is_final = a_is_final
			total_known: has_total
		end

	make_unknown (a_current, a_revision: INTEGER_64; a_is_final: BOOLEAN)
			-- Create a snapshot whose total is unknown.
		require
			current_non_negative: a_current >= 0
			revision_non_negative: a_revision >= 0
		do
			position := a_current
			revision := a_revision
			is_final := a_is_final
		ensure
			position_set: position = a_current
			revision_set: revision = a_revision
			final_set: is_final = a_is_final
			total_unknown: not has_total
		end

feature -- Access

	position: INTEGER_64
			-- Current absolute position.

	total: INTEGER_64
			-- Expected total.
		require
			total_known: has_total
		do
			Result := stored_total
		ensure
			non_negative: Result >= 0
		end

	revision: INTEGER_64
			-- Number of update or pulse requests represented by Current.

	fraction: REAL_64
			-- Completion fraction limited to the range 0.0 through 1.0.
		require
			total_known: has_total
		do
			if stored_total = 0 or else position >= stored_total then
				Result := 1.0
			else
				Result := position.to_double / stored_total.to_double
			end
		ensure
			not_negative: Result >= 0.0
			not_greater_than_one: Result <= 1.0
			empty_is_complete: stored_total = 0 implies Result = 1.0
		end

	percentage: INTEGER
			-- Whole completion percentage limited to 0 through 100.
		require
			total_known: has_total
		do
			Result := (fraction * 100.0).truncated_to_integer
		ensure
			not_negative: Result >= 0
			not_greater_than_one_hundred: Result <= 100
		end

feature -- Status report

	has_total: BOOLEAN
			-- Is the expected total known?

	is_complete: BOOLEAN
			-- Has Current reached or exceeded its known total?
		do
			Result := has_total and then position >= stored_total
		ensure
			definition: Result = (has_total and then position >= stored_total)
		end

	is_final: BOOLEAN
			-- Is Current the final snapshot of its progress line?

feature {NONE} -- Implementation

	stored_total: INTEGER_64
			-- Expected total when `has_total`.

invariant

	position_non_negative: position >= 0
	revision_non_negative: revision >= 0
	stored_total_non_negative: stored_total >= 0

end
