require 'rubygems'
require 'bundler/setup'
require 'google/api_client'
require 'date'
require 'json'

API_VERSION = 'v3'
CACHED_API_FILE = "analytics-#{API_VERSION}.cache"

# Update these to match your own apps credentials
service_account_email = 'xxxxxxxx@developer.gserviceaccount.com' # Email of service account
key_file = 'xxxxxxxx.p12' # File containing your private key
key_secret = 'notasecret' # Password to unlock private key
profileID = 'xxxxxxxx' # Analytics profile ID.
accountID = 'xxxxxxxx'
propertyID = 'UA-xxxxxxxx-1'


client = Google::APIClient.new(
  :application_name => 'Ubersich GA widget',
  :application_version => '1.0.0')

# Load our credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
  :issuer => service_account_email,
  :signing_key => key)

# Request a token for our service account
client.authorization.fetch_access_token!

analytics = nil
# Load cached discovered API, if it exists. This prevents retrieving the
# discovery document on every run, saving a round-trip to the discovery service.
if File.exists? CACHED_API_FILE
  File.open(CACHED_API_FILE) do |file|
    analytics = Marshal.load(file)
  end
else
  analytics = client.discovered_api('analytics', API_VERSION)
  File.open(CACHED_API_FILE, 'w') do |file|
    Marshal.dump(analytics, file)
  end
end

startDate = (Date.today - 7).strftime("%Y-%m-%d")
#startDate = DateTime.now.prev_month.strftime("%Y-%m-%d")
endDate = Date.today.strftime("%Y-%m-%d")

visitCount = client.execute(:api_method => analytics.data.ga.get, :parameters => {
  'ids' => "ga:" + profileID,
  'start-date' => startDate,
  'end-date' => endDate,
  'dimensions' => "ga:day",
  'metrics' => "ga:sessions",
  'sort' => "ga:day"
})

combinedData = { :visits => [], :goals => [] }

# Fix Google API date sorting
daysArray = ((Date.today - 7)..Date.today).map{ |date| date.strftime("%d")}

daysArray.each do |d|
  visits = visitCount.data.rows.select { |r| r[0] == d }
  combinedData[:visits] << visits[0][1]
end

goals = client.execute(:api_method => analytics.management.goals.list, :parameters => {
  'accountId' => accountID,
  'profileId' => profileID,
  'webPropertyId' => propertyID
})

goals.data.items.each do |g|
  goalCount = client.execute(:api_method => analytics.data.ga.get, :parameters => {
    'ids' => "ga:" + profileID,
    'start-date' => startDate,
    'end-date' => endDate,
    'dimensions' => "ga:day",
    'metrics' => "ga:goal" + g.id + "Completions",
  })

  combinedData[:goals] << { :name => g.name, :hits => [] }

  daysArray.each do |d|
    hits = goalCount.data.rows.select { |r| r[0] == d }
    combinedData[:goals].last[:hits] << hits[0][1]
  end

end # end of goals iteration

print combinedData.to_json
