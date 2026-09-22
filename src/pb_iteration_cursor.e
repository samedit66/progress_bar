class PB_ITERATION_CURSOR [G]

inherit

	ITERATION_CURSOR [G]

create

	make

feature {NONE} -- Initialization

	make (a_iterable: ITERABLE [G]; a_bar: PB_PROGRESS_BAR)
		do
			original_cursor := a_iterable.new_cursor
			bar := a_bar
		end

feature -- Access

	item: G
		do
			Result := original_cursor.item
		end

feature -- Status report

	after: BOOLEAN
		do
			Result := original_cursor.after
		end

feature -- Cursor movement

	forth
		do
			bar.advance
			original_cursor.forth
		end

feature {NONE} -- Implementation

	original_cursor: ITERATION_CURSOR [G]

	bar: PB_PROGRESS_BAR

end
