class Report < ActiveRecord::Base
  attr_accessible :location
  validates_presence_of :location

  require 'geoplanet'
  require 'timezone'


  def geoplanet_location
    if location.to_i > 0
      geoplanet_location = GeoPlanet::Place.search(location.to_s)
    else
      geoplanet_location = GeoPlanet::Place.search(location.to_s, count: 5)
    end
  end

  def woeid
    woeid = woeid || geoplanet_location.first.woeid
  end

  def response
    @response = client.lookup_by_woeid(woeid)
  end

  def forecast
    forecast = response.forecasts.first
  end

  def sunny?
    forecast['text'].downcase.include?("sun") || forecast['text'].downcase.include?("clear")
  end

  def sunrise
    (response.astronomy['sunrise'].to_i) - 1
  end

  def sunset
    response.astronomy['sunset'].to_i + 11
  end

  def time_at_location
    latitude = geoplanet_location.first.latitude
    longitude = geoplanet_location.first.longitude
    timezone = Timezone::Zone.new :latlon => [latitude, longitude]
    time_at_location = timezone.time Time.now
  end

  def daytime?
    time_at_location.hour >= sunrise && time_at_location.hour <= sunset
  end

  private
  # GeoPlanet and Timezone configurations
  GeoPlanet.appid = "I22yVmDV34G_SCBRk0NHKXjuMe9bxnhNQRW27lY1rqn0ta.L8vKUx5TxM3v9yOtMbp9kpDrew8XJ"
  Timezone::Configure.begin do |c|
    c.username = 'bdcheung'
  end
  def client
    client = Weatherman::Client.new
  end

end
