note

	description:
		"Iteration cursor that advances a private progress bar after each visited item."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_ITERATION_CURSOR [G]

inherit

	ITERATION_CURSOR [G]

create {PB_ITERABLE}

	make_known,
	make_unknown

feature {NONE} -- Initialization

	make_known (
		a_source_cursor: ITERATION_CURSOR [G];
		a_total: INTEGER_64;
		a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
	)
			-- Create a cursor with a known `a_total`.
		require
			total_non_negative: a_total >= 0
		do
			source_cursor := a_source_cursor
			create bar.make_with_formatter (a_total, a_formatter)
			start
		end

	make_unknown (
		a_source_cursor: ITERATION_CURSOR [G];
		a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
	)
			-- Create a cursor whose total is unknown.
		do
			source_cursor := a_source_cursor
			create bar.make_unknown_with_formatter (a_formatter)
			start
		end

	start
			-- Render the initial state and finish immediately for an empty source.
		do
			bar.update (0)
			if source_cursor.after then
				bar.finish
			end
		ensure
			zero_processed: processed = 0
			empty_finished: source_cursor.after implies bar.is_finished
		end

feature -- Access

	item: G
			-- Item at the current source cursor position.
		do
			Result := source_cursor.item
		end

feature -- Status report

	after: BOOLEAN
			-- Are there no more source items?
		do
			Result := source_cursor.after
		end

feature -- Cursor movement

	forth
			-- Move to the next item and report the completed source item.
		do
			source_cursor.forth
			processed := processed + 1
			bar.update (processed)
			if source_cursor.after then
				bar.finish
			end
		ensure then
			processed_advanced: processed = old processed + 1
			finished_at_end: after implies bar.is_finished
		end

feature {NONE} -- Implementation

	source_cursor: ITERATION_CURSOR [G]
			-- Cursor supplied by the decorated iterable.

	bar: PB_BAR
			-- Progress state private to this traversal.

	processed: INTEGER_64
			-- Number of source items passed by `forth`.

invariant

	processed_non_negative: processed >= 0
	finished_only_after: bar.is_finished implies source_cursor.after

end
