class PB_PIXEL_PROGRESS_RENDERER

inherit

	PB_BLOCK_PROGRESS_RENDERER

feature {NONE}

	phases: STRING_32 = "%/10304/%/10308/%/10310/%/10311/%/10439/%/10471/%/10487/%/10495/"

	empty_symbol: CHARACTER_32 = ' '

	uses_percentage: BOOLEAN
		do
			Result := False
		end

end
