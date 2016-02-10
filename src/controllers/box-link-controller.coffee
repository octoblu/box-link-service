class boxLinkController
  constructor: ({@boxLinkService}) ->

  generate: (request, response) =>
    {token} = request
    {fileId} = request.params
    {fileName} = request.body
    return response.sendStatus(422) unless fileId?
    return response.sendStatus(422) unless token?

    @boxLinkService.generate {token, fileId, fileName}, (error, body) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      response.status(201).send body

  download: (request, response) =>
    {meshbluAuth} = request
    @boxLinkService.download {meshbluAuth}, (error, requestStream) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      requestStream.pipe response

module.exports = boxLinkController
