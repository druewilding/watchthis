require "test_helper"

module Api
  module V1
    class StatusControllerTest < ActionDispatch::IntegrationTest
      test "status returns JSON with OK status" do
        get api_v1_status_url
        assert_response :success
        assert_equal "application/json; charset=utf-8", response.content_type
        body = JSON.parse(response.body)
        assert_equal "OK", body["status"]
        assert body["message"].present?
      end
    end
  end
end
