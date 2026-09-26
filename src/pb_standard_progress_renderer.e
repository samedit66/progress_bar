class PB_STANDARD_PROGRESS_RENDERER
	-- Configurable renderer for known and unknown progress.

inherit

	PB_PROGRESS_RENDERER

create

	make

feature -- Initialization

	make
			-- Initialize the standard renderer.
		do
			width := 20
			fill_character := '#'
			empty_character := ' '
			show_percentage := True
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Format a progress bar with description and timing information.
		local
			filled, i: INTEGER
		do
			create Result.make (width + 32)
			if not a_progress_bar.description.is_empty then
				Result.append (a_progress_bar.description)
				Result.extend (' ')
			end
			if not a_progress_bar.has_total then
				Result.append_string_general ("[" + a_progress_bar.absolute_progress.out + "/?]")
			else
				filled := (a_progress_bar.progress_ratio * width).floor
				Result.extend ('[')
				from
					i := 1
				until
					i > width
				loop
					if i <= filled then
						Result.extend (fill_character)
					else
						Result.extend (empty_character)
					end
					i := i + 1
				end
				Result.extend (']')
				if show_percentage then
					Result.append_string_general (" " + a_progress_bar.progress_percentage.out + "%%")
				else
					Result.append_string_general (" " + a_progress_bar.absolute_progress.out + "/" + a_progress_bar.progress_limit.out)
				end
			end
			append_timing (Result, a_progress_bar)
		end

feature -- Settings

	set_width (a_width: INTEGER)
			-- Set the number of cells used by the bar.
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

	set_show_percentage (a_show_percentage: BOOLEAN)
			-- Choose percentage instead of a counter for known progress.
		do
			show_percentage := a_show_percentage
		end

feature {NONE} -- Implementation

	width: INTEGER
			-- Number of cells used by the bar.

	fill_character: CHARACTER_32
			-- Character used for completed cells.

	empty_character: CHARACTER_32
			-- Character used for incomplete cells.

	show_percentage: BOOLEAN
			-- Should known progress be displayed as a percentage?

end
