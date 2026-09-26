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

end
