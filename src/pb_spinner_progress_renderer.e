class PB_SPINNER_PROGRESS_RENDERER
	-- Renderer for progress with an unknown total.

inherit

	PB_PROGRESS_RENDERER

create

	make

feature -- Initialization

	make
			-- Initialize a phase-based spinner.
		do
			create phases.make_from_string (default_phases)
			show_count := False
			show_elapsed := False
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Format the current phase and optional progress details.
		local
			index: INTEGER
		do
			index := (a_progress_bar.absolute_progress \\ phases.count).to_integer_32 + 1
			create Result.make (phases.count + 32)
			if not a_progress_bar.description.is_empty then
				Result.append (a_progress_bar.description)
				Result.extend (' ')
			end
			Result.extend (phases [index])
			if show_count then
				Result.append_string_general (" " + a_progress_bar.absolute_progress.out)
			end
			if show_elapsed then
				Result.append_character (' ')
				Result.append (format_duration (a_progress_bar.elapsed_seconds))
			end
		end

feature -- Settings

	set_phases (a_phases: READABLE_STRING_GENERAL)
			-- Set the sequence of characters used by the spinner.
		require
			not_empty: not a_phases.is_empty
		do
			phases := a_phases.as_string_32
		end

	set_show_count (a_show_count: BOOLEAN)
			-- Choose whether to display the current progress count.
		do
			show_count := a_show_count
		end

	set_show_elapsed (a_show_elapsed: BOOLEAN)
			-- Choose whether to display elapsed time.
		do
			show_elapsed := a_show_elapsed
		end

feature {NONE} -- Implementation

	default_phases: STRING_32 = "%/9681/%/9682/%/9680/%/9683/"
			-- Default spinner phases: ◑◒◐◓.

	phases: STRING_32
			-- Ordered spinner phases.

	show_count: BOOLEAN
			-- Should the current progress count be displayed?

	show_elapsed: BOOLEAN
			-- Should elapsed time be displayed?

end
