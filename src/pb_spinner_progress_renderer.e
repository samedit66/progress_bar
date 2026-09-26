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
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Format the current phase and progress counter.
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
			Result.append_string_general (" " + a_progress_bar.absolute_progress.out)
			append_timing (Result, a_progress_bar)
		end

feature -- Settings

	set_phases (a_phases: READABLE_STRING_GENERAL)
			-- Set the sequence of characters used by the spinner.
		require
			not_empty: not a_phases.is_empty
		do
			phases := a_phases.as_string_32
		end

feature {NONE} -- Implementation

	default_phases: STRING_32 = "%/124/%/47/%/45/%/92/"
			-- Default spinner phases: |/-\.

	phases: STRING_32
			-- Ordered spinner phases.

end
