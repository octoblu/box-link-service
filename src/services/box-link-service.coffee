MeshbluHttp = require 'meshblu-http'
request     = require 'request'

class boxLinkService
  constructor: ({@meshbluConfig,@boxServiceUri}) ->

  generate: ({token,fileId,fileName}, callback) =>
    meshbluHttp = new MeshbluHttp @meshbluConfig
    privateKey = meshbluHttp.setPrivateKey @meshbluConfig.privateKey
    encryptedToken = privateKey.encrypt token, 'base64'
    encryptedFileId = privateKey.encrypt fileId, 'base64'
    meshbluHttp.register box: {encryptedToken,encryptedFileId}, (error, device) =>
      return callback @_createError 500, error.message if error?
      link = "https://#{device.uuid}:#{device.token}@box-link.octoblu.com/meshblu/links"
      callback null, {link,fileName}

  download: ({meshbluAuth}, callback) =>
    {device} = meshbluAuth
    {encryptedToken,encryptedFileId} = device.box
    return callback @_createError 422, 'Invalid Device' unless encryptedFileId?
    return callback @_createError 422, 'Invalid Device' unless encryptedToken?
    meshbluHttp = new MeshbluHttp @meshbluConfig
    privateKey = meshbluHttp.setPrivateKey @meshbluConfig.privateKey
    fileId = privateKey.decrypt(encryptedFileId).toString()
    token = privateKey.decrypt(encryptedToken).toString()

    options =
      baseUrl: @boxServiceUri
      uri: "/files/#{fileId}"
      auth:
        bearer: token
      json: true

    request.post options, (error, response, body) =>
      return callback @_createError 500, error.message if error?
      return callback @_createError response.statusCode, body if response.statusCode > 299
      meshbluHttp = new MeshbluHttp meshbluAuth
      meshbluHttp.unregister uuid: meshbluAuth.uuid, (error) =>
        return callback @_createError 500, error.message if error?
        callback null, request.get body.url

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = boxLinkService
