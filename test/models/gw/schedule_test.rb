require 'test_helper'

class Gw::ScheduleTest < ActiveSupport::TestCase
  def setup
    System::User.where(code: 'schedule-test').delete_all
    @user = System::User.create!(
      state:    'enabled',
      ldap:     0,
      auth_no:  1,
      name:     '予定テストユーザー',
      code:     'schedule-test',
      password: 'password'
    )
  end

  test 'relation json is restored from form parameters when hidden fields are blank' do
    item = ActionController::Parameters.new(
      'schedule_users' => {'uid' => [@user.id.to_s]},
      'schedule_users_json' => '',
      'schedule_props' => {'prop_type_id' => 'other:other:200', 'prop_id' => ['1']},
      'schedule_props_json' => ''
    )

    Gw::Schedule.ensure_relation_json!(item)

    assert_equal [['1', @user.id.to_s, @user.display_name]], JSON.parse(item[:schedule_users_json])
    assert_equal [['other', '1', '']], JSON.parse(item[:schedule_props_json])
  end

  test 'existing relation json is kept' do
    item = {
      schedule_users: {uid: [@user.id.to_s]},
      schedule_users_json: '[["1","999","existing"]]',
      schedule_props: {prop_type_id: 'other:other:200', prop_id: ['1']},
      schedule_props_json: '[["other","999","existing"]]'
    }

    Gw::Schedule.ensure_relation_json!(item)

    assert_equal '[["1","999","existing"]]', item[:schedule_users_json]
    assert_equal '[["other","999","existing"]]', item[:schedule_props_json]
  end
end
