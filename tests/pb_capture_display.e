class PB_CAPTURE_DISPLAY
	-- Capture a display's output for tests.

inherit

	PB_DISPLAY
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
			-- Captured display output.

	reset
			-- Discard captured output.
		do
			captured.wipe_out
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_GENERAL)
		do
			captured.append_string_general (a_text)
		end

end
