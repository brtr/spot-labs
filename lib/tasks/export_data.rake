require 'csv'

namespace :coin do
  desc 'Export top200 from 2021'
  task export_top200_from_2021: :environment do
    arr = []
    end_date = Date.yesterday
    from_date = Date.parse('2021-01-01')
    CmcHistory.includes(:coin).where("event_date >= ? and event_date <= ?", from_date, end_date).order(event_date: :asc).group_by(&:coin_id).each do |coin_id, hh|
      max_h = hh.max {|a, b| a.price <=> b.price}
      next if max_h.blank? || max_h.price == 0 || max_h.volume < 10
      last_h = hh.last
      next if last_h.blank? || last_h.market_cap_rank > 200 || last_h.market_cap_rank == 0 || max_h.price / last_h.price < 10
      coin = last_h.coin
      rate = max_h.price / last_h.price
      arr << {
        id: coin_id, symbol: coin.symbol, name: coin.name,
        coingeckoid: coin.coingeckoid, market_cap_rank: last_h.market_cap_rank,
        max_price: max_h.price, max_time: max_h.event_date,
        current_pirce: last_h.price,
        rate: rate.round(2), volume: last_h.volume,
        market_cap: last_h.market_cap
      }
    end
    arr.sort_by!{|a| a[:market_cap]}.reverse!
    export_csv(arr)
  end

  desc 'Export top200 for last 400 days'
  task export_top200_for_last_400_days: :environment do
    arr = []
    end_date = Date.yesterday
    from_date = end_date - 400.days
    CmcHistory.includes(:coin).where("event_date >= ? and event_date <= ?", from_date, end_date).order(event_date: :asc).group_by(&:coin_id).each do |coin_id, hh|
      min_h = hh.min {|a, b| a.price <=> b.price}
      next if min_h.blank? || min_h.price == 0 || min_h.volume < 10
      last_h = hh.last
      next if last_h.blank? || last_h.market_cap_rank >= 200 || last_h.market_cap_rank == 0 || last_h.price / min_h.price > 1.5
      coin = last_h.coin
      rate = last_h.price / min_h.price
      arr << {
        id: coin_id, symbol: coin.symbol, name: coin.name,
        coingeckoid: coin.coingeckoid, market_cap_rank: last_h.market_cap_rank,
        min_price: min_h.price, min_time: min_h.event_date,
        current_pirce: last_h.price,
        rate: rate.round(2),
        market_cap: last_h.market_cap
      }
    end
    arr.sort_by!{|a| a[:market_cap]}.reverse!
    export_csv(arr)
  end
end

def export_csv(data)
  CSV.open("tmp/export_data.csv", "w") do |csv|
    csv << data.first.keys
    data.each {|a| csv << a.values }
  end
end