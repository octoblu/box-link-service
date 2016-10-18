expressOctoblu     = require 'express-octoblu'
enableDestroy      = require 'server-destroy'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
MeshbluConfig      = require 'meshblu-config'
debug              = require('debug')('box-link-service:server')
Router             = require './router'
BoxLinkService = require './services/box-link-service'

class Server
  constructor: ({@disableLogging, @port}, {@meshbluConfig,@boxServiceUri})->
    @meshbluConfig ?= new MeshbluConfig().toJSON()

  address: =>
    @server.address()

  run: (callback) =>
    app = expressOctoblu()
    boxLinkService = new BoxLinkService {@meshbluConfig,@boxServiceUri}

    router = new Router {boxLinkService,@meshbluConfig}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
