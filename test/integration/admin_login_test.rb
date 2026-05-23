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
    # Rails 5+: use params: keyword; Rails 4: positional hash — detect at runtime
    if Rails::VERSION::MAJOR >= 5
      post "/_admin/login", params: {account: 'admin', password: 'admin'}
    else
      post "/_admin/login", account: 'admin', password: 'admin'
    end
    assert_response :redirect
  end

  test "wrong password stays on login page" do
    if Rails::VERSION::MAJOR >= 5
      post "/_admin/login", params: {account: 'admin', password: 'wrong'}
    else
      post "/_admin/login", account: 'admin', password: 'wrong'
    end
    assert_response :success
  end
end
