note

	description:

		"Manually updated terminal progress bar with agent-based formatting."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_BAR

create

	make,
	make_with_formatter,
	make_unknown,
	make_unknown_with_formatter,
	make_in,
	make_in_with_formatter,
	make_unknown_in,
	make_unknown_in_with_formatter,
	make_child

feature {NONE} -- Initialization

	make (a_total: INTEGER_64)
			-- Create top-level progress with known `a_total` and a private display.
		require
			total_non_negative: a_total >=
				0
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_private (
				True,
				a_total,
				formatters.basic
			)
		ensure
			total_known: has_total
			total_set: total = a_total
		end

	make_with_formatter (a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create top-level progress with known `a_total`, a formatter, and a private display.
		require
			total_non_negative: a_total >=
				0
		do
			initialize_private (
				True,
				a_total,
				a_formatter
			)
		ensure
			total_known: has_total
			total_set: total = a_total
		end

	make_unknown
			-- Create top-level progress with unknown total and a private display.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_private (
				False,
				0,
				formatters.basic
			)
		ensure
			total_unknown: not has_total
		end

	make_unknown_with_formatter (a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create top-level progress with unknown total, a formatter, and a private display.
		do
			initialize_private (
				False,
				0,
				a_formatter
			)
		ensure
			total_unknown: not has_total
		end

	make_in (a_display: PB_DISPLAY; a_total: INTEGER_64)
			-- Create top-level progress with known `a_total` in `a_display`.
		require
			total_non_negative: a_total >=
				0
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_in (
				a_display,
				True,
				a_total,
				formatters.basic
			)
		ensure
			display_set: display = a_display
			total_known: has_total
			total_set: total = a_total
		end

	make_in_with_formatter (a_display: PB_DISPLAY; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create formatted top-level progress with known `a_total` in `a_display`.
		require
			total_non_negative: a_total >=
				0
		do
			initialize_in (
				a_display,
				True,
				a_total,
				a_formatter
			)
		ensure
			display_set: display = a_display
			total_known: has_total
			total_set: total = a_total
		end

	make_unknown_in (a_display: PB_DISPLAY)
			-- Create top-level progress with unknown total in `a_display`.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_in (
				a_display,
				False,
				0,
				formatters.basic
			)
		ensure
			display_set: display = a_display
			total_unknown: not has_total
		end

	make_unknown_in_with_formatter (a_display: PB_DISPLAY; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create formatted top-level progress with unknown total in `a_display`.
		do
			initialize_in (
				a_display,
				False,
				0,
				a_formatter
			)
		ensure
			display_set: display = a_display
			total_unknown: not has_total
		end

	make_child (a_parent: PB_BAR; a_total: INTEGER_64)
			-- Create progress with known `a_total` nested below `a_parent`.
			-- Render `a_parent` at its existing position first when necessary.
		require
			parent_not_finished: not a_parent.is_finished
			total_non_negative: a_total >=
				0
		local
			formatters: PB_FORMATTERS
		do
			if not a_parent.is_started then
				a_parent.update (a_parent.position)
			end
			create formatters
			initialize_child (
				a_parent,
				True,
				a_total,
				formatters.basic
			)
		ensure
			parent_started: a_parent.is_started
			parent_position_unchanged: a_parent.position = old a_parent.position
			started_parent_revision_unchanged: old a_parent.is_started implies
				a_parent.revision = old a_parent.revision
			lazy_parent_revision_advanced: not old a_parent.is_started implies
				a_parent.revision = old a_parent.revision +
					1
			display_shared: display = a_parent.display
			total_known: has_total
			total_set: total = a_total
			child_not_started: not is_started
			child_open: not is_finished
			open_child_registered: a_parent.has_open_children
		end

	initialize_private (a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize Current with a private display.
		require
			total_non_negative: a_total >=
				0
		local
			private_display: PB_DISPLAY
		do
			create private_display.make
			initialize_in (
				private_display,
				a_has_total,
				a_total,
				a_formatter
			)
		end

	initialize_in (a_display: PB_DISPLAY; a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize top-level Current in `a_display`.
		require
			total_non_negative: a_total >=
				0
		do
			has_total := a_has_total
			stored_total := a_total
			formatter := a_formatter
			display := a_display
			display_line := a_display.new_line
			keeps_final_line := True
		end

	initialize_child (a_parent: PB_BAR; a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize Current immediately below `a_parent` and its descendants.
		require
			parent_started: a_parent.is_started
			parent_not_finished: not a_parent.is_finished
			total_non_negative: a_total >=
				0
		do
			has_total := a_has_total
			stored_total := a_total
			formatter := a_formatter
			display := a_parent.display
			display_line := display.new_child_line (a_parent.display_line)
			keeps_final_line := True
		end

feature -- Access

	display: PB_DISPLAY
			-- Display coordinating Current with related progress bars.

	position: INTEGER_64
			-- Current absolute position.

	total: INTEGER_64
			-- Expected total.
		require
			total_known: has_total
		do
			Result := stored_total
		ensure
			non_negative: Result >=
				0
		end

	revision: INTEGER_64
			-- Number of accepted update and pulse requests.

feature -- Status report

	has_total: BOOLEAN
			-- Is the expected total known?

	is_started: BOOLEAN
			-- Has Current received an update or pulse?

	is_finished: BOOLEAN
			-- Has Current terminated its progress line?

	keeps_final_line: BOOLEAN
			-- Should the final line remain visible after `finish`?

	has_open_children: BOOLEAN
			-- Does Current have a child or deeper descendant that has not finished?
		do
			if not is_finished then
				Result := display.has_open_descendants (display_line)
			end
		end

feature -- Configuration

	keep_final_line
			-- Keep the final line visible after `finish`.
		require
			not_started: not is_started
			not_finished: not is_finished
		do
			keeps_final_line := True
		ensure
			kept: keeps_final_line
		end

	discard_final_line
			-- Remove the final line after `finish`.
		require
			not_started: not is_started
			not_finished: not is_finished
		do
			keeps_final_line := False
		ensure
			discarded: not keeps_final_line
		end

feature -- Progress

	update (a_current: INTEGER_64)
			-- Set the current absolute position and refresh its presentation.
		require
			not_finished: not is_finished
			current_non_negative: a_current >=
				0
		do
			position := a_current
			revision :=
				revision +
					1
			is_started := True
			refresh (False)
		ensure
			position_set: position = a_current
			started: is_started
			revision_advanced: revision = old revision +
				1
		end

	pulse
			-- Advance unknown progress animation without changing its position.
		require
			not_finished: not is_finished
			total_unknown: not has_total
		do
			revision :=
				revision +
					1
			is_started := True
			refresh (False)
		ensure
			position_unchanged: position = old position
			started: is_started
			revision_advanced: revision = old revision +
				1
		end

	finish
			-- Render the final state and close Current's display line.
		require
			finished_or_no_open_descendants: is_finished or else
				not has_open_children
		do
			if not is_finished then
				refresh (True)
				is_finished := True
			end
		ensure
			finished: is_finished
			position_unchanged: position = old position
		end

feature -- Output

	put_line (a_message: READABLE_STRING_GENERAL)
			-- Write `a_message` above all active lines in `display`.
		do
			display.put_line (a_message)
		ensure
			position_unchanged: position = old position
			revision_unchanged: revision = old revision
			started_unchanged: is_started = old is_started
			finished_unchanged: is_finished = old is_finished
		end

feature {PB_BAR} -- Display identity

	display_line: PB_DISPLAY_LINE
			-- Stable line handle owned by Current.

feature {NONE} -- Rendering

	refresh (a_is_final: BOOLEAN)
			-- Format Current and update its display line.
		local
			progress: PB_PROGRESS
			formatted: READABLE_STRING_GENERAL
			line: STRING_32
		do
			if has_total then
				create progress.make_known (
					position,
					stored_total,
					revision,
					a_is_final
				)
			else
				create progress.make_unknown (
					position,
					revision,
					a_is_final
				)
			end
			formatted := formatter.item ([progress])
			create line.make_from_string_general (formatted)
			if a_is_final then
				display.finish (
					display_line,
					line,
					keeps_final_line
				)
			else
				display.redraw (
					display_line,
					line
				)
			end
		end

feature {NONE} -- Implementation

	stored_total: INTEGER_64
			-- Expected total when `has_total`.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Presentation function called for every refresh request.

invariant

	position_non_negative: position >=
		0
	revision_non_negative: revision >=
		0
	stored_total_non_negative: stored_total >=
		0

end
