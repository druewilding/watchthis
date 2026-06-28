require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "root returns 200" do
    get root_url
    assert_response :success
  end

  test "ping returns plain text with app name and Rails version" do
    get ping_url
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
    assert_match "Watchthis", response.body
    assert_match Rails::VERSION::STRING, response.body
  end
end
