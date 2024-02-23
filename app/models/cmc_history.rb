class CmcHistory < ApplicationRecord
  establish_connection :coin_elite
  self.table_name = 'cmc_histories'

  belongs_to :coin
  delegate :symbol, to: :coin

  scope :search_period_date, ->(date) { where("event_date >= ?", date) }
end
