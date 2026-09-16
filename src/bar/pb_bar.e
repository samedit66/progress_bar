note

	description:

		"Manually updated terminal progress bar with agent-based formatting."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_BAR

create

	make_with_total,
	make_unknown,
	make_child

feature {NONE} -- Initialization

	make_with_total (a_total: INTEGER_64)
			-- Create silent progress with a known total and a private display.
		require
			total_non_negative: a_total >= 0
		do
			initialize (True, a_total)
		ensure
			total_known: has_total
			total_set: total = a_total
		end

	make_unknown
			-- Create silent progress with an unknown total and a private display.
		do
			initialize (False, 0)
		ensure
			total_unknown: not has_total
		end

	make_child (a_parent: PB_BAR; a_total: INTEGER_64)
			-- Create an explicitly owned child; start a nonempty child's parent.
			-- Unlike sharing a display, this makes parent completion close the child.
		require
			parent_not_finished: not a_parent.is_finished
			total_non_negative: a_total >= 0
		local
			line: PB_DISPLAY_LINE
		do
			initialize (True, a_total)
			display := a_parent.display
			is_child := True
			if a_total > 0 then
				a_parent.start
				if attached a_parent.display_line as parent_line then
					line := display.new_child_line (parent_line)
					display_line := line
					line.set_bar (Current)
				end
			end
		ensure
			parent_started: a_total > 0 implies a_parent.is_started
			parent_progress_unchanged: a_parent.progress = old a_parent.progress
			display_shared: display = a_parent.display
			child_not_started: not is_started
			child_completion: is_finished = (a_total = 0)
			open_child_registered: a_total > 0 implies a_parent.has_open_children
		end

	initialize (a_has_total: BOOLEAN; a_total: INTEGER_64)
			-- Establish configuration without registering a terminal line.
		local
			formatters: PB_FORMATTERS
		do
			create display.make
			has_total := a_has_total
			stored_total := a_total
			create formatters
			formatter := formatters.basic
		end

feature -- Access

	display: PB_DISPLAY
			-- Display coordinating Current with related progress bars.

	progress: INTEGER_64
			-- Last accepted absolute progress, initially zero.

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
			-- Number of accepted set_progress and pulse requests.

feature -- Status report

	has_total: BOOLEAN
			-- Is the expected total known?

	is_started: BOOLEAN
			-- Has Current started through `start`, a progress update, or `pulse`?

	is_finished: BOOLEAN
			-- Has Current irreversibly terminated its progress line?
		do
			Result := (has_total and then stored_total = 0) or else (attached display_line as line and then line.is_closed)
		end

	is_child: BOOLEAN
			-- Was Current created with explicit parent ownership?

	keeps_final_line: BOOLEAN
			-- Keep the final row? Automatic until start: keep only if display is idle.
		do
			if has_line_policy then
				Result := stored_keeps_final_line
			else
				Result := not is_child and then not display.has_open_lines
			end
		end

	has_open_children: BOOLEAN
			-- Does Current have a child or deeper descendant that has not finished?
		do
			if not is_finished and then attached display_line as line then
				Result := display.has_open_descendants (line)
			end
		end

feature -- Configuration

	set_display (a_display: PB_DISPLAY)
			-- Share `a_display` before starting. Explicit children retain their parent's display.
			-- A zero-total bar may also be configured; it never registers a line.
		require
			not_started: not is_started
			independent: not is_child
			unfinished_or_empty: not is_finished or else (has_total and then total = 0)
		do
			display := a_display
		ensure
			display_set: display = a_display
		end

	set_line_formatter (a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Apply `a_formatter` on the next refresh; do nothing after completion.
		do
			if not is_finished then
				formatter := a_formatter
			end
		ensure
			position_unchanged: progress = old progress
			revision_unchanged: revision = old revision
			finished_unchanged: is_finished = old is_finished
		end

	keep_final_line
			-- Keep the final line. Closed bars ignore configuration commands.
		require
			configurable: is_finished or else not is_started
		do
			if not is_finished then
				stored_keeps_final_line := True
				has_line_policy := True
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
				stored_keeps_final_line := False
				has_line_policy := True
			end
		ensure
			discarded_when_active: not is_finished implies not keeps_final_line
			closed_unchanged: old is_finished implies keeps_final_line = old keeps_final_line
		end

feature -- Progress

	start
			-- Show initial progress once; never reset or reopen an operation.
		do
			if not is_started and not is_finished then
				set_progress (progress)
			end
		ensure
			progress_unchanged: progress = old progress
			started_when_open: not is_finished implies is_started
		end

	forth
			-- Report one completed unit of work; start lazily if necessary.
		do
			forth_by (1)
		end

	set_progress (a_current: INTEGER_64)
			-- Set absolute progress, clamped to its bounds. Finish at a known total.
		do
			if not is_finished then
				progress := a_current.max (0)
				if has_total then
					progress := progress.min (stored_total)
				end
				register_line
				revision := revision + 1
				is_started := True
				if has_total and then progress = stored_total then
					finish
				else
					refresh (False)
				end
			end
		ensure
			closed_position_unchanged: old is_finished implies progress = old progress
			closed_revision_unchanged: old is_finished implies revision = old revision
			accepted_known: not old is_finished and has_total implies progress = a_current.max (0).min (stored_total)
			accepted_unknown: not old is_finished and not has_total implies progress = a_current.max (0)
			started_when_accepted: not old is_finished implies is_started
			revision_advanced_when_accepted: not old is_finished implies revision = old revision + 1
			maximum_finishes: has_total and then progress = stored_total implies is_finished
		end

	forth_by (a_delta: INTEGER_64)
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
				if a_delta > upper - progress then
					set_progress (upper)
				elseif a_delta < -progress then
					set_progress (0)
				else
					set_progress (progress + a_delta)
				end
			end
		ensure
			closed_position_unchanged: old is_finished implies progress = old progress
			closed_revision_unchanged: old is_finished implies revision = old revision
		end

	pulse
			-- Animate active unknown progress; ignore calls after completion.
		require
			unknown_when_active: is_finished or else not has_total
		do
			forth_by (0)
		ensure
			position_unchanged: progress = old progress
			closed_revision_unchanged: old is_finished implies revision = old revision
			started_when_accepted: not old is_finished implies is_started
			revision_advanced_when_accepted: not old is_finished implies revision = old revision + 1
		end

	finish
			-- Stop all open descendants, then Current, at their actual values.
		do
			if not is_finished then
				register_line
				if attached display_line as line then
					display.finish_descendants (line)
				end
				refresh (True)
			end
		ensure
			finished: is_finished
			position_unchanged: progress = old progress
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
			position_unchanged: progress = old progress
			revision_unchanged: revision = old revision
			started_unchanged: is_started = old is_started
			finished_unchanged: is_finished = old is_finished
		end

feature {PB_BAR} -- Display identity

	display_line: detachable PB_DISPLAY_LINE
			-- Stable line handle owned by Current.

feature {NONE} -- Rendering

	register_line
			-- Freeze the default retention policy and allocate one stable row handle.
		local
			line: PB_DISPLAY_LINE
		do
			if not has_line_policy then
				stored_keeps_final_line := keeps_final_line
				has_line_policy := True
			end
			if not attached display_line then
				line := display.new_line
				display_line := line
				line.set_bar (Current)
			end
		end

	refresh (a_is_final: BOOLEAN)
			-- Format Current and update its display line.
		local
			snapshot: PB_PROGRESS
			formatted: READABLE_STRING_GENERAL
			line: STRING_32
		do
			if has_total then
				create snapshot.make_known (progress, stored_total, revision, a_is_final)
			else
				create snapshot.make_unknown (progress, revision, a_is_final)
			end
			formatted := formatter.item ([snapshot])
			create line.make_from_string_general (formatted)
			if attached display_line as handle then
				if a_is_final then
					display.finish (handle, line, keeps_final_line)
				else
					display.redraw (handle, line)
				end
			end
		end

feature {NONE} -- Implementation

	has_line_policy: BOOLEAN
			-- Has retention been explicitly configured or fixed at first rendering?

	stored_keeps_final_line: BOOLEAN
			-- Retention policy once `has_line_policy`.

	stored_total: INTEGER_64
			-- Expected total when `has_total`.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Presentation function called for every refresh request.

invariant

	known_position_bounded: has_total implies progress <= stored_total
	position_non_negative: progress >= 0
	revision_non_negative: revision >= 0
	stored_total_non_negative: stored_total >= 0

end
