class OriginTransaction < ApplicationRecord
  establish_connection :spot_manager
  self.table_name = 'origin_transactions'

  SKIP_SYMBOLS = %w(BTC ETH).freeze
  FILTER_SYMBOL = %w(USDC).freeze

  def self.available
    OriginTransaction.where('from_symbol NOT IN (?) and ((from_symbol IN (?) AND amount >= 50) OR from_symbol NOT IN (?))', FILTER_SYMBOL, SKIP_SYMBOLS, SKIP_SYMBOLS)
  end

  def self.year_to_date
    OriginTransaction.where('event_time >= ? and trade_type = ?', DateTime.parse('2023-01-01'), 'buy')
  end
end
