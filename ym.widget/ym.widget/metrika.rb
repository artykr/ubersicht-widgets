require 'rubygems'
require 'bundler/setup'
require 'metrika'

# Update these to match your own apps credentials
application_id = ''
password = ''
auth_token = ''
counter_id = 1234567

client = Metrika::Client.new(application_id, password)
client.restore_token(auth_token)

startDate = (Date.today - 7)
endDate = Date.today
combinedData = { :visits => [], :goals => [] }
dateArray = ((Date.today - 7)..Date.today).map {|date| date.strftime("%Y%m%d")}

# Get visits
result = client.get_counter_stat_traffic_summary(counter_id, :group => :day, :date1 => startDate, :date2 => endDate)

result['data'].each do |item|
 combinedData[:visits] << item['visits']
end

combinedData[:visits].reverse!

# Get goals
result = client.get_counter_goals(counter_id)

result.each do |goal|
  goalDetails = client.get_counter_stat_traffic_summary(counter_id, :group => :day, :date1 => startDate, :date2 => endDate, :goal_id => goal["id"])
  if goalDetails["rows"].to_i != 0
    combinedData[:goals] << { :name => goal["name"] , :hits => Array.new(8, 0) }
    goalDetails["data"].each do |r|
      index = dateArray.index(r["date"])
      combinedData[:goals].last[:hits][index] = r["goal_reaches"]
    end
  end
end

print combinedData.to_json
