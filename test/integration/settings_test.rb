require "test_helper"

class SettingsTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "GET /settings is accessible" do
    get settings_url
    assert_response :success
  end

  test "PATCH /settings updates display_name" do
    patch settings_url, params: {user: {display_name: "Alice Wonderland"}}
    assert_redirected_to settings_url
    assert_equal "Alice Wonderland", users(:alice).reload.display_name
  end

  test "PATCH /settings with blank display_name clears it" do
    users(:alice).update!(display_name: "Old Name")
    patch settings_url, params: {user: {display_name: ""}}
    assert_redirected_to settings_url
    assert_nil users(:alice).reload.display_name
  end
end
