note

	description:

		"Independent completion and recovery after a formatter failure."


class PB_COMPLETION_TESTS

inherit

	TS_TEST_CASE

create

	make_default

feature -- Test

	test_formatter_failure_does_not_close_other_bars
		local
			display: PB_TEST_DISPLAY
			first, second: PB_BAR
		do
			create display.make
			create first.make_with_total (10)
			first.set_display (display)
			first.set_line_formatter (agent failing_final)
			create second.make_with_total (10)
			second.set_display (first.display)
			first.set_progress (2)
			second.set_progress (3)
			assert_exception ("formatter failure propagates", agent first.finish)
			assert_true ("both operations stay open", not first.is_finished and not second.is_finished)
			assert_true ("actual work preserved", first.progress = 2 and second.progress = 3)
			assert_true ("both rows remain registered", display.registered_line_count = 2)
			first.set_line_formatter (agent position_text)
			first.finish
			assert_true ("retry closes only first", first.is_finished and not second.is_finished)
			second.forth
			assert_true ("second can still advance", second.progress = 4)
			second.finish
			assert_true ("display released", display.registered_line_count = 0)
		end

feature {NONE} -- Formatting

	failing_final (snapshot: PB_PROGRESS): STRING_32
		local
			failure: DEVELOPER_EXCEPTION
		do
			Result := position_text (snapshot)
			if snapshot.is_final then
				create failure
				failure.raise
			end
		end

	position_text (snapshot: PB_PROGRESS): STRING_32
		do
			create Result.make_from_string_general (snapshot.position.out)
		end

end
