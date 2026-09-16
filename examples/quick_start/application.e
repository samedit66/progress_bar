note

	description:

		"Demonstrate manual progress, automatic traversal, and nested step bars."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class APPLICATION

create

	make

feature {NONE} -- Initialization

	make
			-- Run complete examples of the public API.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
			items: ARRAYED_LIST [STRING]
			progress: PB_ITERABLE [STRING]
			files, parts: PB_STEP_BAR
			processed_parts: INTEGER
		do
			create formatters
			create bar.make_with_total (10)
			bar.set_line_formatter (formatters.standard ("Manual", "steps", "done"))
			from
				bar.start
			until
				bar.is_finished
			loop
				bar.forth
			end
			create bar.make_unknown
			bar.set_line_formatter (formatters.standard ("Unknown", "items", "done"))
			bar.start
			bar.forth_by (4)
			bar.pulse
			bar.finish
			create bar.make_with_total (100)
			bar.set_line_formatter (formatters.standard ("Stopped early", "items", ""))
			bar.set_progress (40)
			bar.finish
			create items.make (3)
			items.extend ("parse")
			items.extend ("analyze")
			items.extend ("emit")
			create progress.make_over (items)
			progress.set_line_formatter (formatters.standard ("Pipeline", "stages", "done"))
			across
				progress
			as
				item
			loop
				progress.put_line ("Processed " + item)
			end
			create files.make_with_total (3)
			files.set_line_formatter (formatters.standard ("Files", "files", "done"))
			create parts.make_with_total (2)
			parts.set_display (files.display)
			parts.set_line_formatter (formatters.standard ("  Parts", "parts", "done"))
			across
				files
			as
				file_number
			loop
				across
					parts
				as
					part_number
				loop
					processed_parts := processed_parts + 1
					parts.put_line ("File " + file_number.out + ", part " + part_number.out)
				end
			end
			files.put_line ("Processed " + processed_parts.out + " parts")
		end

end
