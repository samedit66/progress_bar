note

	description:

		"Inclusive integer range that reports traversal progress."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_RANGE

inherit

	PB_ITERABLE [INTEGER]

create

	make_from_to,
	make_from_to_with_formatter

feature {NONE} -- Initialization

	make_from_to (a_from, a_to: INTEGER)
			-- Create progress over all integers from `a_from` through `a_to`, inclusive.
		require
			count_representable: is_count_representable (
				a_from,
				a_to
			)
		local
			interval: INTEGER_INTERVAL
		do
			create interval.make (
				a_from,
				a_to
			)
			make (interval)
		end

	make_from_to_with_formatter (a_from, a_to: INTEGER; a_formatter: FUNCTION [TUPLE [progress: PB_PROGRESS], READABLE_STRING_GENERAL])
			-- Create formatted progress over all integers from `a_from` through `a_to`, inclusive.
		require
			count_representable: is_count_representable (
				a_from,
				a_to
			)
		local
			interval: INTEGER_INTERVAL
		do
			create interval.make (
				a_from,
				a_to
			)
			make_with_formatter (
				interval,
				a_formatter
			)
		end

feature {NONE} -- Contract support

	is_count_representable (a_from, a_to: INTEGER): BOOLEAN
			-- Does the inclusive range cardinality fit in `INTEGER`?
		do
			Result :=
				a_from >
					a_to or else
					a_to.to_integer_64 -
						a_from.to_integer_64 +
						1 <=
						{INTEGER}.max_value.to_integer_64
		ensure
			empty_representable: a_from >
				a_to implies
				Result
		end

end
