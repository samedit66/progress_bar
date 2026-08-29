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
	make_unknown_with_formatter

feature {NONE} -- Initialization

	make (a_total: INTEGER_64)
			-- Create progress with known `a_total` and the default formatter.
		require
			total_non_negative: a_total >=
				0
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize (
				True,
				a_total,
				formatters.basic
			)
		ensure
			total_known: has_total
			total_set: total = a_total
		end

	make_with_formatter (a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create progress with known `a_total` rendered by `a_formatter`.
		require
			total_non_negative: a_total >=
				0
		do
			initialize (
				True,
				a_total,
				a_formatter
			)
		ensure
			total_known: has_total
			total_set: total = a_total
		end

	make_unknown
			-- Create progress with unknown total and the default formatter.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize (
				False,
				0,
				formatters.basic
			)
		ensure
			total_unknown: not has_total
		end

	make_unknown_with_formatter (a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create progress with unknown total rendered by `a_formatter`.
		do
			initialize (
				False,
				0,
				a_formatter
			)
		ensure
			total_unknown: not has_total
		end

	initialize (a_has_total: BOOLEAN; a_total: INTEGER_64; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Initialize Current with one coherent progress mode.
		require
			total_non_negative: a_total >=
				0
		do
			has_total := a_has_total
			stored_total := a_total
			formatter := a_formatter
			create terminal_renderer
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
			-- Render the final state and terminate the progress line.
		do
			if not is_finished then
				refresh (True)
				is_finished := True
			end
		ensure
			finished: is_finished
			position_unchanged: position = old position
		end

feature {NONE} -- Rendering

	refresh (a_is_final: BOOLEAN)
			-- Format Current and update its terminal line when necessary.
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
				emit (terminal_renderer.finish_sequence (
					line,
					previous_line_count
				))
				last_line := line
				previous_line_count := line.count
			elseif not attached last_line as previous_line or else
				not line.same_string (previous_line) then
				emit (terminal_renderer.redraw_sequence (
					line,
					previous_line_count
				))
				last_line := line
				previous_line_count := line.count
			end
		end

	emit (a_sequence: STRING_32)
			-- Write `a_sequence` to standard error immediately.
		do
			io.error.put_string_32 (a_sequence)
			io.error.flush
		end

feature {NONE} -- Implementation

	stored_total: INTEGER_64
			-- Expected total when `has_total`.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Presentation function called for every refresh request.

	terminal_renderer: PB_TERMINAL_RENDERER
			-- Terminal control-sequence builder.

	last_line: detachable STRING_32
			-- Last line written to the terminal, if any.

	previous_line_count: INTEGER
			-- Character count of `last_line`.

invariant

	position_non_negative: position >=
		0
	revision_non_negative: revision >=
		0
	stored_total_non_negative: stored_total >=
		0
	line_count_non_negative: previous_line_count >=
		0
	last_line_count: attached last_line as line implies
		previous_line_count = line.count

end
