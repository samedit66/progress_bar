class APPLICATION

create

	make

feature {NONE} -- Initialization

	make
		do
				-- Show a manually controlled progress bar with a known total.
			known_progress
				-- Show progress that follows an iterable.
			wrapped_progress
				-- Show a message above an active progress bar.
			progress_messages
				-- Show several progress bars at the same time.
			multiple_progress
				-- Show the built-in Unicode renderer.
			unicode_progress
		end

feature {NONE} -- Examples

	known_progress
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (3)
			from
			until
				bar.has_finished
			loop
				bar.advance
			end
		end

	wrapped_progress
		local
			bar: PB_WRAPPED_BAR [STRING]
		do
			create bar.wrap (<<"first", "second", "third">>)
			across
				bar
			as
				item
			loop
				bar.put_line ("Processed: " + item)
			end
		end

	progress_messages
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (3)
			from
			until
				bar.has_finished
			loop
				if bar.absolute_progress = 1 then
					bar.put_line ("Reached the first milestone")
				end
				bar.advance
			end
		end

	multiple_progress
		local
			first, second: PB_PROGRESS_BAR
			group: PB_MULTIPLE_PROGRESS_RENDERER
		do
			create first.make_with_total (2)
			create second.make_with_total (3)
			create group.make (<<first, second>>)
			from
			until
				first.has_finished and second.has_finished
			loop
				if not first.has_finished then
					first.advance
				end
				if not second.has_finished then
					second.advance_by (2)
				end
			end
		end

	unicode_progress
		local
			bar: PB_PROGRESS_BAR
		do
			create bar.make_with_total (3)
			bar.set_renderer (create {PB_UNICODE_PROGRESS_RENDERER})
			from
			until
				bar.has_finished
			loop
				bar.advance
			end
		end

end
