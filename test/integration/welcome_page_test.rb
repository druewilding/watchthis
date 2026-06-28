require "test_helper"

class WelcomePageTest < ActionDispatch::IntegrationTest
  setup { get root_url }

  test "renders the klods page shell" do
    assert_select "div.klods-page"
    assert_select "header.klods-header"
    assert_select "main.klods-content"
    assert_select "footer.klods-footer"
  end

  test "page title is set" do
    assert_select "title", text: /WatchThis/
  end

  test "welcome heading is present" do
    assert_select "h1", text: /WatchThis/
  end

  test "sign up button links to registration" do
    assert_select "a.klods-button[href='/users/sign_up']"
  end

  test "sign in button links to session" do
    assert_select "a.klods-button[href='/users/sign_in']"
  end
end
