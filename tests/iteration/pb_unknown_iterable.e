note

	description:

		"Test iterable that deliberately does not conform to FINITE."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_UNKNOWN_ITERABLE [G]

inherit

	ITERABLE [G]

create

	make

feature {NONE} -- Initialization

	make (a_source: ITERABLE [G])
			-- Wrap `a_source` without exposing a count.
		do
			source := a_source
		end

feature -- Access

	new_cursor: ITERATION_CURSOR [G]
			-- Fresh cursor from `source`.
		do
			Result := source.new_cursor
		end

feature {NONE} -- Implementation

	source: ITERABLE [G]
			-- Wrapped iterable.

end
