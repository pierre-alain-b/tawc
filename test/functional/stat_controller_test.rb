require 'test_helper'

class StatControllerTest < ActionController::TestCase
  test "should get query" do
    get :query
    assert_response :success
  end

  test "should get result" do
    get :result
    assert_response :success
  end

end
