note

	description:
		"Pure construction of terminal line replacement sequences."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_TERMINAL_RENDERER

feature -- Conversion

	redraw_sequence (a_line: READABLE_STRING_GENERAL; a_previous_count: INTEGER): STRING_32
			-- Sequence that replaces a line of `a_previous_count` characters with `a_line`.
		require
			previous_count_non_negative: a_previous_count >= 0
		local
			padding: STRING_32
			padding_count: INTEGER
		do
			padding_count := (a_previous_count - a_line.count).max (0)
			create Result.make (a_line.count * 2 + padding_count + 2)
			Result.append_character ('%R')
			Result.append_string_general (a_line)
			if padding_count > 0 then
				create padding.make_filled (' ', padding_count)
				Result.append (padding)
				Result.append_character ('%R')
				Result.append_string_general (a_line)
			end
		end

	finish_sequence (a_line: READABLE_STRING_GENERAL; a_previous_count: INTEGER): STRING_32
			-- Sequence that replaces a line and terminates it.
		require
			previous_count_non_negative: a_previous_count >= 0
		local
			padding: STRING_32
			padding_count: INTEGER
		do
			padding_count := (a_previous_count - a_line.count).max (0)
			create Result.make (a_line.count + padding_count + 2)
			Result.append_character ('%R')
			Result.append_string_general (a_line)
			if padding_count > 0 then
				create padding.make_filled (' ', padding_count)
				Result.append (padding)
			end
			Result.append_character ('%N')
		end

end
