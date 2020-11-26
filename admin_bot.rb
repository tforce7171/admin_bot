require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'

bot = Discordrb::Commands::CommandBot.new(
token: ENV['TOKEN'],
client_id: ENV['CLIENT_ID'],
prefix:'/',
)
application_id = ENV['APPLICATION_ID']
clan_ids = ["1845","6800","29274","34796","16297"]
access_token = ENV['ACCESS_TOKEN']
channel_id_thirty = "451034405721473026"

bot.command :buku do |event|

  bot_message = event.message.content
  bot_message.slice!(0,5)
  date_range = bot_message.to_i

  today = Date.today

  clan_ids.each do |clan_id|

    url = "https://api.wotblitz.asia/wotb/clans/info/?application_id=#{application_id}&clan_id=#{clan_id}&fields=tag%2Cmembers_ids"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)

    tag = result["data"]["#{clan_id}"]["tag"]
    bot.send_message(channel_id_thirty, "|#{tag}|")

    result["data"]["#{clan_id}"]["members_ids"].each do |member_id|

      url = "https://api.wotblitz.asia/wotb/account/info/?application_id=#{application_id}&access_token=#{access_token}&account_id=#{member_id}&fields=nickname%2Clast_battle_time"
      client = HTTPClient.new
      response = client.get(url)
      result = JSON.parse(response.body)

      nickname = result["data"]["#{member_id}"]["nickname"]
      last_battle_time_unix = result["data"]["#{member_id}"]["last_battle_time"]
      last_battle_date = Time.at(last_battle_time_unix).to_date
      date_since_last_battle = (today - last_battle_date).to_i

      if date_range <= date_since_last_battle
        bot.send_message(channel_id_thirty, "#{nickname} : #{date_since_last_battle}日")
      end

    end

  end
  bot.send_message(channel_id_thirty, "done")
end

bot.command :test do |event|

  url = "https://api.worldoftanks.asia/wot/auth/login/?application_id=#{application_id}&nofollow=1"
  client = HTTPClient.new
  response = client.get(url)
  result = JSON.parse(response.body)

  bot.send_message(channel_id_boshuu,"#{result}")

  # url = "https://api.worldoftanks.asia/wot/auth/prolongate/?application_id=#{application_id}&access_token=#{access_token}"
  # client = HTTPClient.new
  # response = client.get(url)
  # result = JSON.parse(response.body)
  #
  # bot.send_message(channel_id_boshuu,"#{result}")
  #
  # access_token = result["data"]["access_token"]
  # ENV['ACCESS_TOKEN'] = access_token

end

bot.run
