class PB_CAPTURE_RENDERER
	-- Exercise the real single-line renderer while retaining terminal output.

inherit

	PB_STANDARD_PROGRESS_RENDERER
		redefine
			make,
			emit
		end

create

	make

feature {NONE} -- Initialization

	make
		do
			Precursor
			create captured.make_empty
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
