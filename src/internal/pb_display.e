note

	description:

		"Terminal display coordinating one or more ordered progress lines."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_DISPLAY

create

	make

feature {NONE} -- Initialization

	make
			-- Create an idle display.
		do
			create lines.make (1)
			create renderer
		end

feature -- Output

	put_line (a_message: READABLE_STRING_GENERAL)
			-- Write `a_message` above all currently visible progress lines.
		local
			visible_lines: ARRAYED_LIST [STRING_32]
		do
			visible_lines := current_lines
			emit (renderer.message_frame_sequence (
				a_message,
				visible_line_count,
				visible_lines
			))
		ensure
			line_count_unchanged: lines.count = old lines.count
		end

feature {PB_BAR} -- Line lifecycle

	new_line: PB_DISPLAY_LINE
			-- New pending top-level line at the bottom of Current.
		do
			create Result.make (Void)
			lines.extend (Result)
		ensure
			registered: lines.has (Result)
			open: not Result.is_closed
		end

	new_child_line (a_parent: PB_DISPLAY_LINE): PB_DISPLAY_LINE
			-- New pending line immediately after all descendants of `a_parent`.
		require
			parent_registered: is_registered (a_parent)
			parent_open: not a_parent.is_closed
		local
			index: INTEGER
		do
			create Result.make (a_parent)
			from
				index :=
					lines.index_of (
						a_parent,
						1
					) +
						1
			until
				index >
					lines.count or else
					not lines.i_th (index).is_descendant_of (a_parent)
			loop
				index :=
					index +
						1
			end
			if index >
				lines.count then
				lines.extend (Result)
			else
				lines.go_i_th (index)
				lines.put_left (Result)
			end
		ensure
			registered: lines.has (Result)
			parent_set: Result.parent = a_parent
			open: not Result.is_closed
		end

	redraw (a_line: PB_DISPLAY_LINE; a_text: STRING_32)
			-- Show `a_text` on `a_line`, preserving all other managed lines.
		require
			registered: is_registered (a_line)
			open: not a_line.is_closed
			single_line: is_single_line (a_text)
		local
			old_visible_count: INTEGER
			was_visible: BOOLEAN
			previous_count: INTEGER
			rows_below: INTEGER
		do
			old_visible_count := visible_line_count
			was_visible := a_line.is_visible
			if attached a_line.text as old_text then
				previous_count := old_text.count
			end
			if not attached a_line.text as old_text or else
				not old_text.same_string (a_text) then
				a_line.set_text (a_text)
				if was_visible then
					rows_below := visible_rows_below (a_line)
					emit (renderer.redraw_line_sequence (
						a_text,
						previous_count,
						rows_below
					))
				else
					emit (renderer.frame_sequence (
						old_visible_count,
						current_lines
					))
				end
			end
		ensure
			text_set: attached a_line.text as stored_text and then
				stored_text.same_string (a_text)
		end

	finish (a_line: PB_DISPLAY_LINE; a_text: STRING_32; a_keep_final_line: BOOLEAN)
			-- Close `a_line` with its final text and retention policy.
		require
			registered: is_registered (a_line)
			open: not a_line.is_closed
			no_open_descendants: not has_open_descendants (a_line)
			single_line: is_single_line (a_text)
		local
			old_visible_count: INTEGER
			previous_count: INTEGER
			visible_lines: ARRAYED_LIST [STRING_32]
		do
			old_visible_count := visible_line_count
			if attached a_line.text as old_text then
				previous_count := old_text.count
			end
			a_line.close (
				a_text,
				a_keep_final_line
			)
			visible_lines := current_lines
			if has_open_lines then
				emit (renderer.frame_sequence (
					old_visible_count,
					visible_lines
				))
			else
				if visible_lines.count = 1 and then
					old_visible_count <=
						1 then
					emit (renderer.finish_sequence (
						visible_lines.first,
						previous_count
					))
				else
					emit (renderer.commit_frame_sequence (
						old_visible_count,
						visible_lines
					))
				end
				lines.wipe_out
			end
		ensure
			closed: a_line.is_closed
			policy_set: a_line.keeps_final_line = a_keep_final_line
		end

	has_open_descendants (a_line: PB_DISPLAY_LINE): BOOLEAN
			-- Does `a_line` have a registered descendant that has not finished?
		require
			registered: is_registered (a_line)
		local
			candidate: PB_DISPLAY_LINE
		do
			across
				lines
			as
				line_cursor
			until
				Result
			loop
				candidate := line_cursor
				Result :=
					not candidate.is_closed and then
						candidate.is_descendant_of (a_line)
			end
		end

	is_registered (a_line: PB_DISPLAY_LINE): BOOLEAN
			-- Is `a_line` currently owned by Current?
		do
			Result := lines.has (a_line)
		end

	is_single_line (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_text` contain no terminal line separator?
		local
			index: INTEGER
			character: CHARACTER_32
		do
			Result := True
			from
				index := 1
			until
				not Result or else
					index >
						a_text.count
			loop
				character := a_text.item (index)
				Result :=
					character /= '%N' and then
						character /= '%R'
				index :=
					index +
						1
			end
		end

feature {NONE} -- Rendering

	current_lines: ARRAYED_LIST [STRING_32]
			-- Visible line texts in display order.
		do
			create Result.make (visible_line_count)
			across
				lines
			as
				line_cursor
			loop
				if attached line_cursor.text as line_text and then
					line_cursor.is_visible then
					Result.extend (line_text)
				end
			end
		end

	visible_line_count: INTEGER
			-- Number of rows currently managed by Current.
		do
			across
				lines
			as
				line_cursor
			loop
				if line_cursor.is_visible then
					Result :=
						Result +
							1
				end
			end
		end

	visible_rows_below (a_line: PB_DISPLAY_LINE): INTEGER
			-- Number of visible managed rows below `a_line`.
		require
			registered: lines.has (a_line)
		local
			found: BOOLEAN
		do
			across
				lines
			as
				line_cursor
			loop
				if found and then
					line_cursor.is_visible then
					Result :=
						Result +
							1
				elseif line_cursor = a_line then
					found := True
				end
			end
		end

	has_open_lines: BOOLEAN
			-- Is any registered line unfinished?
		do
			across
				lines
			as
				line_cursor
			until
				Result
			loop
				Result := not line_cursor.is_closed
			end
		end

	emit (a_sequence: STRING_32)
			-- Write `a_sequence` to standard error immediately.
		do
			io.error.put_string_32 (a_sequence)
			io.error.flush
		end

feature {NONE} -- Implementation

	lines: ARRAYED_LIST [PB_DISPLAY_LINE]
			-- Registered lines in stable hierarchy order.

	renderer: PB_TERMINAL_RENDERER
			-- Terminal control-sequence builder.

invariant

	visible_count_non_negative: visible_line_count >=
		0

end
