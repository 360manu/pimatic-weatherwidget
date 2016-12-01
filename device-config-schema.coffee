module.exports = {
  title: "pimatic-weatherwidget device config schemas"
  WeatherWidgetDevice: {
    title: "WeatherWidget config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      location:
        description: "City/country"
        type: "string"
      cityId:
        description: "City ID. If provided, data will queried for the given id instead of using the location property"
        type: "string"
        required: false
      lang:
        description: "Language"
        type: "string"
        default: "en"
      units:
        description: "Units"
        type: "string"
        default: "metric"
      timeout:
        description: "Timeout between requests"
        type: "integer"
        default: "900000"
      timeoutOnError:
        description: "Timeout between requests if previous request failed"
        type: "integer"
        default: "60000"
      apiKey:
        description: "API key for openweather service"
        type: "string"
        default: ""
  }
}
