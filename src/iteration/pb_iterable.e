note

	description:
		"Iterable decorator that reports traversal progress without changing item order."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_ITERABLE [G]

inherit

	ITERABLE [G]

create

	make,
	make_with_formatter

feature {NONE} -- Initialization

	make (a_source: ITERABLE [G])
			-- Decorate `a_source` with the default formatter.
		local
			formatters: PB_FORMATTERS
		do
			create formatters
			initialize (a_source, formatters.basic)
		end

	make_with_formatter (
		a_source: ITERABLE [G];
		a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
	)
			-- Decorate `a_source` and render each traversal with `a_formatter`.
		do
			initialize (a_source, a_formatter)
		end

	initialize (
		a_source: ITERABLE [G];
		a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
	)
			-- Retain `a_source` and `a_formatter` for fresh cursors.
		do
			source := a_source
			formatter := a_formatter
		end

feature -- Access

	new_cursor: ITERATION_CURSOR [G]
			-- Fresh progress-reporting cursor over `source`.
		local
			cursor: PB_ITERATION_CURSOR [G]
		do
			if attached {FINITE [G]} source as finite then
				create cursor.make_known (source.new_cursor, finite.count.to_integer_64, formatter)
			else
				create cursor.make_unknown (source.new_cursor, formatter)
			end
			Result := cursor
		end

feature {NONE} -- Implementation

	source: ITERABLE [G]
			-- Decorated source; ownership remains with the caller.

	formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Formatter used by every fresh traversal.

end
