module.exports = (env) ->
  _ = env.require 'lodash'

  # Encapsulate different weather API
  # 
  # output structure is expected to be
  class WeatherBabel 

    # send the request to the API   
    buildRequestForecast: =>
    
    # check if the request was successfull
    # send exception on error
    handleError: (result) -> 
    
    # translate 
    getForecast: (result) -> 
    
    # helper to cleanup some values
    _toFixed: (value, nDecimalDigits) ->
      if _.isNumber(value)
        return Number value.toFixed(nDecimalDigits)
      else
        return Number value
        
  
