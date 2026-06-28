require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  setup { ActiveJob::Base.queue_adapter = :inline }
  teardown { ActiveJob::Base.queue_adapter = :test }
end
