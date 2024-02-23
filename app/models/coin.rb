class Coin < ApplicationRecord
  establish_connection :coin_elite
  self.table_name = 'coins'

  has_many :cmc_histories, dependent: :destroy, autosave: true
  scope :stable, -> { where(is_stable: true) }
  scope :without_stable, -> { where(is_stable: false) }
  scope :staking, -> { where(is_staking: true) }
  scope :without_staking, -> { where(is_staking: false) }

  def generate_cmc_history(start_date: 1.years.ago.to_date, end_date: Date.yesterday)
    puts "generate historical data for #{symbol}"
    range = (end_date.to_date - start_date.to_date).to_i
    histories = cmc_histories.where(event_date: start_date..end_date)

    if histories.count >= (range + 1)
      puts "-----histories already have -- #{symbol}-----------------------------------"
      return
    end

    begin
      while start_date < end_date
        date = (start_date - 1.day).strftime("%Y-%m-%d")
        res = Net::HTTP.get_response(URI("https://web-api.coinmarketcap.com/v1/cryptocurrency/ohlcv/historical?id=#{cmc_id}&count=300&time_start=#{date}"))
        if res.code.to_i == 200
          response = JSON.parse(res.body)
          data = response['data']
          self.update(cmc_id: data['id'])
          quotes = data['quotes']

          quotes.each do |quote|
            price = quote['quote']['USD']
            timestamp = DateTime.parse(price['timestamp'])
            history = histories.where(event_date: timestamp)
                                  .first_or_create(
                                    event_date: timestamp,
                                    price: price['close'],
                                    volume: price['volume'],
                                    market_cap: price['market_cap']
                                  )
          end
        else
          puts "skip"
        end

        start_date += 300.days
      end
    rescue
      puts "bad request coin #{symbol}"
    end
  end
end
