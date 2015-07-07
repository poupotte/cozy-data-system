async = require "async"

db = require('../helpers/db_connect_helper').db_connect()
request = require '../lib/request'
encryption = require '../lib/encryption'
dbHelper = require '../lib/db_remove_helper'
errors = require '../middlewares/errors'
util = require 'util'

log = require('printit')
    prefix: 'requests'

## Actions

# GET /doctypes
# list all doctypes that have been created
# a doctype is a design document with a "all" request
module.exports.doctypes = (req, res, next) ->

    query = group: true
    out = []

    db.view "all/bydoctype", query, (err, docs) ->
        if err
            next err
        else
            docs.forEach (key, row, id) -> out.push key
            res.send 200, out

# GET /tags
# list all tags
# tags are item of a tags:[] field
module.exports.tags = (req, res, next) ->

    query = group: true
    out = []

    db.view "tags/list", query, (err, docs) ->
        if err
            next err
        else
            docs.forEach (key, row, id) -> out.push key
            res.send 200, out

# POST /request/:type/:req_name/
module.exports.results = (req, res, next) ->
    if req.params.req_name is 'all'
        req.body.startkey = req.params.type
        req.body.endkey = req.params.type
        req.body['include_docs'] = true
        req.body.reduce = false
        req.params.type = 'all'
    request.get req.appName, req.params, (path) ->
        db.view "#{req.params.type}/" + path, req.body, (err, docs) ->
            if "#{req.params.type}/" + path is "all/bydoctype"
                for doc in docs
                    doc.value = doc.doc
                    delete doc.doc
            if err
                log.error err
                next err
            else if util.isArray(docs)
                docs.forEach (value) ->
                    delete value._rev # CouchDB specific, user don't need it
                    if value.password? and not (
                        value.docType?.toLowerCase() is "user")
                        try
                            password = encryption.decrypt value.password
                        catch error
                            # do nothing to prevt error in apps
                            # todo add a way to send a warning in the http response

                        value.password = password if not err?
                res.send docs
            else
                res.send docs

# PUT /request/:type/:req_name/destroy/
module.exports.removeResults = (req, res, next) ->

    options = JSON.parse JSON.stringify req.body
    options.limit = 100
    viewName = null

    delFunc = ->
        console.log "delFunc"
        db.view viewName, options, (err, docs) ->
            console.log "endRequest"
            if err
                if err.error is "not_found"
                    next errors.http 404, "Request #{viewName} was not found"
                else
                    log.error "Deletion by request failed for #{viewName}"
                    log.error err
                    # The fact that no docs with the proper key exsits raised
                    # an error. But that's what we are seeking for: removing
                    # all docs. That's why we ignore the error.
                    if options.startkey?
                        res.send 204, success: true
                    else
                        next err
            else
                if docs.length > 0
                    console.log 'if'
                    # Put a timeout to give some breath because each doc
                    # deletion raises an event.
                    dbHelper.removeAll docs, ->
                        console.log "removeAll"
                        setTimeout delFunc, 500
                else
                    res.send 204, success: true

    request.get req.appName, req.params, (path) ->
        viewName = "#{req.params.type}/#{path}"
        if req.params.req_name is 'all'
            viewName = "all/bydoctype"
            options.startkey = req.params.type
            options.endkey = req.params.type
            options['include_docs'] = true
            options.reduce = false
        delFunc()


# PUT /request/:type/:req_name/
module.exports.definition = (req, res, next) ->
    # no need to precise language because it's javascript
    if req.params.req_name is 'all'
        # Use all/byDocTypes
        index = req.body.map.indexOf('emit')
        emit =  req.body.map.substring(index, index + 12)
        if emit is 'emit(doc._id'
            res.send 200, succeess:true
        else
            err = new Error 'All view should emit doc._id'
            err.status = 400
            next err
    else
        db.get "_design/#{req.params.type}", (err, docs) ->
            if err && err.error is 'not_found'
                design_doc = {}
                design_doc[req.params.req_name] = req.body
                db.save "_design/#{req.params.type}", design_doc, (err, response) ->
                    if err
                        console.log "[Definition] err: " + JSON.stringify err
                        next err
                    else
                        res.send 200, success: true
                        next()

            else if err
                next err

            else
                views = docs.views
                request.create req.appName, req.params, views, req.body, \
                (err, path) ->
                    views[path] = req.body
                    db.merge "_design/#{req.params.type}", views: views, \
                    (err, response) ->
                        if err
                            console.log "[Definition] err: " + JSON.stringify err
                            next err
                        else
                            res.send 200, success: true
                            next()

# DELETE /request/:type/:req_name
module.exports.remove = (req, res, next) ->
    db.get "_design/#{req.params.type}", (err, docs) ->
        if err and err.error is 'not_found'
            next errors.http 404, "Not Found"
        else if err
            next err
        else
            views = docs.views
            request.get req.appName, req.params, (path) ->
                if path is "#{req.params.req_name}"
                    res.send 204, success: true
                    next()
                else
                    delete views["#{path}"]
                    db.merge "_design/#{req.params.type}", views: views, \
                    (err, response) ->
                        if err
                            console.log "[Definition] err: " + err.message
                            next err
                        else
                            res.send 204, success: true
                            next()
