class PB_UNICODE_PROGRESS_RENDERER

inherit

	PB_PROGRESS_RENDERER

feature

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
		local
			ratio: REAL_64
			units, full_cells, remainder, i: INTEGER
			partial_blocks: STRING_32
		do
			if not a_progress_bar.has_total then
				Result := "[" + a_progress_bar.absolute_progress.out + "/?]"
			else
				if a_progress_bar.total = 0 then
					ratio := 1.0
				else
					ratio := a_progress_bar.absolute_progress / a_progress_bar.total
				end
				units := (ratio * (Width * 8)).floor
				full_cells := units // 8
				remainder := units \\ 8
				partial_blocks := {STRING_32} "%/9615/%/9614/%/9613/%/9612/%/9611/%/9610/%/9609/"
				create Result.make (Width + 8)
				Result.append_string_general ("[")
				from
					i := 1
				until
					i > Width
				loop
					if i <= full_cells then
						Result.extend ('%/9608/')
					elseif i = full_cells + 1 and remainder > 0 then
						Result.extend (partial_blocks [remainder])
					else
						Result.extend ('%/9617/')
					end
					i := i + 1
				end
				Result.append_string_general ("] ")
				Result.append_string_general ((ratio * 100).floor.out)
				Result.append_string_general ("%%")
			end
		end

feature {NONE} -- Implementation

	Width: INTEGER = 20

end
