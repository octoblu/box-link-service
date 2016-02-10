_             = require 'lodash'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server'

class Command
  constructor: ->
    @serverOptions =
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"

    @boxServiceUri = process.env.box_SERVICE_URI || 'https://api.box.com/2.0'
    @privateKeyBase64 = process.env.MESHBLU_PRIVATE_KEY_BASE64

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    @panic new Error('Missing required environment variable: MESHBLU_PRIVATE_KEY_BASE64') if _.isEmpty @privateKeyBase64

    meshbluConfig = new MeshbluConfig().toJSON()
    meshbluConfig.privateKey = new Buffer(@privateKeyBase64, 'base64').toString('utf8')
    server = new Server @serverOptions, {meshbluConfig, @boxServiceUri}
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()
