class PB_CLOCK_IMP
	-- Gobo clock implementation.

inherit
	PB_CLOCK

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize an unused clock.
		do
			create stopwatch.make
		end

feature -- Status report

	is_started: BOOLEAN
			-- Has the clock been started?
		do
			Result := stopwatch.is_started
		end

feature -- Basic operations

	start
			-- Start measuring elapsed time.
		require else
			not_started: not is_started
		do
			stopwatch.start
		ensure then
			started: is_started
		end

feature -- Measurement

	elapsed_seconds: INTEGER_64
			-- Whole seconds elapsed since `start'.
		require else
			started: is_started
		do
			Result := stopwatch.elapsed_time.second_count.to_integer_64
		ensure then
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	stopwatch: DT_STOPWATCH

end
