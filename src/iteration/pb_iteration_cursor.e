note

	description:

		"Iteration cursor that advances a private progress bar after each visited item."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_ITERATION_CURSOR [G]

inherit

	ITERATION_CURSOR [G]

create {PB_ITERABLE}

	make

feature {NONE} -- Initialization

	make (a_source_cursor: ITERATION_CURSOR [G]; a_bar: PB_BAR)
			-- Take the traversal's configured bar and start reporting progress.
		require
			bar_not_started: not a_bar.is_started
			zero_progress: a_bar.progress = 0
		do
			source_cursor := a_source_cursor
			bar := a_bar
			bar.start
			finish_if_exhausted
		ensure
			zero_processed: processed = 0
			empty_finished: source_cursor.after implies bar.is_finished
		end

	finish_if_exhausted
			-- Close unknown or shortened traversal when its source has no more items.
		do
			if source_cursor.after and then not bar.is_finished then
				bar.finish
			end
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
			bar.set_progress (processed)
			finish_if_exhausted
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
