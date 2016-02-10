BoxLinkController = require './controllers/box-link-controller'
bearerToken           = require 'express-bearer-token'
meshbluAuth           = require 'express-meshblu-auth'
class Router
  constructor: ({@boxLinkService, @meshbluConfig}) ->
  route: (app) =>
    boxLinkController = new BoxLinkController {@boxLinkService}
    app.use '/box', bearerToken()
    app.use '/meshblu', meshbluAuth(@meshbluConfig)

    app.post '/box/links/:fileId', boxLinkController.generate
    app.get '/meshblu/links', boxLinkController.download
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
