class PB_SPINNER_PROGRESS_RENDERER
	-- Renderer for compact phase and value progress displays.

inherit

	PB_PROGRESS_RENDERER

create

	make

feature -- Initialization

	make
			-- Initialize a phase-based spinner.
		do
			create phases.make_from_string (default_phases)
			show_phase := True
			show_count := False
			show_remaining := False
			show_elapsed := False
		end

feature -- Formatting

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Format the current phase and optional progress details.
		local
			index: INTEGER
			value: INTEGER_64
		do
			create Result.make (phases.count + 32)
			if not a_progress_bar.description.is_empty then
				Result.append (a_progress_bar.description)
			end
			if show_phase then
				append_separator (Result)
				index := (a_progress_bar.absolute_progress \\ phases.count).to_integer_32 + 1
				Result.extend (phases [index])
			end
			if show_remaining then
				append_separator (Result)
				if a_progress_bar.has_total then
					value := a_progress_bar.progress_limit - a_progress_bar.absolute_progress
					Result.append_string_general (value.out + " left")
				else
					Result.append_string_general ("? left")
				end
			elseif show_count then
				append_separator (Result)
				Result.append_string_general (a_progress_bar.absolute_progress.out)
			end
			if show_elapsed then
				append_separator (Result)
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

	set_show_phase (a_show_phase: BOOLEAN)
			-- Choose whether to display the current phase.
		do
			show_phase := a_show_phase
		end

	set_show_count (a_show_count: BOOLEAN)
			-- Choose whether to display the current progress count.
		do
			show_count := a_show_count
			if a_show_count then
				show_remaining := False
			end
		end

	set_show_remaining (a_show_remaining: BOOLEAN)
			-- Choose whether to display remaining work instead of the count.
		do
			show_remaining := a_show_remaining
			if a_show_remaining then
				show_count := False
			end
		end

	set_show_elapsed (a_show_elapsed: BOOLEAN)
			-- Choose whether to display elapsed time.
		do
			show_elapsed := a_show_elapsed
		end

feature {NONE} -- Implementation

	append_separator (a_result: STRING_32)
			-- Append a separator when the result already contains text.
		do
			if not a_result.is_empty then
				a_result.extend (' ')
			end
		end

	default_phases: STRING_32 = "%/9681/%/9682/%/9680/%/9683/"
			-- Default spinner phases: ◑◒◐◓.

	phases: STRING_32
			-- Ordered spinner phases.

	show_phase: BOOLEAN
			-- Should the current phase be displayed?

	show_count: BOOLEAN
			-- Should the current progress count be displayed?

	show_remaining: BOOLEAN
			-- Should remaining work be displayed instead of the count?

	show_elapsed: BOOLEAN
			-- Should elapsed time be displayed?

end
