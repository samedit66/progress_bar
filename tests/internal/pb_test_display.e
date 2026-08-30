note

	description:

		"PB_DISPLAY test double retaining emitted terminal sequences."

	author: "samedit66 <samedit66@yandex.ru>"
	library: "progress_bar"

class
	PB_TEST_DISPLAY

inherit

	PB_DISPLAY
		redefine
			emit
		end

create

	make

feature -- Access

	captured: STRING_32
			-- All output emitted since the last reset.
		do
			if attached internal_capture as capture then
				Result := capture
			else
				create Result.make_empty
			end
		end

feature -- Basic operations

	reset
			-- Forget captured output.
		do
			internal_capture := Void
		ensure
			empty: captured.is_empty
		end

feature {NONE} -- Output

	emit (a_sequence: STRING_32)
			-- Append `a_sequence` to the test capture.
		local
			capture: STRING_32
		do
			if attached internal_capture as existing_capture then
				existing_capture.append (a_sequence)
			else
				create capture.make_from_string (a_sequence)
				internal_capture := capture
			end
		end

	internal_capture: detachable STRING_32
			-- Mutable storage used only by this test double.

end
