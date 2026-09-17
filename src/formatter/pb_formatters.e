note

	description:

		"Reusable formatter agents for common progress presentations."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class PB_FORMATTERS

feature -- Standard formatters

	basic_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Portable ASCII bar, percentage, counter, and spinner.
		once
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_default
		ensure
			class
		end

	unicode_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Unicode block bar and braille spinner.
		once
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_unicode
		ensure
			class
		end

	compact_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Percentage and counter without a graphical bar.
		once
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_compact
		ensure
			class
		end

	counter_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Numeric position and total only.
		once
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_counter
		ensure
			class
		end

	minimal_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- Percentage for known progress and a spinner otherwise.
		once
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_minimal
		ensure
			class
		end

feature -- Configured formatters

	standard_formatter (a_label, a_unit, a_post_label: READABLE_STRING_GENERAL): FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL]
			-- ASCII default with copied label, unit, and trailing label.
		local
			label_copy: STRING_32
			unit_copy: STRING_32
			post_label_copy: STRING_32
		do
			create label_copy.make_from_string_general (a_label)
			create unit_copy.make_from_string_general (a_unit)
			create post_label_copy.make_from_string_general (a_post_label)
			Result := agent (create {PB_FORMATTER_IMPLEMENTATION}).format_standard (?, label_copy, unit_copy, post_label_copy, False)
		ensure
			class
		end

end
