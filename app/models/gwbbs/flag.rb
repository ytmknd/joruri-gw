class Gwbbs::Flag < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content

  belongs_to :control, optional: true, :foreign_key => :title_id, :class_name  => 'Gwbbs::Control'
  belongs_to :doc,     optional: true, :foreign_key => :parent_id, :class_name => 'Gwbbs::Doc'
  belongs_to :user,    optional: true, :foreign_key => :user_id, :class_name   => 'System::User'
end
