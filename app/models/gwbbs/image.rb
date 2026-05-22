class Gwbbs::Image < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include Gwboard::Model::SerialNo
  include Gwboard::Model::Image::Base
  include Gwbbs::Model::Systemname

  belongs_to :doc, optional: true, :foreign_key => :parent_id
  belongs_to :control, optional: true, :foreign_key => :title_id
  belongs_to :db_file, optional: true, :foreign_key => :db_file_id, :dependent => :destroy
end
