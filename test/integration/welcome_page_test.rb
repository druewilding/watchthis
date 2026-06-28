require "test_helper"

class WelcomePageTest < ActionDispatch::IntegrationTest
  setup { get root_url }

  test "renders the klods page shell" do
    assert_select "div.klods-page"
    assert_select "header.klods-header"
    assert_select "aside.klods-sidebar"
    assert_select "main.klods-content"
    assert_select "footer.klods-footer"
  end

  test "page title is set" do
    assert_select "title", text: /Rails Server Template/
  end

  test "sidebar has a table of contents" do
    assert_select "ul.klods-toc"
    assert_select "a[href='#welcome']"
    assert_select "a[href='#getting-started']"
  end

  test "welcome heading is present" do
    assert_select "h1#welcome"
  end

  test "klods docs button links out" do
    assert_select "a.klods-button[href*='druewilding.com/klods']"
  end

  test "API status button is present" do
    assert_select "a.klods-button[href='/api/v1/status']"
  end
end
