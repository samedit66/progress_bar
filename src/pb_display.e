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
			clear_block
			render_bars
		end

	put_line (a_text: READABLE_STRING_GENERAL)
			-- Print `a_text` above the displayed bars and redraw them.
			-- Safe to call even when no bars are currently on the screen.
		do
			clear_block
			clear_line
			emit (a_text.as_string_32 + "%N")
			render_bars
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_GENERAL)
			-- Write `a_text` to the display output.
		do
			io.put_string_32 (a_text.as_string_32)
		end

	clear_block
			-- Move the cursor above the previously displayed block.
			-- Safe to call when no bars were rendered earlier: nothing happens.
		do
			if displayed then
				emit ("%/27/[" + bars.count.out + "A")
			end
		end

	clear_line
			-- Erase the current terminal row and return to its beginning.
		do
			emit ("%/27/[2K%/13/")
		end

	render_bars
			-- Write all bars without moving the cursor first.
			-- Nothing happens when no bars are attached to the display.
		do
			if not bars.is_empty then
				across
					bars
				as
					bar
				loop
					clear_line
					emit (bar.formatted + "%N")
				end
				displayed := True
			end
		end

feature {NONE} -- Implementation

	bars: ARRAYED_LIST [PB_PROGRESS_BAR]
			-- Bars shown by this display.

	displayed: BOOLEAN
			-- Has this display written its first block?

end
