class PB_UNICODE_PROGRESS_RENDERER

inherit

	PB_BLOCK_PROGRESS_RENDERER
		redefine
			bar_width
		end

feature

feature {NONE} -- Implementation

	bar_width: INTEGER
		do
			Result := 20
		end

	phases: STRING_32 = "%/9615/%/9614/%/9613/%/9612/%/9611/%/9610/%/9609/%/9608/"

	empty_symbol: CHARACTER_32 = '%/9617/'

	uses_percentage: BOOLEAN
		do
			Result := True
		end

end
