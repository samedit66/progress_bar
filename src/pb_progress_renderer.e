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

	append_timing (a_result: STRING_32; a_progress_bar: PB_PROGRESS_BAR)
			-- Append elapsed time and ETA to `a_result`.
		do
			a_result.append_character (' ')
			a_result.append (format_duration (a_progress_bar.elapsed_seconds))
			a_result.append_string_general (" ETA ")
			if a_progress_bar.has_eta then
				a_result.append (format_duration (a_progress_bar.eta_seconds))
			else
				a_result.append_string_general ("--:--:--")
			end
		end

	format_duration (a_seconds: INTEGER_64): STRING_32
			-- Format seconds as HH:MM:SS.
		local
			hours, minutes, seconds: INTEGER_64
		do
			hours := a_seconds // 3600
			minutes := (a_seconds \\ 3600) // 60
			seconds := a_seconds \\ 60
			create Result.make (8)
			append_two_digits (Result, hours)
			Result.append_character (':')
			append_two_digits (Result, minutes)
			Result.append_character (':')
			append_two_digits (Result, seconds)
		end

	append_two_digits (a_result: STRING_32; a_value: INTEGER_64)
			-- Append `a_value` with at least two digits.
		do
			if a_value < 10 then
				a_result.append_character ('0')
			end
			a_result.append_integer_64 (a_value)
		end

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
				emit (create {STRING_32}.make_filled (Blank.to_character_8, l.count))
				return_carriage
			end
		end

	print_line (a_string: READABLE_STRING_GENERAL)
			-- A shorthand for printing a string to the console with a new line after it.
		local
			line: STRING_32
		do
			create line.make_from_string_general (a_string)
			line.append_character ('%N')
			emit (line)
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
