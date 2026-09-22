class PB_BASIC_PROGRESS_RENDERER

inherit

	PB_PROGRESS_RENDERER

feature

	format_line (a_progress_bar: PB_PROGRESS_BAR): STRING_32
		do
			if a_progress_bar.has_total then
				Result := "[" + (a_progress_bar.absolute_progress.out + "/" + a_progress_bar.total.out) + "]"
			else
				Result := "[" + (a_progress_bar.absolute_progress.out + "/?") + "]"
			end
		end

end
