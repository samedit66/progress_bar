note

	description:
		"Reusable formatter agents for common progress presentations."
	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_FORMATTERS

feature -- Standard formatters

	basic: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Portable ASCII bar, percentage, counter, and spinner.
		once
			Result := agent format_default
		end

	unicode: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Unicode block bar and braille spinner.
		once
			Result := agent format_unicode
		end

	compact: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Percentage and counter without a graphical bar.
		once
			Result := agent format_compact
		end

	counter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Numeric position and total only.
		once
			Result := agent format_counter
		end

	minimal: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Percentage for known progress and a spinner otherwise.
		once
			Result := agent format_minimal
		end

feature -- Configured formatters

	standard (a_label, a_unit, a_post_label: READABLE_STRING_GENERAL): FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- ASCII default with copied label, unit, and trailing label.
		local
			label_copy: STRING_32
			unit_copy: STRING_32
			post_label_copy: STRING_32
		do
			create label_copy.make_from_string_general (a_label)
			create unit_copy.make_from_string_general (a_unit)
			create post_label_copy.make_from_string_general (a_post_label)
			Result := agent format_standard (?, label_copy, unit_copy, post_label_copy, False)
		end

feature {NONE} -- Formatting

	format_default (a_progress: PB_PROGRESS): STRING_32
			-- Format `a_progress` using portable ASCII characters.
		do
			Result := format_standard (a_progress, "", "", "", False)
		end

	format_unicode (a_progress: PB_PROGRESS): STRING_32
			-- Format `a_progress` using Unicode characters.
		do
			Result := format_standard (a_progress, "", "", "", True)
		end

	format_compact (a_progress: PB_PROGRESS): STRING_32
			-- Format `a_progress` without a graphical bar.
		do
			create Result.make (32)
			if a_progress.has_total then
				append_percentage (Result, a_progress)
				Result.append_string_general ("  ")
				append_counter (Result, a_progress)
			else
				append_spinner (Result, a_progress, False)
				Result.append_integer_64 (a_progress.position)
			end
		end

	format_counter (a_progress: PB_PROGRESS): STRING_32
			-- Format `a_progress` as a numeric counter.
		do
			create Result.make (24)
			append_counter (Result, a_progress)
		end

	format_minimal (a_progress: PB_PROGRESS): STRING_32
			-- Format `a_progress` as a percentage or spinner.
		do
			create Result.make (8)
			if a_progress.has_total then
				append_percentage (Result, a_progress)
			elseif a_progress.is_final then
				Result.append_integer_64 (a_progress.position)
			else
				Result.append_character (ascii_spinner (a_progress.revision))
			end
		end

	format_standard (
		a_progress: PB_PROGRESS;
		a_label, a_unit, a_post_label: READABLE_STRING_GENERAL;
		a_use_unicode: BOOLEAN
	): STRING_32
			-- Format `a_progress` with supplied affixes and character style.
		do
			create Result.make (96)
			if not a_label.is_empty then
				Result.append_string_general (a_label)
				Result.append_string_general ("  ")
			end
			if a_progress.has_total then
				append_bar (Result, a_progress, a_use_unicode)
				Result.append_string_general ("  ")
				append_percentage (Result, a_progress)
				Result.append_string_general ("  ")
				append_counter (Result, a_progress)
			else
				append_spinner (Result, a_progress, a_use_unicode)
				Result.append_integer_64 (a_progress.position)
			end
			if not a_unit.is_empty then
				Result.append_character (' ')
				Result.append_string_general (a_unit)
			end
			if not a_post_label.is_empty then
				Result.append_string_general ("  ")
				Result.append_string_general (a_post_label)
			end
		end

	append_bar (a_result: STRING_32; a_progress: PB_PROGRESS; a_use_unicode: BOOLEAN)
			-- Append a fixed-width graphical bar to `a_result`.
		require
			total_known: a_progress.has_total
		local
			filled_count: INTEGER
			empty_count: INTEGER
		do
			filled_count := (a_progress.fraction * Default_bar_width).truncated_to_integer
			empty_count := Default_bar_width - filled_count
			a_result.append_character ('[')
			if a_use_unicode then
				append_repeated_code (a_result, 0x2588, filled_count)
				append_repeated_code (a_result, 0x2591, empty_count)
			else
				append_repeated_code (a_result, ('#').natural_32_code, filled_count)
				append_repeated_code (a_result, ('-').natural_32_code, empty_count)
			end
			a_result.append_character (']')
		end

	append_percentage (a_result: STRING_32; a_progress: PB_PROGRESS)
			-- Append the whole percentage to `a_result`.
		require
			total_known: a_progress.has_total
		do
			a_result.append_integer (a_progress.percentage)
			a_result.append_character ('%%')
		end

	append_counter (a_result: STRING_32; a_progress: PB_PROGRESS)
			-- Append the numeric position and optional total to `a_result`.
		do
			a_result.append_integer_64 (a_progress.position)
			if a_progress.has_total then
				a_result.append_string_general (" / ")
				a_result.append_integer_64 (a_progress.total)
			end
		end

	append_spinner (a_result: STRING_32; a_progress: PB_PROGRESS; a_use_unicode: BOOLEAN)
			-- Append an animation frame and spacing unless `a_progress` is final.
		do
			if not a_progress.is_final then
				if a_use_unicode then
					a_result.append_character (unicode_spinner (a_progress.revision))
				else
					a_result.append_character (ascii_spinner (a_progress.revision))
				end
				a_result.append_string_general ("  ")
			end
		end

	ascii_spinner (a_revision: INTEGER_64): CHARACTER_32
			-- ASCII spinner frame selected by `a_revision`.
		do
			inspect (a_revision \\ 4).as_integer_32
			when 0 then
				Result := '|'
			when 1 then
				Result := '/'
			when 2 then
				Result := '-'
			else
				Result := (0x5C).to_character_32
			end
		end

	unicode_spinner (a_revision: INTEGER_64): CHARACTER_32
			-- Braille spinner frame selected by `a_revision`.
		do
			inspect (a_revision \\ 10).as_integer_32
			when 0 then Result := (0x280B).to_character_32
			when 1 then Result := (0x2819).to_character_32
			when 2 then Result := (0x2839).to_character_32
			when 3 then Result := (0x2838).to_character_32
			when 4 then Result := (0x283C).to_character_32
			when 5 then Result := (0x2834).to_character_32
			when 6 then Result := (0x2826).to_character_32
			when 7 then Result := (0x2827).to_character_32
			when 8 then Result := (0x2807).to_character_32
			else Result := (0x280F).to_character_32
			end
		end

	append_repeated_code (a_result: STRING_32; a_code: NATURAL_32; a_count: INTEGER)
			-- Append `a_code` to `a_result` exactly `a_count` times.
		require
			count_non_negative: a_count >= 0
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_count
			loop
				a_result.append_code (a_code)
				i := i + 1
			end
		end

feature {NONE} -- Constants

	Default_bar_width: INTEGER = 30
			-- Number of cells in a built-in graphical bar.

end
