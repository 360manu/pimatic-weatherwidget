module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  path = require 'path'
  fs = require 'fs'
 
  PromiseRetryer = require('promise-retryer')(Promise)
  WeatherOpenWeather = require('./WeatherOpenWeather')(env)

  class WeatherWidget extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      # copy font files
      imgDest = ""
      imgSource = ""
      if process.platform in ['win32', 'win64']
        imgSource = path.dirname(fs.realpathSync(__filename)) + "\\app\\webfont\\"
        imgDest = path.dirname(fs.realpathSync(__filename+"\\..\\"))+"\\pimatic-mobile-frontend\\public\\font\\"
      else
        imgSource = path.dirname(fs.realpathSync(__filename)) + "/app/webfont/"
        imgDest = path.dirname(fs.realpathSync(__filename+"/../"))+"/pimatic-mobile-frontend/public/font/"
      # create directory    
      fs.exists(imgDest, (exists) =>
        if !exists 
          fs.mkdir(imgDest, (stat) =>
            env.logger.info "Create directory for the first time"
          )
      )
      #copy
      fs.readdir(imgSource, (err, files) => 
        files.forEach( (file) =>
          env.logger.info "Copy " + file + " to " + imgDest
          curSource = path.join(imgSource, file)
          curDest = path.join(imgDest, file)
          fs.writeFileSync(curDest, fs.readFileSync(curSource))
        )
      )
      
      @framework.deviceManager.registerDeviceClass("WeatherWidgetDevice", {
        configDef: deviceConfigDef.WeatherWidgetDevice,
        createCallback: (config, lastState) => new WeatherWidgetDevice(config)
      })

      # wait till all plugins are loaded
      @framework.on "after init", =>
        # Check if the mobile-frontend was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'css', "pimatic-weatherwidget/app/weathericons.css"
          mobileFrontend.registerAssetFile 'css', "pimatic-weatherwidget/app/weather.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-weatherwidget/app/weather.html"
        else
          env.logger.warn "your plugin could not find the mobile-frontend. No gui will be available"

  class WeatherWidgetDevice extends env.devices.Device
    attributes:
      forecast:
        description: "The weather forecast"
        type: "array" 
        hidden: true
      unit:
        description: "unit for displaying temperature or speed"
        type: "string"
        enum: ["imperial", "metric", "standard"]

    template: "weatherwidgetdevice"

    _forecast: null
    _mode : "metric"

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @timeout = @config.timeout
      @timeoutOnError = @config.timeoutOnError
      # unit 
      @setUnit(@config.units)  
      
      # Select API : OpenWeather
      @weather = new WeatherOpenWeather(@config.cityId, @config.location, 5, @config.lang, @config.units, @config.apiKey)
      super()
      # go
      @requestForecast()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestForecastTimeout if @requestForecastTimeout?
      super()

    requestForecast: () =>
      @requestForecastTimeout = null
      @requestPromise = PromiseRetryer.run(
        delay: 1000,
        maxRetries: 5,
        promise: => @weather.buildRequestForecast()
      ).then( (result) =>
      
        # check any error
        @weather.handleError(result)
   
        # no error (no exception launched) then translate
        @_forecast = @weather.getForecast(result)

        env.logger.debug @_forecast
        @emit "forecast", @_forecast

        @_currentRequest = Promise.resolve()
        @requestForecastTimeout = setTimeout(@requestForecast, @timeout)

      ).catch( (err) =>
        unless @lastError?.message is err.message
          env.logger.error(err.message)
          env.logger.debug(err.stack)
        @lastError = err
        @requestForecastTimeout = setTimeout(@requestForecast, @timeoutOnError)
      )
      @_currentRequest = @requestPromise unless @_currentRequest?
      return @requestPromise
 
    # Getter / Setter of attributes
    getUnit: () -> 
      Promise.resolve(@_unit)

    setUnit: (unit) ->
      @_unit = unit
      @emit "unit", @_unit

    getForecast: -> 
      @_currentRequest.then(=> @_forecast )

  plugin = new WeatherWidget
  return plugin
