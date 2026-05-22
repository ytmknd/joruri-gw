class Hcs::NotificationLetterDeduction < Hcs::NotificationDatabase
  include System::Model::Base
  include System::Model::Base::Content

  belongs_to :letter, optional: true, :foreign_key => :parent_id, :class_name => 'Hcs::NotificationLetter'
end
