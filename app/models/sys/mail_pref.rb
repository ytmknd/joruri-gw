class Sys::MailPref < ApplicationRecord
  self.abstract_class = true
  establish_connection :mailcore rescue nil
end
