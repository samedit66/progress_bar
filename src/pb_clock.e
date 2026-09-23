deferred class PB_CLOCK
	-- Measures elapsed whole seconds.

feature -- Status report

	is_started: BOOLEAN
			-- Has the clock been started?
		deferred
		end

feature -- Basic operations

	start
			-- Start measuring elapsed time.
		require
			not_started: not is_started
		deferred
		ensure
			started: is_started
		end

feature -- Measurement

	elapsed_seconds: INTEGER_64
			-- Whole seconds elapsed since `start'.
		require
			started: is_started
		deferred
		ensure
			non_negative: Result >= 0
		end

end
