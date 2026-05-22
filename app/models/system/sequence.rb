class System::Sequence < ApplicationRecord
  self.table_name = "system_sequences"

  scope :versioned, lambda{ |v| { :conditions => ["version = ?", "#{v}"] }}
end
