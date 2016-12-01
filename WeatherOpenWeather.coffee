module.exports = (env) ->
  Promise = env.require 'bluebird'
  weatherLib = require "openweathermap"
  Promise.promisifyAll(weatherLib)
  WeatherBabel = require('./WeatherBabel')(env) 

  # Encapsulate open weather API
  class WeatherOpenWeather extends WeatherBabel 

    constructor: (cityId, cityName, days, lang, units, apiKey) ->
      @serviceProperties = lang: lang, units: units, cnt: days, agent: false

      # location type
      if cityId?
        @serviceProperties.id = cityId
      else
        @serviceProperties.q = cityName
      
      unless apiKey?
        env.logger.warn "Missing API key. Service request may be blocked"
      # id key
      @serviceProperties.appid = apiKey
      
    # send request to the API   
    buildRequestForecast: =>
      weatherLib.dailyAsync(@serviceProperties)
    
    # check if the request was successfull
    handleError: (result) -> 
      code = parseInt(result.cod, 10)
      if code isnt 200
        if result.message?.length > 0
          throw new Error("#{result.message} (#{code})")
        else
          if code is 404
            throw new Error("Location not found")
          else
            throw new Error("Error code: #{code}")
      env.logger.debug "Forecast result contains data for #{result.cnt} day(s)"
          
    # translate 
    getForecast: (result) -> 
      _forecast = []
      if result.list.length > 0
        for weather in result.list 
          #store only if full weather is available
          if weather.weather?
            temp_min = +Infinity
            temp_max = -Infinity
            if weather.temp.min <= temp_min
              temp_min = weather.temp.min
            if weather.temp.max >= temp_max?
              temp_max = weather.temp.max

            low = @_toFixed(temp_min, 1)
            high = @_toFixed(temp_max, 1)

            humidity = @_toFixed(weather.humidity, 1)
            pressure = @_toFixed(weather.pressure, 1)
            windspeed = @_toFixed(weather.speed, 1)
            weId = weather.weather[0].id
            we = weather.weather[0].description
                 
            _forecast.push({low:low, high:high, weatherId:weId, weatherDesc:we, humidity:humidity, pressure:pressure, windspeed:windspeed})
          else
            env.logger.warn "no weather"
      else
        env.logger.warn "No data found for #{@day}-day forecast"
      return _forecast

  return WeatherOpenWeather
