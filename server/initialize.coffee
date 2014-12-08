module.exports = (app, server, callback) ->
    feed = require './lib/feed'
    feed.initialize server

    proxy = require './lib/proxy'
    proxy.initializeProxy()

    db = require './lib/db'
    db -> callback app, server if callback?
