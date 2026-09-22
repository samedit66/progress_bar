class PB_MOON_SPINNER_RENDERER

inherit

	PB_PROGRESS_RENDERER

feature

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
		local
			index: INTEGER
		do
			index := (a_progress_bar.absolute_progress \\ phases.count).to_integer_32 + 1
			create Result.make (10)
			Result.append_string_general ("Loading ")
			Result.extend (phases [index])
		end

feature {NONE} -- Implementation

	phases: STRING_32 = "%/9681/%/9682/%/9680/%/9683/"

end
