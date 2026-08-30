note

	description:

		"Iterable decorator that reports traversal progress without changing item order."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_ITERABLE [G]

inherit

	ITERABLE [G]

create

	make,
	make_with_formatter,
	make_in,
	make_in_with_formatter

feature {NONE} -- Initialization

	make (a_source: ITERABLE [G])
			-- Decorate `a_source` with the default formatter and a private display.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_private (
				a_source,
				formatters.basic
			)
		end

	make_with_formatter (a_source: ITERABLE [G]; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Decorate `a_source` with `a_formatter` and a private display.
		do
			initialize_private (
				a_source,
				a_formatter
			)
		end

	make_in (a_display: PB_DISPLAY; a_source: ITERABLE [G])
			-- Decorate `a_source` with the default formatter in `a_display`.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize_in (
				a_display,
				a_source,
				formatters.basic
			)
		ensure
			display_set: display = a_display
		end

	make_in_with_formatter (a_display: PB_DISPLAY; a_source: ITERABLE [G]; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Decorate `a_source` with `a_formatter` in `a_display`.
		do
			initialize_in (
				a_display,
				a_source,
				a_formatter
			)
		ensure
			display_set: display = a_display
		end

	initialize_private (a_source: ITERABLE [G]; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Retain source and formatter with a private display.
		local
			private_display: PB_DISPLAY
		do
			create private_display.make
			initialize_in (
				private_display,
				a_source,
				a_formatter
			)
		end

	initialize_in (a_display: PB_DISPLAY; a_source: ITERABLE [G]; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Retain source, formatter, and display for fresh cursors.
		do
			display := a_display
			source := a_source
			formatter := a_formatter
			keeps_final_line := True
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
				create cursor.make_known (
					source.new_cursor,
					finite.count.to_integer_64,
					formatter,
					display,
					keeps_final_line
				)
			else
				create cursor.make_unknown (
					source.new_cursor,
					formatter,
					display,
					keeps_final_line
				)
			end
			Result := cursor
		end

feature -- Status report

	keeps_final_line: BOOLEAN
			-- Should cursors created from now on retain their final line?

feature -- Configuration

	keep_final_line
			-- Configure future traversal cursors to retain their final line.
		do
			keeps_final_line := True
		ensure
			kept: keeps_final_line
		end

	discard_final_line
			-- Configure future traversal cursors to remove their final line.
		do
			keeps_final_line := False
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
