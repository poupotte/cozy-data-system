async = require "async"
feed = require '../lib/feed'
db = require('../helpers/db_connect_helper').db_connect()
request = require '../lib/request'
default_filter = require '../lib/default_filter'
dbHelper = require '../lib/db_remove_helper'
utils = require '../middlewares/utils'
{getProxy} = require '../lib/proxy'
fs = require 'fs'
S = require 'string'

## Helpers ##

# Define random function for application's token
randomString = (length) ->
    string = ""
    while (string.length < length)
        string = string + Math.random().toString(36).substr(2)
    return string.substr 0, length
## Actions

# POST /device
module.exports.create = (req, res, next) ->
    # Create device
    device =
        login: req.body.login
        password: randomString 32
        docType: "Device"
        configuration:
            "File": "all"
            "Folder": "all"
    # Check if an other device hasn't the same name
    db.view 'device/byLogin', key: device.login, (err, response) ->
        if err
            next err
        else if response.length isnt 0
            err = new Error "This name is already used"
            err.status = 400
            next err
        else
            db.save device, (err, docInfo) ->
                if err?
                    next new Error err
                else
                    res.send 200, device

# DELETE /device/:id
module.exports.remove = (req, res, next) ->
    send_success = () ->
        # status code is 200 because 204 is not transmit by httpProxy
        res.send 200, success: true
        next()
    id = req.params.id
    db.remove "_design/#{id}", (err, response) ->
        if err?
            console.log "[Definition] err: " + JSON.stringify err
            next new Error err.error
            next()
        else
            dbHelper.remove req.doc, (err, response) ->
                if err?
                    console.log "[Definition] err: " + JSON.stringify err
                    next new Error err.error
                else
                    send_success()

getCredentialsHeader = ->
    data = fs.readFileSync '/etc/cozy/couchdb.login'
    lines = S(data.toString('utf8')).lines()
    credentials = "#{lines[0]}:#{lines[1]}"
    basicCredentials = new Buffer(credentials).toString 'base64'
    return "Basic #{basicCredentials}"

module.exports.replication = (req, res, next) ->
    # Check permissions
    auth = false
    check_after = false
    error = ""
    if req.params?[0] is '_changes' or
        req.params?[0] is '_local' or
        req.params?[0].indexOf('?_nonce') isnt -1
            auth = true
    else
        switch req.method
            when 'GET'
                auth = true
                check_after = true
                #console.log "test after request"
            when 'POST'
                #console.log "test before"
                utils.checkPermissionsByBody req, res, (err) ->
                    error = err
                    auth = true if not err?
            when 'PUT'
                #console.log "test before"
                utils.checkPermissionsByBody req, res, (err) ->
                    error = err
                    auth = true if not err?
                check_after = true
                #console.log "test after request"
            when 'DELETE'
                #console.log "test before"
                utils.checkPermissionsByBody req, res, (err) ->
                    error = err
                    auth = true if not err?
    if auth
        current_req  = req.headers['authorization']
        # Change couchDB authentication
        if process.env.NODE_ENV is "production"
            req.headers['authorization'] = getCredentialsHeader()
        else
            # Do not forward 'authorization' header in other environments
            # in order to avoid wrong authentications in CouchDB
            req.headers['authorization'] = null
        if check_after
            #res.writeHead = (status, reason, headers) =>
            #    console.log status
            res.write = (data, encoding) ->
                json = JSON.parse data.toString('utf8')
                if json.docType?
                    req.params.type = json.docType
                    req.headers["authorization"] = current_req
                    utils.checkPermissionsByType req, res, (err) =>
                        if err?
                            #console.log res.headers
                            # error : Can't set headers after they are sent.
                            # http://stackoverflow.com/questions/22487048/node-js-http-proxy-modify-body

                            # TODOS : utiliser le même principe partout ???? (à la place de utils)
                            #console.log next
                            next err
                            #res.send err, 401
                        else
                            #next()
                            res.end.call res, data
                else
                    #next()
                    res.end.call res, data

        getProxy().web req, res, target: "http://localhost:5984"
    else
        next error
