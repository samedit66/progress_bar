class PB_DISPLAY
	-- Displays a fixed ordered set of progress bars.

create

	make

feature {NONE} -- Initialization

	make
			-- Create an empty display.
		do
			create bars.make (0)
		end

feature -- Commands

	extend (a_bar: PB_PROGRESS_BAR)
			-- Add `a_bar` to the display in the current order.
		do
			a_bar.set_display (Current)
			bars.extend (a_bar)
		end

	render
			-- Redraw all bars in their display order.
		do
			if not bars.is_empty then
				clear_block
				across
					bars
				as
					bar
				loop
					emit (bar.formatted + "%N")
				end
				displayed := True
			end
		end

	put_line (a_text: READABLE_STRING_GENERAL)
			-- Print `a_text` above the displayed bars and redraw them.
		do
			clear_block
			emit (a_text.as_string_32 + "%N")
			render
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_GENERAL)
			-- Write `a_text` to the display output.
		do
			io.put_string_32 (a_text.as_string_32)
		end

	clear_block
			-- Move the cursor above the previously displayed block.
		do
			if displayed then
				emit ("%/27/[" + bars.count.out + "A")
			end
		end

feature {NONE} -- Implementation

	bars: ARRAYED_LIST [PB_PROGRESS_BAR]
			-- Bars shown by this display.

	displayed: BOOLEAN
			-- Has this display written its first block?

end
