class PB_FORMATTER
	-- Formats known and unknown progress bars as one physical line.

create

	make

feature {NONE} -- Initialization

	make
			-- Create a formatter with the standard progress-bar style.
		do
			phases := "%/9681/%/9682/%/9680/%/9683/"
			width := 20
			fill_character := '#'
			empty_character := ' '
			show_phases := True
			show_percentage := True
		end

feature -- Settings

	set_width (a_width: INTEGER)
			-- Set the number of cells used for known progress.
		require
			positive_width: a_width > 0
		do
			width := a_width
		end

	set_fill_character (a_character: CHARACTER_32)
			-- Set the character used for completed cells.
		do
			fill_character := a_character
		end

	set_empty_character (a_character: CHARACTER_32)
			-- Set the character used for incomplete cells.
		do
			empty_character := a_character
		end

	set_phases (a_phases: READABLE_STRING_GENERAL)
			-- Set the phase characters used by spinner and compact styles.
		require
			not_empty: not a_phases.is_empty
		do
			phases := a_phases.as_string_32
		end

	set_show_phases (a_show: BOOLEAN)
			-- Use one phase character instead of a cell bar.
		do
			show_phases := a_show
		end

	set_show_percentage (a_show: BOOLEAN)
			-- Show percentage instead of `count/total`.
		do
			show_percentage := a_show
		end

	set_show_remaining (a_show: BOOLEAN)
			-- Show remaining work instead of the count.
		do
			show_remaining := a_show
		end

	set_show_count (a_show: BOOLEAN)
			-- Show the current count for unknown progress.
		do
			show_count := a_show
		end

	set_show_elapsed (a_show: BOOLEAN)
			-- Show elapsed time after the progress value.
		do
			show_elapsed := a_show
		end

feature -- Formatting

	format (a_bar: PB_PROGRESS_BAR): STRING_32
			-- Return the current state of `a_bar` as one line.
		do
			create Result.make (width + 32)
			if not a_bar.description.is_empty then
				Result.append (a_bar.description)
				Result.append_character (' ')
			end
			if a_bar.has_total then
				format_known (Result, a_bar)
			else
				format_unknown (Result, a_bar)
			end
			if show_elapsed then
				append_timing (Result, a_bar)
			end
		end

feature {NONE} -- Formatting details

	format_known (a_result: STRING_32; a_bar: PB_PROGRESS_BAR)
		do
			if show_phases then
				a_result.append_character (phases [phase_index (a_bar)])
			elseif not show_remaining then
				a_result.append_character ('[')
				append_n_character (a_result, (width * a_bar.progress_ratio).floor, fill_character)
				append_n_character (a_result, (width * (1 - a_bar.progress_ratio)).floor, empty_character)
				a_result.append_character (']')
			end
			if not (show_remaining and not show_phases) then
				a_result.append_character (' ')
			end
			if show_percentage then
				a_result.append_string_general (a_bar.progress_percentage.out + "%%")
			elseif show_remaining then
				a_result.append_string_general ((a_bar.progress_limit - a_bar.absolute_progress).out + " left")
			else
				a_result.append_string_general (a_bar.absolute_progress.out + "/" + a_bar.progress_limit.out)
			end
		end

	format_unknown (a_result: STRING_32; a_bar: PB_PROGRESS_BAR)
		do
			if show_phases then
				a_result.append_character (phases [phase_index (a_bar)])
			end
			if show_count then
				if not a_result.is_empty and a_result [a_result.count] /= ' ' then
					a_result.append_character (' ')
				end
				a_result.append_string_general (a_bar.absolute_progress.out)
			elseif show_remaining then
				a_result.append_string_general ("? left")
			end
		end

	phase_index (a_bar: PB_PROGRESS_BAR): INTEGER
		do
			if a_bar.has_total then
				Result := (a_bar.progress_ratio * (phases.count - 1)).floor + 1
			else
				Result := (a_bar.absolute_progress \\ phases.count).to_integer_32 + 1
			end
		end

	append_timing (a_result: STRING_32; a_bar: PB_PROGRESS_BAR)
		do
			a_result.append_character (' ')
			a_result.append (format_duration (a_bar.elapsed_seconds))
			if a_bar.has_eta then
				a_result.append_string_general (" ETA ")
				a_result.append (format_duration (a_bar.eta_seconds))
			end
		end

	format_duration (a_seconds: INTEGER_64): STRING_32
			-- Format seconds as `HH:MM:SS`.
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
		do
			if a_value < 10 then
				a_result.append_character ('0')
			end
			a_result.append_integer_64 (a_value)
		end

	append_n_character (a_result: STRING_32; a_count: INTEGER_64; a_character: CHARACTER_32)
		local
			i: INTEGER_64
		do
			from
				i := 1
			until
				i > a_count
			loop
				a_result.append_character (a_character)
				i := i + 1
			end
		end

feature {NONE} -- Settings

	phases: STRING_32
			-- Characters used for phase-based progress.

	width: INTEGER
			-- Number of cells used for a known-total bar.

	fill_character: CHARACTER_32
			-- Character used for completed cells.

	empty_character: CHARACTER_32
			-- Character used for incomplete cells.

	show_phases: BOOLEAN
			-- Use one phase character instead of a cell bar.

	show_percentage: BOOLEAN
			-- Show percentage instead of `count/total`.

	show_remaining: BOOLEAN
			-- Show remaining work instead of the count.

	show_count: BOOLEAN
			-- Show the current count for unknown progress.

	show_elapsed: BOOLEAN
			-- Append elapsed time after the progress value.

end
