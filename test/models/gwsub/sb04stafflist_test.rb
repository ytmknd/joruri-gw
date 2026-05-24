require 'test_helper'

class Gwsub::Sb04stafflistTest < ActiveSupport::TestCase
  test 'search accepts empty action controller parameters' do
    params = ActionController::Parameters.new

    assert_nothing_raised do
      Gwsub::Sb04stafflist.new.search(params)
    end
  end
end
