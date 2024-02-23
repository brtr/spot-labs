class CombineTransaction < ApplicationRecord
  establish_connection :spot_manager
  self.table_name = 'combine_transactions'
end
