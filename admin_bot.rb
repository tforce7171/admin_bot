require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'
require 'pg'
require 'dotenv'
require_relative 'wg_api'

Dotenv.load
bot = Discordrb::Commands::CommandBot.new(
  token: ENV['TOKEN'],
  client_id: ENV['CLIENT_ID'],
  prefix: '/'
)
@wgapi = WGAPI.new
assign_time_hour = 16
assign_time_min = 0o0
exec_count = 0
application_id = ENV['APPLICATION_ID']
clan_ids = [1845, 6800, 29274, 34796, 16297]
# channel_id_thirty = '451034405721473026' # 本番
channel_id_thirty = "549143999814959124"#テスト

def MakeMessage(event,clan_ids)
  message = ""
  clan_ids.each do |clan_id|
    result = GetClanData(clan_id)
    tag = GetClanTag(result,clan_id)
    non_active_data = GetNonActiveData(event,result,clan_id)
    message = CombineString(message,tag,non_active_data)
  end
  return message
end
def GetClanData(clan_id)
  result = @wgapi.GetClanMembers(clan_id)
  return result
end
def GetClanTag(result,clan_id)
  tag = result['data'][clan_id.to_s]['tag']
  return tag
end
def GetNonActiveData(event,result,clan_id)
  non_active_data = {}
  personal_data = GetPersonalData(result,clan_id)
  print personal_data
  date_range = GetDateRange(event)
  today = Date.today
  personal_data['data'].each do |member_data|
    nickname = member_data[1]['nickname']
    last_battle_time_unix = member_data[1]['last_battle_time']
    last_battle_date = Time.at(last_battle_time_unix).to_date
    date_since_last_battle = (today - last_battle_date).to_i
    if date_range <= date_since_last_battle
      non_active_data[nickname] = date_since_last_battle
    end
  end
  return non_active_data
end
def GetPersonalData(result,clan_id)
  member_ids = ""
  result['data'][clan_id.to_s]['members_ids'].each do |member_id|
    member_ids << "#{member_id}%2C"
  end
  member_ids = member_ids.chomp('%2C')
  personal_data = @wgapi.GetMembersData(member_ids)
  return personal_data
end
def GetDateRange(event)
  bot_message = event.message.content
  bot_message.slice!(0, 5)
  date_range = bot_message.to_i
  return date_range
end
def CombineString(message,tag,non_active_data)
  if message.empty?
    message << "|#{tag}|"
  else
    message << "\n\n|#{tag}|"
  end
  non_active_data.each do |nickname, date_since_last_battle|
    message << "\n#{nickname} : #{date_since_last_battle}日"
  end
  return message
end

bot.ready do
  bot.send_message(channel_id_thirty,"up and ready")
end

bot.command :buku do |event|
  bot.send_message(channel_id_thirty,"processing...")
  message = MakeMessage(event,clan_ids)
  bot.send_message(channel_id_thirty,message)
end

bot.heartbeat do |_event|
  now_hour = Time.now.hour
  now_min = Time.now.min

  if assign_time_hour == now_hour && assign_time_min <= now_min && exec_count == 0
    @wgapi.ProlongateAccessToken
  end
  exec_count = 1

  exec_count = 0 if assign_time_hour < now_hour && exec_count == 1
end

bot.run
