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

	test_message_above_active_line
			-- Clear the active line, write a message, and restore the line.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.message_sequence (
				"done",
				"work",
				4
			)
			assert_true (
				"sequence",
				sequence.same_string ("%R    %Rdone%N%Rwork")
			)
		end

	test_empty_message_above_empty_line
			-- Preserve an active empty line around an empty message.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.message_sequence (
				"",
				"",
				0
			)
			assert_true (
				"sequence",
				sequence.same_string ("%R%R%N%R")
			)
		end

	test_unicode_multiline_message
			-- Preserve Unicode and embedded line breaks in a message.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.message_sequence (
				{STRING_32} "first%NВторая%N",
				{STRING_32} "Работа",
				6
			)
			assert_true (
				"sequence",
				sequence.same_string ({STRING_32} "%R      %Rfirst%NВторая%N%N%RРабота")
			)
		end

	test_redraw_parent_line
			-- Replace a row above the bottom and restore the cursor to the bottom row.
		local
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			sequence := renderer.redraw_line_sequence (
				"parent",
				3,
				1
			)
			assert_true (
				"move up",
				sequence.has_substring ({STRING_32} "%/27/[1A")
			)
			assert_true (
				"erase row",
				sequence.has_substring ({STRING_32} "%/27/[2K%Rparent")
			)
			assert_true (
				"move down",
				sequence.has_substring ({STRING_32} "%/27/[1B")
			)
		end

	test_replace_multiline_frame
			-- Clear the old frame and render new rows in order.
		local
			lines: ARRAYED_LIST [STRING_32]
			renderer: PB_TERMINAL_RENDERER
			sequence: STRING_32
		do
			create renderer
			create lines.make (2)
			lines.extend ("parent")
			lines.extend ("child")
			sequence := renderer.frame_sequence (
				1,
				lines
			)
			assert_true (
				"old row erased",
				sequence.starts_with ({STRING_32} "%R%/27/[2K")
			)
			assert_true (
				"ordered rows",
				sequence.ends_with ("parent%N%Rchild")
			)
		end

end
