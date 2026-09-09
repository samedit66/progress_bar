note

	description:

		"Manually updated terminal progress bar with agent-based formatting."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_BAR

create

	make,
	make_unknown,
	make_in,
	make_unknown_in,
	make_child

feature {NONE} -- Initialization

	make (a_total: INTEGER_64)
			-- Create top-level progress with known `a_total` and a private display.
		require
			total_non_negative: a_total >= 0
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_private (True, a_total, formatters.basic)
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
			initialize_private (False, 0, formatters.basic)
		ensure
			total_unknown: not has_total
		end

	make_in (a_display: PB_DISPLAY; a_total: INTEGER_64)
			-- Create top-level progress with known `a_total` in `a_display`.
		require
			total_non_negative: a_total >= 0
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_in (a_display, True, a_total, formatters.basic)
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
			initialize_in (a_display, False, 0, formatters.basic)
		ensure
			display_set: display = a_display
			total_unknown: not has_total
		end

	make_child (a_parent: PB_BAR; a_total: INTEGER_64)
			-- Create progress with known `a_total` nested below `a_parent`.
			-- Render `a_parent` at its existing position first when necessary.
		require
			parent_not_finished: not a_parent.is_finished
			total_non_negative: a_total >= 0
		local
			formatters: PB_FORMATTERS
		do
			if a_total > 0 and then not a_parent.is_started then
				a_parent.update (a_parent.position)
			end
			create formatters
			initialize_child (a_parent, True, a_total, formatters.basic)
		ensure
			parent_started: a_total > 0 implies a_parent.is_started
			parent_position_unchanged: a_parent.position = old a_parent.position
			started_parent_revision_unchanged: old a_parent.is_started implies a_parent.revision = old a_parent.revision
			lazy_parent_revision_advanced: a_total > 0 and not old a_parent.is_started implies a_parent.revision = old a_parent.revision + 1
			display_shared: display = a_parent.display
			total_known: has_total
			total_set: total = a_total
			child_not_started: not is_started
			child_completion: is_finished = (a_total = 0)
			open_child_registered: a_total > 0 implies a_parent.has_open_children
		end

	initialize_private (a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize Current with a private display.
		require
			total_non_negative: a_total >= 0
		local
			private_display: PB_DISPLAY
		do
			create private_display.make
			initialize_in (private_display, a_has_total, a_total, a_formatter)
		end

	initialize_in (a_display: PB_DISPLAY; a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize top-level Current in `a_display`.
		require
			total_non_negative: a_total >= 0
		do
			has_total := a_has_total
			stored_total := a_total
			formatter := a_formatter
			display := a_display
			if a_has_total and a_total = 0 then
				display_line := a_display.new_closed_line
			else
				display_line := a_display.new_line
			end
			keeps_final_line := True
			if not is_finished then
				display_line.set_bar (Current)
			end
		end

	initialize_child (a_parent: PB_BAR; a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize Current immediately below `a_parent` and its descendants.
		require
			parent_started: a_total > 0 implies a_parent.is_started
			parent_not_finished: not a_parent.is_finished
			total_non_negative: a_total >= 0
		do
			has_total := a_has_total
			stored_total := a_total
			formatter := a_formatter
			display := a_parent.display
			if a_has_total and a_total = 0 then
				display_line := display.new_closed_line
			else
				display_line := display.new_child_line (a_parent.display_line)
			end
			keeps_final_line := True
			if not is_finished then
				display_line.set_bar (Current)
			end
		end

feature -- Access

	display: PB_DISPLAY
			-- Display coordinating Current with related progress bars.

	position: INTEGER_64
			-- Last accepted absolute position, initially zero.

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
			-- Number of accepted update and pulse requests.

feature -- Status report

	has_total: BOOLEAN
			-- Is the expected total known?

	is_started: BOOLEAN
			-- Has Current received an update or pulse?

	is_finished: BOOLEAN
			-- Has Current irreversibly terminated its progress line?
		do
			Result := display_line.is_closed
		end

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

	set_formatter (a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Apply `a_formatter` on the next refresh; do nothing after completion.
		do
			if not is_finished then
				formatter := a_formatter
			end
		ensure
			position_unchanged: position = old position
			revision_unchanged: revision = old revision
			finished_unchanged: is_finished = old is_finished
		end

	keep_final_line
			-- Keep the final line. Closed bars ignore configuration commands.
		require
			configurable: is_finished or else not is_started
		do
			if not is_finished then
				keeps_final_line := True
			end
		ensure
			kept_when_active: not is_finished implies keeps_final_line
			closed_unchanged: old is_finished implies keeps_final_line = old keeps_final_line
		end

	discard_final_line
			-- Remove the final line. Closed bars ignore configuration commands.
		require
			configurable: is_finished or else not is_started
		do
			if not is_finished then
				keeps_final_line := False
			end
		ensure
			discarded_when_active: not is_finished implies not keeps_final_line
			closed_unchanged: old is_finished implies keeps_final_line = old keeps_final_line
		end

feature -- Progress

	update (a_current: INTEGER_64)
			-- Set absolute progress, clamped to its bounds. Finish at a known total.
		do
			if not is_finished then
				position := a_current.max (0)
				if has_total then
					position := position.min (stored_total)
				end
				revision := revision + 1
				is_started := True
				if has_total and then position = stored_total then
					finish
				else
					refresh (False)
				end
			end
		ensure
			closed_position_unchanged: old is_finished implies position = old position
			closed_revision_unchanged: old is_finished implies revision = old revision
			accepted_known: not old is_finished and has_total implies position = a_current.max (0).min (stored_total)
			accepted_unknown: not old is_finished and not has_total implies position = a_current.max (0)
			started_when_accepted: not old is_finished implies is_started
			revision_advanced_when_accepted: not old is_finished implies revision = old revision + 1
			maximum_finishes: has_total and then position = stored_total implies is_finished
		end

	advance (a_delta: INTEGER_64)
			-- Signed relative update, clamped before addition can overflow.
		local
			upper: INTEGER_64
		do
			if not is_finished then
				if has_total then
					upper := stored_total
				else
					upper := {INTEGER_64}.max_value
				end
				if a_delta > upper - position then
					update (upper)
				elseif a_delta < -position then
					update (0)
				else
					update (position + a_delta)
				end
			end
		ensure
			closed_position_unchanged: old is_finished implies position = old position
			closed_revision_unchanged: old is_finished implies revision = old revision
		end

	pulse
			-- Animate active unknown progress; ignore calls after completion.
		require
			unknown_when_active: is_finished or else not has_total
		do
			if not is_finished then
				revision := revision + 1
				is_started := True
				refresh (False)
			end
		ensure
			position_unchanged: position = old position
			closed_revision_unchanged: old is_finished implies revision = old revision
			started_when_accepted: not old is_finished implies is_started
			revision_advanced_when_accepted: not old is_finished implies revision = old revision + 1
		end

	finish
			-- Stop all open descendants, then Current, at their actual values.
		do
			if not is_finished then
				display.finish_descendants (display_line)
				refresh (True)
			end
		ensure
			finished: is_finished
			position_unchanged: position = old position
			no_open_children: not has_open_children
		end

feature -- Output

	put_line (a_message: READABLE_STRING_GENERAL)
			-- Write `a_message` above all active lines in `display`.
		do
			if not is_finished then
				display.put_line (a_message)
			end
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
				create progress.make_known (position, stored_total, revision, a_is_final)
			else
				create progress.make_unknown (position, revision, a_is_final)
			end
			formatted := formatter.item ([progress])
			create line.make_from_string_general (formatted)
			if a_is_final then
				display.finish (display_line, line, keeps_final_line)
			else
				display.redraw (display_line, line)
			end
		end

feature {NONE} -- Implementation

	stored_total: INTEGER_64
			-- Expected total when `has_total`.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Presentation function called for every refresh request.

invariant

	known_position_bounded: has_total implies position <= stored_total
	position_non_negative: position >= 0
	revision_non_negative: revision >= 0
	stored_total_non_negative: stored_total >= 0

end
