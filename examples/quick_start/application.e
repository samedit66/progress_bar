note

	description:

		"Demonstrate manual, unknown, and iterable progress."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	APPLICATION

create

	make

feature {NONE} -- Initialization

	make
			-- Run the quick-start examples.
		local
			bar: PB_BAR
			formatters: PB_FORMATTERS
			items: ARRAYED_LIST [STRING]
			progress: PB_ITERABLE [STRING]
			i: INTEGER_64
		do
			create formatters
			create bar.make_with_formatter (
				10,
				formatters.standard (
					"Manual",
					"steps",
					"done"
				)
			)
			from
				i := 0
			until
				i >
					10
			loop
				bar.update (i)
				i :=
					i +
						1
			end
			bar.finish
			create bar.make_unknown_with_formatter (formatters.unicode)
			from
				i := 1
			until
				i >
					4
			loop
				bar.update (i)
				i :=
					i +
						1
			end
			bar.finish
			create items.make (3)
			items.extend ("parse")
			items.extend ("analyze")
			items.extend ("emit")
			create progress.make_with_formatter (
				items,
				formatters.standard (
					"Across",
					"items",
					"complete"
				)
			)
			across
				progress
			as
				item
			loop
				process (item)
			end
		end

feature {NONE} -- Basic operation

	process (a_item: STRING)
			-- Stand in for application work on `a_item`.
		require
			item_not_empty: not a_item.is_empty
		do
		end

end
