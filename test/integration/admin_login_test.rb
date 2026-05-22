require 'test_helper'

class AdminLoginTest < ActionDispatch::IntegrationTest
  def setup
    System::User.where(code: 'admin').delete_all
    System::User.create!(
      state:    'enabled',
      ldap:     0,
      auth_no:  1,
      name:     'システム管理者',
      code:     'admin',
      password: 'admin'
    )
  end

  test "login page is accessible" do
    get "/_admin/login"
    assert_response :success
  end

  test "admin can authenticate with correct credentials" do
    post "/_admin/login", account: 'admin', password: 'admin'
    assert_response :redirect
  end

  test "wrong password stays on login page" do
    post "/_admin/login", account: 'admin', password: 'wrong'
    assert_response :success
  end
end
