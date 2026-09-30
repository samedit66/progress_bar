class PB_PROGRESS_BAR
	-- A basic manually controlled progress bar.

create

	make_unknown,
	make_with_total

feature {NONE} -- Initialization

	make_with_total (a_total: INTEGER_64)
			-- Make a progress bar with a known total.
		require
			valid_total: a_total >= 0
		do
			initialize (a_total, True)
		ensure
			total_set: progress_limit = a_total
			total_is_known: has_total
			not_finished: not has_finished
			no_progress_made_so_far: absolute_progress = 0
		end

	make_unknown
			-- Make a progress bar without a known total.
		do
			initialize ({INTEGER_64}.max_value, False)
		ensure
			unknown_total: not has_total
			maximum_progress_limit: progress_limit = {INTEGER_64}.max_value
			not_finished: not has_finished
			no_progress_made_so_far: absolute_progress = 0
		end

	initialize (a_limit: INTEGER_64; a_has_total: BOOLEAN)
		do
			progress_limit := a_limit
			has_total := a_has_total
			create description.make_empty
			create {PB_CLOCK_IMP} clock.make
			clock.start
			formatter := {PB_FORMATTER_PRESETS}.standard
			create display.make
			display.extend (Current)
		end

feature -- Commands

	advance
			-- Advance the bar by 1.
		do
			advance_by (1)
		end

	advance_by (a_count: INTEGER_64)
			-- Advance by `a_count`, saturating progress at zero and its limit.
			-- A known-total bar finishes automatically when it reaches its limit.
		local
			remaining: INTEGER_64
		do
			if not has_finished then
				remaining := progress_limit - absolute_progress
				if a_count > remaining then
					absolute_progress := progress_limit
				elseif a_count < -absolute_progress then
					absolute_progress := 0
				else
					absolute_progress := (absolute_progress + a_count).max (0)
				end
				if has_total and then absolute_progress = progress_limit then
					finish
				else
					render
				end
			end
		ensure
			non_negative_progress: absolute_progress >= 0
			progress_within_limit: absolute_progress <= progress_limit
		end

	finish
			-- Finish the bar at its current progress and render it once.
		do
			if not has_finished then
				has_finished := True
				render
			end
		end

	render
			-- Render the bar.
		do
			display.render
		end

	put_line (a_string: READABLE_STRING_GENERAL)
			-- Print `a_string` above the progress bar.
		do
			display.put_line (a_string)
		end

	set_description (a_description: READABLE_STRING_GENERAL)
			-- Set the text displayed before the progress bar.
		do
			description := a_description.as_string_32
		end

	set_formatter (a_formatter: PB_FORMATTER)
			-- Set the formatter used for this bar.
		do
			formatter := a_formatter
		end

	set_total (a_total: INTEGER_64)
			-- Set `a_total` as the known progress limit.
		require
			valid_total: a_total >= 0
		do
			progress_limit := a_total
			has_total := True
		end

	set_absolute_progress (a_absolute_progress: INTEGER_64)
			-- Set the current absolute progress without rendering.
		require
			non_negative_progress: a_absolute_progress >= 0
			progress_within_limit: a_absolute_progress <= progress_limit
		do
			absolute_progress := a_absolute_progress
		end

feature -- Status report

	has_total: BOOLEAN
			-- Is the progress limit a known total?

	has_finished: BOOLEAN
			-- Has the bar finished?

	has_eta: BOOLEAN
			-- Is an ETA available for the current progress?
		do
			Result := has_total and then progress_limit > 0 and then absolute_progress > 0
		end

feature -- Measurement

	description: STRING_32
			-- Text displayed before the progress bar.

	elapsed_seconds: INTEGER_64
			-- Whole seconds elapsed since creation.
		do
			Result := clock.elapsed_seconds
		end

	progress_ratio: REAL_64
			-- Progress as a value between 0.0 and 1.0.
		require
			total_is_known: has_total
		do
			if progress_limit = 0 then
				Result := 1.0
			else
				Result := absolute_progress / progress_limit
			end
		ensure
			valid_ratio: Result >= 0.0 and Result <= 1.0
		end

	progress_percentage: INTEGER_64
			-- Progress as a whole percentage between 0 and 100.
		require
			total_is_known: has_total
		do
			Result := (progress_ratio * 100).floor
		ensure
			valid_percentage: Result >= 0 and Result <= 100
		end

	eta_seconds: INTEGER_64
			-- Estimated whole seconds remaining.
		require
			eta_available: has_eta
		local
			remaining: INTEGER_64
		do
			remaining := progress_limit - absolute_progress
			Result := (remaining * elapsed_seconds) // absolute_progress
		end

	progress_limit: INTEGER_64
			-- Maximum possible absolute progress value.

	absolute_progress: INTEGER_64
			-- Absolute progress.

	formatter: PB_FORMATTER
			-- Formatter used to produce the bar's display line.

feature {PB_DISPLAY}

	set_display (a_display: PB_DISPLAY)
			-- Attach the bar to `a_display`.
		do
			display := a_display
		end

	formatted: STRING_32
			-- Return this bar formatted as one display line without writing output.
		do
			Result := formatter.format (Current)
		end

feature {NONE} -- Implementation

	clock: PB_CLOCK
			-- Clock measuring this bar's lifetime.

	display: PB_DISPLAY
			-- Display receiving this bar's output.

invariant

	positive_progress_limit: progress_limit >= 0
	unknown_uses_maximum_limit: not has_total implies progress_limit = {INTEGER_64}.max_value
	non_negative_progress: absolute_progress >= 0
	progress_within_limit: absolute_progress <= progress_limit

end
