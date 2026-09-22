class PB_CHARGING_PROGRESS_RENDERER

inherit

	PB_BLOCK_PROGRESS_RENDERER

feature {NONE}

	phases: STRING_32 = "%/9608/"

	empty_symbol: CHARACTER_32 = '%/8729/'

	uses_percentage: BOOLEAN
		do
			Result := True
		end

end
