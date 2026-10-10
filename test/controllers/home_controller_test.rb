require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when signed out" do
    get root_url
    assert_redirected_to new_session_url
  end
end
