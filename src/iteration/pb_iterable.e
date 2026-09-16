note

	description:

		"Iterable decorator that reports traversal progress without changing item order."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_ITERABLE [G]

inherit

	ITERABLE [G]

create

	make_over

feature {NONE} -- Initialization

	make_over (a_source: ITERABLE [G])
			-- Decorate `a_source`; every traversal gets fresh progress on a private display.
		local
			formatters: PB_FORMATTERS
		do
			create display.make
			source := a_source
			create formatters
			formatter := formatters.basic
		end

feature -- Access

	display: PB_DISPLAY
			-- Display shared by every traversal cursor created by Current.

	new_cursor: ITERATION_CURSOR [G]
			-- Fresh progress-reporting cursor over `source`.
		local
			cursor: PB_ITERATION_CURSOR [G]
		do
			if attached {FINITE [G]} source as finite then
				create cursor.make_known (source.new_cursor, finite.count.to_integer_64, formatter, display, has_line_policy, keeps_final_line)
			else
				create cursor.make_unknown (source.new_cursor, formatter, display, has_line_policy, keeps_final_line)
			end
			Result := cursor
		end

feature -- Status report

	has_line_policy: BOOLEAN
			-- Has final-line retention been explicitly chosen for future cursors?

	keeps_final_line: BOOLEAN
			-- Explicit retention choice; used only when `has_line_policy`.
			-- Otherwise each cursor keeps its line only if the display is idle at start.

feature -- Configuration

	set_display (a_display: PB_DISPLAY)
			-- Use `a_display` for future cursors; existing traversals keep their display.
		do
			display := a_display
		ensure
			display_set: display = a_display
		end

	set_line_formatter (a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Use `a_formatter` for cursors created from now on.
		do
			formatter := a_formatter
		end

	keep_final_line
			-- Configure future traversal cursors to retain their final line.
		do
			keeps_final_line := True
			has_line_policy := True
		ensure
			kept: keeps_final_line
		end

	discard_final_line
			-- Configure future traversal cursors to remove their final line.
		do
			keeps_final_line := False
			has_line_policy := True
		ensure
			discarded: not keeps_final_line
		end

feature -- Output

	put_line (a_message: READABLE_STRING_GENERAL)
			-- Write `a_message` above all active lines in `display`.
		do
			display.put_line (a_message)
		end

feature {NONE} -- Implementation

	source: ITERABLE [G]
			-- Decorated source; ownership remains with the caller.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Formatter used by every fresh traversal.

end
