class PB_TIMING_RENDERER
	-- Decorates a renderer with elapsed time and ETA.

inherit

	PB_PROGRESS_RENDERER

create

	make

feature {NONE} -- Initialization

	make (a_renderer: PB_PROGRESS_RENDERER)
			-- Initialize a timing decorator.
		do
			renderer := a_renderer
			create clock.make
			clock.start
		ensure
			renderer_set: renderer = a_renderer
			clock_started: clock.is_started
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Render the wrapped line with elapsed time and ETA.
		local
			elapsed: INTEGER_64
		do
			elapsed := clock.elapsed_seconds
			Result := renderer.format_line (a_progress_bar)
			Result.append_character (' ')
			Result.append (format_duration (elapsed))
			Result.append_string_general (" ETA ")
			if a_progress_bar.has_total and then a_progress_bar.total > 0 and then a_progress_bar.absolute_progress > 0 then
				Result.append (format_duration (eta_seconds (a_progress_bar, elapsed)))
			else
				Result.append_string_general ("--:--:--")
			end
		end

feature {NONE} -- Implementation

	renderer: PB_PROGRESS_RENDERER

	clock: PB_CLOCK_IMP

	eta_seconds (a_progress_bar: PB_PROGRESS_BAR; a_elapsed: INTEGER_64): INTEGER_64
			-- Estimated seconds remaining.
		local
			remaining: INTEGER_64
		do
			remaining := a_progress_bar.total - a_progress_bar.absolute_progress
			if remaining > 0 then
				Result := (remaining * a_elapsed) // a_progress_bar.absolute_progress
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
			-- Append `a_value' with at least two digits.
		do
			if a_value < 10 then
				a_result.append_character ('0')
			end
			a_result.append_integer_64 (a_value)
		end

end
