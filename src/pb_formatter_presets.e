class PB_FORMATTER_PRESETS
	-- Factory features for common standard formatter styles.

feature -- Standard formatters

	standard: PB_FORMATTER
			-- Create a formatter with the default style.
		do
			create Result.make
			Result.set_show_phases (False)
			Result.set_show_elapsed (True)
		ensure
			instance_free: class
		end

	squares: PB_FORMATTER
			-- Create a formatter using square characters.
		do
			Result := standard
			Result.set_fill_character ('%/9635/')
			Result.set_empty_character ('%/9634/')
		ensure
			instance_free: class
		end

	circles: PB_FORMATTER
			-- Create a formatter using circle characters.
		do
			Result := standard
			Result.set_fill_character ('%/9673/')
			Result.set_empty_character ('%/9711/')
		ensure
			instance_free: class
		end

	pixels: PB_FORMATTER
			-- Create a formatter using pixel characters.
		do
			Result := standard
			Result.set_fill_character ('%/10495/')
			Result.set_empty_character (' ')
		ensure
			instance_free: class
		end

	unicode: PB_FORMATTER
			-- Create a formatter using Unicode block characters.
		do
			Result := standard
			Result.set_fill_character ('%/9608/')
			Result.set_empty_character ('%/9617/')
		ensure
			instance_free: class
		end

feature -- Spinner formatters

	counter: PB_FORMATTER
			-- Create a formatter showing the current progress count.
		do
			create Result.make
			Result.set_show_phases (False)
			Result.set_show_count (True)
		ensure
			instance_free: class
		end

	countdown: PB_FORMATTER
			-- Create a formatter showing the remaining progress count.
		do
			create Result.make
			Result.set_show_phases (False)
			Result.set_show_percentage (False)
			Result.set_show_remaining (True)
		ensure
			instance_free: class
		end

	spinner: PB_FORMATTER
			-- Create a formatter using ASCII spinner phases.
		do
			create Result.make
			Result.set_phases ("%/45/%/92/%/124/%/47/")
		ensure
			instance_free: class
		end

	pie_spinner: PB_FORMATTER
			-- Create a formatter using pie spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9719/%/9718/%/9717/%/9716/")
		ensure
			instance_free: class
		end

	moon_spinner: PB_FORMATTER
			-- Create a formatter using moon spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9681/%/9682/%/9680/%/9683/")
		ensure
			instance_free: class
		end

	line_spinner: PB_FORMATTER
			-- Create a formatter using line spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9146/%/9147/%/9148/%/9149/%/9148/%/9147/")
		ensure
			instance_free: class
		end

	pixel_spinner: PB_FORMATTER
			-- Create a formatter using Braille pixel phases.
		do
			create Result.make
			Result.set_phases ("%/10494/%/10487/%/10479/%/10463/%/10367/%/10431/%/10491/%/10493/")
		ensure
			instance_free: class
		end

feature -- Compact standard formatters

	stack: PB_FORMATTER
			-- Create a formatter showing progress as one stack glyph.
		do
			Result := standard
			Result.set_phases ("%/32/%/9601/%/9602/%/9603/%/9604/%/9605/%/9606/%/9607/%/9608/")
			Result.set_show_phases (True)
		ensure
			instance_free: class
		end

end
