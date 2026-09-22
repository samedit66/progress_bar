deferred class PB_PROGRESS_RENDERER
	-- Abstract progress bar renderer.
	-- Renders current state of a progress bar to the console.
	-- Descendants must implement `format_line` to provide a string representation of the current state of a progress bar.
	-- They may also override `emit` to specify a different place to print the progress bar out.

inherit

	ASCII

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Return a string representation of the current state of `a_progress_bar`.
		deferred
		end

feature -- Rendering

	render (a_progress_bar: PB_PROGRESS_BAR)
			-- Render the current state of `a_progress_bar` to the console.
			-- Calls `format_line` on a given progress bar and prints the result to the console.
			-- When the progress bar has finished, prints a new line after the progress bar.
			-- Nothing happens if the progress bar has already finished.
		local
			rendered_line: STRING_32
		do
			if not bar_finished then
				return_carriage
				rendered_line := format_line (a_progress_bar)
				if attached last_line as l then
					pad_with (rendered_line, Blank.to_character_32, l.count)
				end
				emit (rendered_line)
				last_line := rendered_line
				if a_progress_bar.has_finished then
					emit ("%N")
					bar_finished := True
				end
			end
		end

	put_line (a_string: READABLE_STRING_GENERAL)
			-- Print `a_string` to the console with a new line after it above the progress bar.
			-- Exists because a call to `print` (from `ANY`) or `io.put_string` will damage the progress bar.
		do
			if not bar_finished then
				clear_current_line
				print_line (a_string)
				if attached last_line as l then
					emit (l)
				end
			end
		end

feature {NONE} -- Output

	emit (a_string: READABLE_STRING_GENERAL)
			-- Write terminal output; descendants may redirect it.
		do
			io.put_string_32 (a_string.as_string_32)
		end

feature {NONE} -- Implementation

	bar_finished: BOOLEAN
			-- Indicates whether the progress bar has finished.

	last_line: detachable STRING_32
			-- The last line printed to the console by this renderer.
			-- `Void` if nothing has been printed yet.

	return_carriage
			-- Print a carriage return to the console.
		do
			emit ("%R")
		end

	clear_current_line
			-- Clear the current line in the console.
		do
			if attached last_line as l then
				return_carriage
				emit (create {STRING_32}.make_filled (Blank.to_character, l.count))
				return_carriage
			end
		end

	print_line (a_string: READABLE_STRING_GENERAL)
			-- A shorthand for printing a string to the console with a new line after it.
		do
			emit (a_string + "%N")
		end

	pad_with (a_string: STRING_32; a_character: CHARACTER_32; a_length: INTEGER)
			-- Pad `a_string` with `a_character` until it is at least `a_length` characters long.
		require
			length_non_negative: a_length >= 0
		do
			from
			until
				a_string.count >= a_length
			loop
				a_string.extend (a_character)
			end
		end

end
