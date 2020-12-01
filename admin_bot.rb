require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'
require 'pg'

bot = Discordrb::Commands::CommandBot.new(
token: ENV['TOKEN'],
client_id: ENV['CLIENT_ID'],
prefix:'/',
)
application_id = ENV['APPLICATION_ID']
clan_ids = ["1845","6800","29274","34796","16297"]
access_token = ENV['ACCESS_TOKEN']
#access_token_test = ENV['ACCESS_TOKEN_TEST']
# channel_id_thirty = "451034405721473026"#本番
channel_id_thirty = "549143999814959124"#テスト

uri = URI.parse(ENV['DATABASE_URL'])
   @client ||= PG::connect(
     host: uri.hostname,
     dbname: uri.path[1..-1],
     user: uri.user,
     port: uri.port,
     password: uri.password
   )

bot.command :buku do |event|

  bot_message = event.message.content
  bot_message.slice!(0,5)
  date_range = bot_message.to_i

  today = Date.today

  clan_ids.each do |clan_id|

    member_ids = ""

    url = "https://api.wotblitz.asia/wotb/clans/info/?application_id=#{application_id}&clan_id=#{clan_id}&fields=tag%2Cmembers_ids"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)

    tag = result["data"]["#{clan_id}"]["tag"]
    bot.send_message(channel_id_thirty, "|#{tag}|")

    result["data"]["#{clan_id}"]["members_ids"].each do |member_id|

      member_ids = member_ids + "#{member_id}%2C"

    end

    member_ids = member_ids.chomp('%2C')

    url = "https://api.wotblitz.asia/wotb/account/info/?application_id=#{application_id}&access_token=#{access_token}&account_id=#{member_ids}&fields=nickname%2Clast_battle_time"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)

    results["data"].each do |member_data|

      nickname = member_data[1]["nickname"]
      last_battle_time_unix = member_data[1]["last_battle_time"]
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

  rows = conn.exec("select * from access_token")
  access_token_test = rows["access_token"]

  bot.send_message(channel_id_thirty,"#{access_token_test}")

  url = "https://api.worldoftanks.asia/wot/auth/prolongate/"
  client = HTTPClient.new
  response = client.post(url,{
    application_id: "#{application_id}",
    access_token: "#{access_token_test}"})
  result = JSON.parse(response.body)

  bot.send_message(channel_id_thirty,"#{result}")

  access_token_test = result["data"]["access_token"]
  conn.exec("
    update access_token
    set access_token=#{access_token_test}
    where id=1
    ")



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
