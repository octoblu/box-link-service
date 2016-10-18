http          = require 'http'
request       = require 'request'
shmock        = require '@octoblu/shmock'
enableDestroy = require 'server-destroy'
MeshbluHttp   = require 'meshblu-http'
Server        = require '../../src/server'

describe 'Download', ->
  before ->
    @timeout 20000
    meshbluHttp = new MeshbluHttp({})
    {@privateKey, publicKey} = meshbluHttp.generateKeyPair()

    @privateKeyObj = meshbluHttp.setPrivateKey @privateKey

  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu
    @box = shmock 0xbabe
    enableDestroy @box

    serverOptions =
      port: undefined,
      disableLogging: true

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d
      privateKey: @privateKey

    @boxServiceUri = "http://localhost:#{0xbabe}"
    @server = new Server serverOptions, {meshbluConfig,@boxServiceUri}

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()
    @meshblu.destroy()
    @box.destroy()

  describe 'On GET /meshblu/links', ->
    beforeEach (done) ->
      deviceAuth = new Buffer('one-time-device-uuid:one-time-device-token').toString 'base64'
      @getTheDevice = @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{deviceAuth}"
        .reply 200,
          uuid: 'one-time-device-uuid'
          box:
            encryptedToken: @privateKeyObj.encrypt 'oh-this-is-my-bearer-token', 'base64'
            encryptedFileId: @privateKeyObj.encrypt 'file-id', 'base64'

      @shareLink = @box
        .put "/files/file-id"
        .reply 201,
          shared_link:
            download_url: "#{@boxServiceUri}/download-link"

      @downloadLink = @box
        .get "/download-link"
        .reply 200, '{"some-data":true}'

      @deleteTheDevice = @meshblu
        .delete '/devices/one-time-device-uuid'
        .set 'Authorization', "Basic #{deviceAuth}"
        .reply 200

      options =
        uri: '/meshblu/links'
        baseUrl: "http://localhost:#{@serverPort}"
        auth:
          username: 'one-time-device-uuid'
          password: 'one-time-device-token'

      request.get options, (error, @response, @body) =>
        done error

    it 'should get the device', ->
      @getTheDevice.done()

    it 'should share the link', ->
      @shareLink.done()

    it 'should dowload the link', ->
      @downloadLink.done()

    it 'should delete the device when done', ->
      @deleteTheDevice.done()

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should return the result', ->
      expect(@body).to.equal '{"some-data":true}'
