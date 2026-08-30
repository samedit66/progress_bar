note

	description:

		"One progress line owned and ordered by a PB_DISPLAY."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_DISPLAY_LINE

create {PB_DISPLAY}

	make

feature {NONE} -- Initialization

	make (a_parent: detachable PB_DISPLAY_LINE)
			-- Create a pending line below `a_parent`, if supplied.
		do
			parent := a_parent
		end

feature {PB_DISPLAY, PB_DISPLAY_LINE} -- Access

	parent: detachable PB_DISPLAY_LINE
			-- Parent line in the display hierarchy, if any.

	text: detachable STRING_32
			-- Most recently rendered text, if Current has become visible.

feature {PB_DISPLAY, PB_BAR} -- Status report

	is_closed: BOOLEAN
			-- Has the owner finished this line?

	is_visible: BOOLEAN
			-- Does Current occupy a terminal row?
		do
			Result :=
				attached text and then
					(not is_closed or else
						keeps_final_line)
		end

	keeps_final_line: BOOLEAN
			-- Should the closed line remain visible until the display becomes idle?

	is_descendant_of (a_line: PB_DISPLAY_LINE): BOOLEAN
			-- Is Current nested below `a_line`?
		local
			candidate: detachable PB_DISPLAY_LINE
		do
			from
				candidate := parent
			until
				Result or else
					not attached candidate as attached_candidate
			loop
				if attached_candidate = a_line then
					Result := True
				else
					candidate := attached_candidate.parent
				end
			end
		end

feature {PB_DISPLAY} -- Element change

	set_text (a_text: STRING_32)
			-- Retain a private copy of `a_text`.
		require
			open: not is_closed
		do
			text := a_text.twin
		ensure
			text_set: attached text as stored_text and then
				stored_text.same_string (a_text)
		end

	close (a_text: STRING_32; a_keep_final_line: BOOLEAN)
			-- Close Current with `a_text` and the requested retention policy.
		require
			open: not is_closed
		do
			text := a_text.twin
			keeps_final_line := a_keep_final_line
			is_closed := True
		ensure
			closed: is_closed
			policy_set: keeps_final_line = a_keep_final_line
			text_set: attached text as stored_text and then
				stored_text.same_string (a_text)
		end

end
