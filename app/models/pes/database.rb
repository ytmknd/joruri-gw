class Pes::Database < ApplicationRecord
  self.abstract_class = true
  establish_connection :pes rescue nil
end
