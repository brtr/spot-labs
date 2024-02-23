require 'open-uri'

class SyncCmcHistoryService
  EXCEPT_SYMBOL = ["anc", "arc", "atom", "bits", "btm", "cmt", "cos", "dot", "gcc", "glc", "med", "net", "rune", "steth", "stx", "tix", "ton", "vip", "auto"]

  class << self
    def generate_for_history(start_date = nil, end_date = nil)
      start_date = Date.new(2017,1,1) if start_date.nil?
      end_date = Date.yesterday - 1.day if end_date.nil?

      puts "Start at #{Time.now}"
      (start_date..end_date).each do |date|
        get_cmc_histories(date, "https://web-api.coinmarketcap.com/v1/cryptocurrency/listings/historical?convert=USD,BTC&date=#{date}&limit=500&start=1")

        sleep 1
      end

      puts "End at #{Time.now}"
    end

    def generate_for_yesterday
      puts "Start at #{Time.now}"

      get_cmc_histories(Date.yesterday, "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?CMC_PRO_API_KEY=#{ENV["CMC_API_KEY"]}&limit=500")

      puts "End at #{Time.now}"
    end

    def get_cmc_histories(date, url)
      response = URI.open(url).read
      summary = JSON.parse response
      summary['data'].each do |asset|
        symbol = asset['symbol'].downcase
        slug = asset['slug'].downcase
        puts "------coin: #{symbol}"

        coin = Coin.where(cmc_id: asset['id']).take
        coin = Coin.where("lower(coingeckoid) = ? and (lower(symbol) = ? and lower(symbol) not in (?))", slug, symbol, EXCEPT_SYMBOL).take unless coin

        if coin.nil?
          coin = Coin.create(symbol: symbol, name: asset['name'].downcase, coingeckoid: slug, cmc_id: asset['id'])
        end

        if coin
          history = coin.cmc_histories.find_or_create_by(event_date: date)
          quote = asset['quote']['USD']
          history.update(price: quote['price'].to_f,
                          market_cap: quote['market_cap'].to_f,
                          market_cap_rank: asset['cmc_rank'],
                          volume: quote['volume_24h'].to_f,
                          percentage_24h: quote['percent_change_24h'],
                          percentage_7d: quote['percent_change_7d'])
        end
      end
    end

    def rearrange_cmc_history_rank
      puts "--------------update rank by market_cap--------------"
      CmcHistory.where(market_cap_rank: 0).pluck(:event_date).uniq.sort.each do |date|
        CmcHistory.update_date_rank(date)
      end
    end
  end
end