class AggregateTransaction < ApplicationRecord
  establish_connection :spot_manager
  self.table_name = 'aggregate_transactions'
end
