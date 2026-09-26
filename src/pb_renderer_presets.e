class PB_RENDERER_PRESETS
	-- Factory features for common standard renderer styles.

feature -- Standard renderers

	standard: PB_STANDARD_PROGRESS_RENDERER
			-- Create a renderer with the default style.
		do
			create Result.make
		ensure
			instance_free: class
		end

	squares: PB_STANDARD_PROGRESS_RENDERER
			-- Create a renderer using square characters.
		do
			Result := standard
			Result.set_fill_character ('%/9635/')
			Result.set_empty_character ('%/9634/')
		ensure
			instance_free: class
		end

	circles: PB_STANDARD_PROGRESS_RENDERER
			-- Create a renderer using circle characters.
		do
			Result := standard
			Result.set_fill_character ('%/9673/')
			Result.set_empty_character ('%/9711/')
		ensure
			instance_free: class
		end

	pixels: PB_STANDARD_PROGRESS_RENDERER
			-- Create a renderer using pixel characters.
		do
			Result := standard
			Result.set_fill_character ('%/10495/')
			Result.set_empty_character (' ')
		ensure
			instance_free: class
		end

	unicode: PB_STANDARD_PROGRESS_RENDERER
			-- Create a renderer using Unicode block characters.
		do
			Result := standard
			Result.set_fill_character ('%/9608/')
			Result.set_empty_character ('%/9617/')
		ensure
			instance_free: class
		end

feature -- Spinner renderers

	spinner: PB_SPINNER_PROGRESS_RENDERER
			-- Create a renderer using ASCII spinner phases.
		do
			create Result.make
			Result.set_phases ("%/45/%/92/%/124/%/47/")
		ensure
			instance_free: class
		end

	pie_spinner: PB_SPINNER_PROGRESS_RENDERER
			-- Create a renderer using pie spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9719/%/9718/%/9717/%/9716/")
		ensure
			instance_free: class
		end

	moon_spinner: PB_SPINNER_PROGRESS_RENDERER
			-- Create a renderer using moon spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9681/%/9682/%/9680/%/9683/")
		ensure
			instance_free: class
		end

	line_spinner: PB_SPINNER_PROGRESS_RENDERER
			-- Create a renderer using line spinner phases.
		do
			create Result.make
			Result.set_phases ("%/9146/%/9147/%/9148/%/9149/%/9148/%/9147/")
		ensure
			instance_free: class
		end

	pixel_spinner: PB_SPINNER_PROGRESS_RENDERER
			-- Create a renderer using Braille pixel phases.
		do
			create Result.make
			Result.set_phases ("%/10494/%/10487/%/10479/%/10463/%/10367/%/10431/%/10491/%/10493/")
		ensure
			instance_free: class
		end

end
