class PB_MULTIPLE_PROGRESS_RENDERER
	-- A fixed group of single-line bars sharing one terminal block.
	-- Attach distinct bars before their first display. Calls must be sequential.
	-- Lines must fit the terminal width and the block must fit its height.

inherit

	PB_PROGRESS_RENDERER
		redefine
			render,
			put_line
		end

create

	make

feature {NONE} -- Initialization

	make (a_bars: ITERABLE [PB_PROGRESS_BAR])
			-- Attach bars in iteration order, preserving their formatters.
			-- Do not replace individual renderers while the group is in use.
		require
			not_empty: not a_bars.new_cursor.after
		do
			create entries.make
			across
				a_bars
			as
				progress_bar
			loop
				entries.extend ([progress_bar, progress_bar.renderer])
			end
			across
				entries
			as
				entry
			loop
				entry.bar.set_renderer (Current)
			end
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Delegate to the registered bar's original formatter.
		local
			original: detachable PB_PROGRESS_RENDERER
		do
			across
				entries
			as
				entry
			loop
				if entry.bar = a_progress_bar then
					original := entry.formatter
				end
			end
			check
				registered_bar: attached original as formatter
			then
				Result := formatter.format_line (a_progress_bar)
			end
		end

feature -- Rendering

	render (a_progress_bar: PB_PROGRESS_BAR)
			-- Redraw the group after a bar update, retaining finished bars.
		do
			redraw
		end

	put_line (a_string: READABLE_STRING_GENERAL)
			-- Print a message above the group and restore all its rows.
		do
			erase_block
			emit (a_string)
			emit ("%N")
			redraw
		end

feature {NONE} -- Implementation

	entries: LINKED_LIST [TUPLE [bar: PB_PROGRESS_BAR; formatter: PB_PROGRESS_RENDERER]]
			-- Stable display order and original formatters.

	displayed: BOOLEAN
			-- Is the cursor positioned immediately below the displayed block?

	redraw
		local
			frame: STRING_32
		do
			create frame.make_empty
			if displayed then
				append_cursor_up (frame)
			end
			across
				entries
			as
				entry
			loop
				frame.extend (Carriage_return.to_character_32)
				frame.append (entry.formatter.format_line (entry.bar))
				append_control_sequence (frame, Erase_line_tail_command)
				frame.extend (Line_feed.to_character_32)
			end
			frame.extend (Carriage_return.to_character_32)
			emit (frame)
			displayed := True
		end

	erase_block
			-- Remove the block, leaving the cursor at its first row.
		local
			frame: STRING_32
		do
			if displayed then
				create frame.make_empty
				append_cursor_up (frame)
				across
					entries
				as
					entry
				loop
					frame.extend (Carriage_return.to_character_32)
					append_control_sequence (frame, Erase_entire_line_command)
					frame.extend (Line_feed.to_character_32)
				end
				append_cursor_up (frame)
				frame.extend (Carriage_return.to_character_32)
				emit (frame)
				displayed := False
			end
		end

	append_cursor_up (a_frame: STRING_32)
			-- Append movement from below the block to its first row.
		do
			append_control_sequence (a_frame, entries.count.out + Cursor_up_command)
		end

	append_control_sequence (a_frame: STRING_32; a_command: READABLE_STRING_GENERAL)
			-- Append a terminal control sequence with `a_command`.
		do
			a_frame.extend (Esc.to_character_32)
			a_frame.extend (Lbracket.to_character_32)
			a_frame.append_string_general (a_command)
		end

feature {NONE} -- Terminal commands

	Cursor_up_command: STRING = "A"

	Erase_line_tail_command: STRING = "K"

	Erase_entire_line_command: STRING = "2K"

end
