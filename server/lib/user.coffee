db = require('../helpers/db_connect_helper').db_connect()
request = require './request'


module.exports = class User


    getUser: (callback) ->
        request.viewAll 'user', (err, res) =>
            if err
                callback err
            else
                if res.length > 0
                    callback null, res[0].doc
                else
                    callback new Error("No user found")
