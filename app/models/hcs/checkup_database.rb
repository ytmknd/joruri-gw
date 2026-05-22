class Hcs::CheckupDatabase < ApplicationRecord
  self.abstract_class = true
  establish_connection :hcs_entry rescue nil
end
