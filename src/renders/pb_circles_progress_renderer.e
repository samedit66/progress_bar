class PB_CIRCLES_PROGRESS_RENDERER

inherit

	PB_BLOCK_PROGRESS_RENDERER

feature {NONE}

	phases: STRING_32 = "%/9673/"

	empty_symbol: CHARACTER_32 = '%/9711/'

	uses_percentage: BOOLEAN
		do
			Result := True
		end

end
