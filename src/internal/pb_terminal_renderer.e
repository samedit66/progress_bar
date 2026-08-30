note

	description:

		"Pure construction of terminal line replacement sequences."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_TERMINAL_RENDERER

feature -- Multiline conversion

	redraw_line_sequence (a_line: READABLE_STRING_GENERAL; a_previous_count, a_rows_below: INTEGER): STRING_32
			-- Sequence replacing one managed row and returning to the bottom row.
		require
			previous_count_non_negative: a_previous_count >=
				0
			rows_below_non_negative: a_rows_below >=
				0
		do
			if a_rows_below = 0 then
				Result := redraw_sequence (
					a_line,
					a_previous_count
				)
			else
				create Result.make (a_line.count +
					32)
				Result.append_character ('%R')
				append_cursor_up (
					Result,
					a_rows_below
				)
				Result.append_string_general ({STRING_32} "%/27/[2K%R")
				Result.append_string_general (a_line)
				append_cursor_down (
					Result,
					a_rows_below
				)
				Result.append_character ('%R')
			end
		end

	frame_sequence (a_previous_line_count: INTEGER; a_lines: ARRAYED_LIST [STRING_32]): STRING_32
			-- Sequence replacing a managed frame with `a_lines`.
		require
			previous_count_non_negative: a_previous_line_count >=
				0
		do
			create Result.make (a_previous_line_count *
				8 +
				frame_character_count (a_lines) +
				16)
			append_clear_frame (
				Result,
				a_previous_line_count
			)
			if a_previous_line_count = 0 and then
				not a_lines.is_empty then
				Result.append_character ('%R')
			end
			append_frame (
				Result,
				a_lines
			)
		end

	commit_frame_sequence (a_previous_line_count: INTEGER; a_lines: ARRAYED_LIST [STRING_32]): STRING_32
			-- Sequence replacing a managed frame and committing its remaining rows.
		require
			previous_count_non_negative: a_previous_line_count >=
				0
		do
			Result := frame_sequence (
				a_previous_line_count,
				a_lines
			)
			if not a_lines.is_empty then
				Result.append_character ('%N')
			end
		end

	message_frame_sequence (a_message: READABLE_STRING_GENERAL; a_previous_line_count: INTEGER; a_lines: ARRAYED_LIST [STRING_32]): STRING_32
			-- Sequence writing `a_message` above a managed multiline frame.
		require
			previous_count_non_negative: a_previous_line_count >=
				0
		do
			if a_previous_line_count = 1 and then
				a_lines.count = 1 then
				Result := message_sequence (
					a_message,
					a_lines.first,
					a_lines.first.count
				)
			else
				create Result.make (a_message.count +
					a_previous_line_count *
						8 +
					frame_character_count (a_lines) +
					16)
				append_clear_frame (
					Result,
					a_previous_line_count
				)
				Result.append_string_general (a_message)
				Result.append_character ('%N')
				append_frame (
					Result,
					a_lines
				)
			end
		end

feature -- Conversion

	redraw_sequence (a_line: READABLE_STRING_GENERAL; a_previous_count: INTEGER): STRING_32
			-- Sequence that replaces a line of `a_previous_count` characters with `a_line`.
		require
			previous_count_non_negative: a_previous_count >=
				0
		local
			padding: STRING_32
			padding_count: INTEGER
		do
			padding_count := (a_previous_count -
				a_line.count).max (0)
			create Result.make (a_line.count *
				2 +
				padding_count +
				2)
			Result.append_character ('%R')
			Result.append_string_general (a_line)
			if padding_count >
				0 then
				create padding.make_filled (
					' ',
					padding_count
				)
				Result.append (padding)
				Result.append_character ('%R')
				Result.append_string_general (a_line)
			end
		end

	finish_sequence (a_line: READABLE_STRING_GENERAL; a_previous_count: INTEGER): STRING_32
			-- Sequence that replaces a line and terminates it.
		require
			previous_count_non_negative: a_previous_count >=
				0
		local
			padding: STRING_32
			padding_count: INTEGER
		do
			padding_count := (a_previous_count -
				a_line.count).max (0)
			create Result.make (a_line.count +
				padding_count +
				2)
			Result.append_character ('%R')
			Result.append_string_general (a_line)
			if padding_count >
				0 then
				create padding.make_filled (
					' ',
					padding_count
				)
				Result.append (padding)
			end
			Result.append_character ('%N')
		end

	message_sequence (a_message, a_line: READABLE_STRING_GENERAL; a_previous_count: INTEGER): STRING_32
			-- Sequence that writes `a_message` above active `a_line`.
		require
			previous_count_non_negative: a_previous_count >=
				0
		local
			padding: STRING_32
		do
			create Result.make (a_message.count +
				a_line.count +
				a_previous_count +
				4)
			Result.append_character ('%R')
			if a_previous_count >
				0 then
				create padding.make_filled (
					' ',
					a_previous_count
				)
				Result.append (padding)
			end
			Result.append_character ('%R')
			Result.append_string_general (a_message)
			Result.append_character ('%N')
			Result.append_character ('%R')
			Result.append_string_general (a_line)
		end

feature {NONE} -- Multiline implementation

	append_clear_frame (a_sequence: STRING_32; a_line_count: INTEGER)
			-- Clear `a_line_count` rows, starting from the bottom managed row.
		require
			line_count_non_negative: a_line_count >=
				0
		local
			index: INTEGER
		do
			from
				index := a_line_count
			until
				index = 0
			loop
				a_sequence.append_string_general ({STRING_32} "%R%/27/[2K")
				if index >
					1 then
					append_cursor_up (
						a_sequence,
						1
					)
				end
				index :=
					index -
						1
			end
		end

	append_frame (a_sequence: STRING_32; a_lines: ARRAYED_LIST [STRING_32])
			-- Append `a_lines` top to bottom, leaving the cursor on the last row.
		local
			index: INTEGER
		do
			from
				index := 1
			until
				index >
					a_lines.count
			loop
				if index >
					1 then
					a_sequence.append_character ('%N')
					a_sequence.append_character ('%R')
				end
				a_sequence.append (a_lines.i_th (index))
				index :=
					index +
						1
			end
		end

	append_cursor_up (a_sequence: STRING_32; a_count: INTEGER)
			-- Move the terminal cursor up by `a_count` rows.
		require
			positive_count: a_count >
				0
		do
			a_sequence.append_string_general ({STRING_32} "%/27/[")
			a_sequence.append_integer (a_count)
			a_sequence.append_character ('A')
		end

	append_cursor_down (a_sequence: STRING_32; a_count: INTEGER)
			-- Move the terminal cursor down by `a_count` rows.
		require
			positive_count: a_count >
				0
		do
			a_sequence.append_string_general ({STRING_32} "%/27/[")
			a_sequence.append_integer (a_count)
			a_sequence.append_character ('B')
		end

	frame_character_count (a_lines: ARRAYED_LIST [STRING_32]): INTEGER
			-- Sum of character counts in `a_lines`.
		do
			across
				a_lines
			as
				line_cursor
			loop
				Result :=
					Result +
						line_cursor.count
			end
		end

end
