class PB_PROGRESS_BAR
	-- A basic manually controlled progress bar.

create

	make_unknown,
	make_with_total

feature {NONE} -- Initialization

	make_unknown
			-- Make a bar with unknown total.
			-- Same as calling `make_with_total (-1)`.
		do
			make_with_total (-1)
		end

	make_with_total (a_total: INTEGER_64)
			-- Make a bar with a known total.
			-- Accepts any non-negative integer as a total.
			-- By convention also accepts `-1` -- this means it's a bar with an unknown total.
		require
			meaningful_total: a_total >= -1
		do
			total := a_total
			create {PB_BASIC_PROGRESS_RENDERER} renderer
		end

feature -- Commands

	advance
			-- Advance the bar by 1.
		do
			advance_by (1)
		end

	advance_by (a_count: INTEGER_64)
			-- Advance the bar within bounds without overflowing; finish at a known total.
		local
			upper: INTEGER_64
		do
			if not has_finished then
				if has_total then
					upper := total
				else
					upper := {INTEGER_64}.max_value
				end
				if a_count > upper - absolute_progress then
					absolute_progress := upper
				elseif a_count < -absolute_progress then
					absolute_progress := 0
				else
					absolute_progress := absolute_progress + a_count
				end
				if has_total and then absolute_progress = total then
					finish
				else
					render
				end
			end
		end

	finish
			-- Force finish the bar.
		do
			if not has_finished then
				has_finished := True
				render
			end
		end

	set_renderer (a_renderer: PB_PROGRESS_RENDERER)
			-- Set a renderer for the bar.
		do
			renderer := a_renderer
		end

	render
			-- Render the bar.
		do
			renderer.render (Current)
		end

	put_line (a_string: READABLE_STRING_GENERAL)
			-- Print `a_string` to the console with a new line after it above the progress bar.
			-- See `PB_PROGRESS_RENDERER.put_line` for details.
		do
			renderer.put_line (a_string)
		end

feature -- Queries

	has_total: BOOLEAN
			-- Has the bar a known total?
		do
			Result := total > -1
		end

	total: INTEGER_64
			-- The total.

	has_finished: BOOLEAN
			-- Has the bar finished?

	absolute_progress: INTEGER_64
			-- Abosule progress.

	renderer: PB_PROGRESS_RENDERER
			-- Attached renderer.

invariant

	unknown_total: not has_total implies total = -1
	valid_total: has_total implies total >= 0
	non_negative_progress: absolute_progress >= 0
	bounded_progress: has_total implies absolute_progress <= total

end
