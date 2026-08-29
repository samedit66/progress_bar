note

	description:

		"Tests for terminal line replacement sequences."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_TERMINAL_RENDERER_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_redraw_longer_line
			-- Replace a shorter line without padding.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.redraw_sequence (
				"long",
				2
			)
			assert_true (
				"sequence",
				sequence.same_string ("%Rlong")
			)
		end

	test_redraw_shorter_line
			-- Clear the tail left by a longer previous line.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.redraw_sequence (
				"new",
				5
			)
			assert_true (
				"sequence",
				sequence.same_string ("%Rnew  %Rnew")
			)
		end

	test_finish_line
			-- Clear a previous tail and append one newline.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.finish_sequence (
				"ok",
				4
			)
			assert_true (
				"sequence",
				sequence.same_string ("%Rok  %N")
			)
		end

end
