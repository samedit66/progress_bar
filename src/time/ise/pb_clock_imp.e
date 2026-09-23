class PB_CLOCK_IMP
	-- EiffelStudio clock implementation.

inherit
	PB_CLOCK

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize an unused clock.
		do
		end

feature -- Status report

	is_started: BOOLEAN
			-- Has the clock been started?
		do
			Result := attached started_at
		end

feature -- Basic operations

	start
			-- Start measuring elapsed time.
		require else
			not_started: not is_started
		do
			create started_at.make_now
		ensure then
			started: is_started
		end

feature -- Measurement

	elapsed_seconds: INTEGER_64
			-- Whole seconds elapsed since `start'.
		local
			now: DATE_TIME
		do
			if attached started_at as l_started_at then
				create now.make_now
				Result := now.relative_duration (l_started_at).seconds_count
			end
		ensure then
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	started_at: detachable DATE_TIME

end
