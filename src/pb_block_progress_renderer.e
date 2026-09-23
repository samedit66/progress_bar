deferred class PB_BLOCK_PROGRESS_RENDERER
	-- Common renderer for fixed-width bars built from repeated block symbols.
	-- Descendants provide the symbols and choose between percentage and counter output.

inherit

	PB_PROGRESS_RENDERER

feature

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
			-- Format the current progress as a block bar or an unknown-total counter.
		local
			ratio: REAL_64
			units, full_cells, remainder, i: INTEGER
		do
			if not a_progress_bar.has_total then
				Result := "[" + a_progress_bar.absolute_progress.out + "/?]"
			else
				if a_progress_bar.total = 0 then
					ratio := 1.0
				else
					ratio := a_progress_bar.absolute_progress / a_progress_bar.total
				end
				units := (ratio * (bar_width * phases.count)).floor
				full_cells := units // phases.count
				remainder := units \\ phases.count
				create Result.make (bar_width + 16)
				Result.extend ('[')
				from
					i := 1
				until
					i > bar_width
				loop
					if i <= full_cells then
						Result.extend (phases [phases.count])
					elseif i = full_cells + 1 and remainder > 0 then
						Result.extend (phases [remainder])
					else
						Result.extend (empty_symbol)
					end
					i := i + 1
				end
				if uses_percentage then
					Result.append_string_general ("] " + (ratio * 100).floor.out + "%%")
				else
					Result.append_string_general ("] " + a_progress_bar.absolute_progress.out + "/" + a_progress_bar.total.out)
				end
			end
		end

feature {NONE} -- Implementation

	Width: INTEGER = 32
			-- Number of character cells in the rendered bar.

	bar_width: INTEGER
			-- Number of character cells used by this renderer.
		do
			Result := Width
		end

	phases: STRING_32
			-- Ordered symbols from the least to the most filled cell.
		deferred
		end

	empty_symbol: CHARACTER_32
			-- Symbol used for an empty cell.
		deferred
		end

	uses_percentage: BOOLEAN
			-- Should a known total be displayed as a percentage instead of a counter?
		deferred
		end

end
