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

	has_started: BOOLEAN
			-- Has the clock been started?
		do
			Result := attached started_at
		end

feature -- Basic operations

	start
			-- Start measuring elapsed time.
		do
			create started_at.make_now
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
		end

feature {NONE} -- Implementation

	started_at: detachable DATE_TIME

end
