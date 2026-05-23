ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # check_pending! removed in Rails 8; use check_all_pending! if available
  if ActiveRecord::Migration.respond_to?(:check_all_pending!)
    ActiveRecord::Migration.check_all_pending!
  elsif ActiveRecord::Migration.respond_to?(:check_pending!)
    ActiveRecord::Migration.check_pending!
  end

  # Add more helper methods to be used by all tests here...
end
