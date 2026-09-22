class PB_CAPTURE_MULTIPLE_RENDERER
	-- Exercise the real grouped renderer while retaining terminal output.

inherit

	PB_MULTIPLE_PROGRESS_RENDERER
		redefine
			make,
			emit
		end

create

	make

feature {NONE} -- Initialization

	make (a_bars: ITERABLE [PB_PROGRESS_BAR])
		do
			create captured.make_empty
			Precursor (a_bars)
		end

feature -- Access

	captured: STRING_32

feature -- Commands

	reset
		do
			captured.wipe_out
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_GENERAL)
		do
			captured.append_string_general (a_text)
		end

end
