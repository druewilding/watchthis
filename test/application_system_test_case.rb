require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # System tests run a real browser against the Rails server, so they cannot
  # share a database transaction with the test process. Disable parallelisation
  # here so all system tests run in a single process and see the same DB state.
  parallelize(workers: 1)

  Capybara.default_max_wait_time = 5
end
