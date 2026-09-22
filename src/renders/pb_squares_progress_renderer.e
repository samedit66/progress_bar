class PB_SQUARES_PROGRESS_RENDERER

inherit

	PB_BLOCK_PROGRESS_RENDERER

feature {NONE}

	phases: STRING_32 = "%/9635/"

	empty_symbol: CHARACTER_32 = '%/9634/'

	uses_percentage: BOOLEAN
		do
			Result := True
		end

end
