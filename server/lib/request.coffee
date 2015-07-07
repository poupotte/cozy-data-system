db = require('../helpers/db_connect_helper').db_connect()
async = require 'async'
request = {}
log = require('printit')
    date: true
    prefix: 'lib/request'

# Define random function for application's token
randomString = (length) ->
    string = ""
    while (string.length < length)
        string = string + Math.random().toString(36).substr(2)
    return string.substr 0, length

productionOrTest = process.env.NODE_ENV is "production" or
    process.env.NODE_ENV is "test"


module.exports.viewAll = viewAll = (docType, cb) ->
    options =
        startkey: docType
        endkey: docType
        include_docs: true
        reduce: false
    db.view 'all/bydoctype', options, cb

## function create (app, req, views, newView, callback)
## @app {String} application name
## @req {Object} contains type and request name
## @views {Object} contains all existing view for this type
## @newView {Object} contains function map/reduce of new view
## @callback {function} Continuation to pass control back to when complete.
## Store new view with name <app>-request name in case of conflict
## Callback view name (req.req_name or name-req.req_name)
module.exports.create = (app, req, views, newView, callback) =>
    storeRam = (path) =>
        request[app] ?= {}
        request[app]["#{req.type}/#{req.req_name}"] = path
        callback null, path

    if productionOrTest
        # If classic view already exists and view is different :
        # store in app-req.req_name
        if views?[req.req_name]? and
                JSON.stringify(views[req.req_name]) isnt JSON.stringify(newView)
            storeRam "#{app}-#{req.req_name}"
        else
            # Else store view in classic path (req.req_name)
            if views?["#{app}-#{req.req_name}"]?
                # If views app-req.req_name exists, remove it.
                delete views["#{app}-#{req.req_name}"]
                db.merge "_design/#{req.type}", views: views, \
                (err, response) ->
                    if err
                        log.error "[Definition] err: " + err.message
                    storeRam req.req_name
            else
                storeRam req.req_name
    else
        callback null, req.req_name


## function get (app, req, callback)
## @app {String} application name
## @req {Object} contains type and request name
## @callback {function} Continuation to pass control back to when complete.
## Callback correct request name
module.exports.get = (app, req, callback) =>
    if req.req_name is 'all'
        callback "byDocType"
    else if productionOrTest
        if request[app]?["#{req.type}/#{req.req_name}"]?
            callback request[app]["#{req.type}/#{req.req_name}"]
        else
            callback "#{req.req_name}"
    else
        callback "#{req.req_name}"


## Helpers for init function ##

## function recoverApp (callback)
## @callback {function} Continuation to pass control back to when complete.
## Callback all application names from database
recoverApp = (callback) =>
    apps = []
    viewAll 'application', (err, res) =>
        if err
            callback err
        else if not res
            callback null, []
        else
            res.forEach (app) =>
                apps.push app.name
            callback null, apps

## function recoverDocs (callback)
## @res {tab} design docs without views
## @docs {tab} design docs with view
## @callback {function} Continuation to pass control back to when complete.
## Callback all design documents from database
recoverDocs = (res, docs, callback) =>
    if res and res.length isnt 0
        doc = res.pop()
        db.get doc.id, (err, result) =>
            docs.push(result)
            recoverDocs res, docs, callback
    else
        callback null, docs

## function recoverDocs (callback)
## @callback {function} Continuation to pass control back to when complete.
## Callback all design documents from database
recoverDesignDocs = (callback) =>
    filterRange =
        startkey: "_design/"
        endkey: "_design0"
    db.all filterRange, (err, res) =>
        return callback err if err?
        recoverDocs res, [], callback


# Data system uses some views, this function initialize it.
initializeDSView = (callback) ->
    views =
        all:
            bydoctype: 
                map:"""
                    function(doc) {
                        if(doc.docType) {
                            return emit(doc.docType.toLowerCase(), doc._id)
                        }
                    }
                    """
                # use to make a "distinct"
                reduce: """
                function(key, values) {
                    return true;
                }
                """
            withoutdoctype:
                map: """
                function(doc) {
                    if (!doc.docType) {
                        return emit(doc._id, doc);
                    }
                }
                """
        # Usefull to manage device access
        device:
            bylogin:
                map: """
                function (doc) {
                    if(doc.docType && doc.docType.toLowerCase() === "device") {
                        return emit(doc.login, doc)
                    }
                }
                """
        # Usefull to manage application access
        application:
            byslug:
                map: """
                function(doc) {
                    if(doc.docType && doc.docType.toLowerCase() === "application") {
                        return emit(doc.slug, doc);
                    }
                }
                """
        # Usefull to manage access
        access:
            byapp:
                map: """
                function(doc) {
                    if(doc.docType && doc.docType.toLowerCase() === "access") {
                        return emit(doc.app, doc);
                    }
                }
                """

        # Usefull to remove binary lost
        binary:
            bydoc:
                map: """
                function(doc) {
                    if(doc.binary) {
                        for (bin in doc.binary) {
                            emit(doc.binary[bin].id, doc._id);
                        }
                    }
                }
                """
        # Usefull for thumbs creation
        file:
            withoutthumb:
                map: """
                function(doc) {
                    if(doc.docType && doc.docType.toLowerCase() === "file") {
                        if(doc.class === "image" && doc.binary && doc.binary.file && !doc.binary.thumb) {
                            emit(doc._id, null);
                        }
                    }
                }
                """
        # Usefull for API tags
        tags:
            list:
                map: """
                function (doc) {
                var _ref;
                return (_ref = doc.tags) != null ? typeof _ref.forEach === "function" ? _ref.forEach(function(tag) {
                   return emit(tag, null);
                    }) : void 0 : void 0;
                }
                """
                # use to make a "distinct"
                reduce: """
                function(key, values) {
                    return true;
                }
                """
    async.forEach Object.keys(views), (docType, cb) ->
        view = views[docType]
        db.get "_design/#{docType}", (err, doc) ->
            if err and err.error is 'not_found'
                db.save "_design/#{docType}", view, cb
            else if err
                log.error err
                cb()
            else
                for type in Object.keys(view)
                    doc.views[type] = view[type]
                db.save "_design/#{docType}", doc, cb
    , callback


## function init (callback)
## @callback {function} Continuation to pass control back to when complete.
## Initialize request
module.exports.init = (callback) =>
    removeEmptyView = (doc, callback) ->
        if Object.keys(doc.views).length is 0 or not doc?.views?
            db.remove doc._id, doc._rev, (err, response) ->
                if err
                    log.error "[Definition] err: " + err.message
                callback err
        else
            callback()

    storeAppView = (apps, doc, view, body, callback) ->
        # Search if view start with application name
        # Views as <name>-
        if view.indexOf('-') isnt -1
            # Link view and app in RAM
            #   -> Linked to an application
            if view.split('-')[0] in apps
                app = view.split('-')[0]
                type = doc._id.substr 8, doc._id.length-1
                req_name = view.split('-')[1]
                request[app] = {} if not request[app]
                request[app]["#{type}/#{req_name}"] = view
                callback()
            else
                # Remove view
                #   -> linked to an undefined application
                delete doc.views[view]
                db.merge doc._id, views: doc.views, \
                (err, response) ->
                    if err
                        log.error "[Definition] err: " +
                            err.message
                    removeEmptyView doc, (err) ->
                        log.error err if err?
                        callback()
        else
            callback()

    # Initialize view used by data-system
    initializeDSView ->
        if productionOrTest
            # Recover all applications in database
            recoverApp (err, apps) =>
                return callback err if err?
                # Recover all design docs in database
                recoverDesignDocs (err, docs) =>
                    return callback err if err?
                    async.forEach docs, (doc, cb) ->
                        async.forEach Object.keys(doc.views), (view, cb) ->
                            body = doc.views[view]
                            storeAppView apps, doc, view, body, cb
                        , (err) ->
                            removeEmptyView doc, (err) ->
                                log.error err if err?
                                cb()
                    , (err) ->
                        log.error err if err?
                        callback()
        else
            callback null

removeOldView = (designDoc, view) ->
    delete designDoc.views[view]
    if Object.keys(designDoc.views).length is 0
        db.remove designDoc._id, designDoc._rev, callback
    else
        db.merge designDoc._id, views: designDoc.views, callback

isSimilare = (sharedView, appView) ->
    warning = 2

    if appView.indexOf 'filter' isnt -1
        appView = appView.replace 'filter = function (doc) {\n', ''
        appView = appView.replace '};\n    filter(doc);\n', ''
    if sharedView.indexOf 'filter(doc)' isnt -1
        sharedView = sharedView.replace 'filter = function (doc) {\n', ''
        sharedView = sharedView.replace '};\n    filter(doc);\n', ''
    appView = appView.replace /\ /g, ''
    appView = appView.replace /\n/g, ''
    sharedView = sharedView.replace /\ /g, ''
    sharedView = sharedView.replace /\n/g, ''

    # Check docType
    if sharedView.indexOf('doc.docType&&') isnt -1
        sharedView = sharedView.replace 'doc.docType&&', ''
        warning = 1
    if appView.indexOf('doc.docType&&') isnt -1
        appView = appView.replace 'doc.docType&&', ''
        warning = 2

    # Use _ for temporary variables
    if sharedView.indexOf('_') isnt -1
        sharedView = sharedView.replace /_/g, ''

    if appView.indexOf('_') isnt -1
        appView = appView.replace /_/g, ''

    # Check lowerCase docType
    if sharedView.indexOf('.toLowerCase') isnt -1
        sharedView = sharedView.replace('.toLowerCase()', '').toLowerCase()
        appView = appView.toLowerCase()
        warning = 1

    if appView.indexOf('.toLowerCase') isnt -1
        appView = appView.replace('.toLowerCase()', '').toLowerCase()
        sharedView = sharedView.toLowerCase()
        warning = 2

    # Compare two views
    if sharedView.toString() is appView.toString()
        return [true, warning]
    else
        console.log '  ->  ', sharedView
        console.log '  ->  ', appView
        return [false, null]

exports.removeOldViews = (callback) ->
    # TODOS : Remove old device view
    # TODOS : tasky-byorder / byorder (même vue mais avec 2 versions : garder byorder)
    count = 0
    total = 0
    viewAll 'application', (err, docs) ->
        return callback err if err
        apps = docs.map (app) -> return app.slug
        db.all {startkey:"_design", endkey:"_design0", include_docs:true}, (err, designDocs) ->
            async.forEachSeries designDocs, (designDoc, next) =>
                designDoc = designDoc.doc
                console.log '\n', designDoc._id
                async.forEachSeries Object.keys(designDoc.views), (type, cb) =>
                    total += 1
                    console.log ' ->', type
                    if type is 'all' or type is 'dball'
                        removeOldView designDoc, type, () ->
                            console.log '  -> REMOVE (all views)'
                            count +=1
                    else if type.indexOf('-') isnt -1
                        console.log '  -> specific view for application'
                        if type.split('-')[0] in apps
                            if type.split('-')[1] is 'all'
                                console.log '  -> REMOVE (all views)'
                                count +=1
                            else
                                console.log '  -> check similarity with other'
                                sharedView = designDoc.views[type.split('-')[1]].map.toString()
                                appView = designDoc.views[type].map.toString()
                                if appView.indexOf 'filter' isnt -1
                                    appView = appView.replace 'filter = function (doc) {\n', ''
                                    appView = appView.replace '};\n    filter(doc);\n', ''
                                if sharedView.indexOf 'filter(doc)' isnt -1
                                    sharedView = sharedView.replace 'filter = function (doc) {\n', ''
                                    sharedView = sharedView.replace '};\n    filter(doc);\n', ''
                                appView = appView.replace /\ /g, ''
                                appView = appView.replace /\n/g, ''
                                sharedView = sharedView.replace /\ /g, ''
                                sharedView = sharedView.replace /\n/g, ''
                                if sharedView.indexOf('doc.docType&&') isnt -1 or appView.indexOf('doc.docType&&') isnt -1
                                    sharedView = sharedView.replace 'doc.docType&&', ''
                                    appView = appView.replace 'doc.docType&&', ''
                                    console.log 'Warning : docType check'
                                if sharedView.indexOf('_') isnt -1 or appView.indexOf('_') isnt -1
                                    sharedView = sharedView.replace /_/g, ''
                                    appView = appView.replace /_/g, ''
                                    console.log 'Warning : ___'
                                if sharedView.indexOf('.toLowerCase') isnt -1 or appView.indexOf('.toLowerCase') isnt -1 
                                    sharedView = sharedView.replace('.toLowerCase()', '').toLowerCase()
                                    appView = appView.replace('.toLowerCase()', '').toLowerCase()
                                    console.log 'Warning : docType toLowerCase'
                                if sharedView.toString() is appView.toString()
                                    count += 1
                                    console.log '  -> REMOVE (same view)'
                                else
                                    console.log '  ->  ', sharedView
                                    console.log '  ->  ', appView
                                    console.log '  -> ????'

                        else
                            console.log 'remove : old application'
                            count +=1
                    else
                        console.log '   -> OK'
                    cb()
                , next
            , () ->
                console.log 'END'
                console.log "#{count}/#{total}"

appIsInstalled = (currentApps, apps) ->
    if currentApps.length > 0
        app = currentApps.pop()
        if app in apps
            return true
        else
            return appIsInstalled currentApps, apps
    else
        return false

exports.removeOldAppViews = (callback) ->
    count = 0
    total = 0
    all = 0
    remove = 0
    duplicateUninstalled = 0
    count_similare = 0
    duplicateInstalled = 0
    views = require('./viewsApp').views
    viewAll 'application', (err, docs) ->
        return callback err if err
        apps = docs.map (app) -> return app.slug
        apps.push "home"
        apps.push "ds"
        db.all {startkey:"_design", endkey:"_design0", include_docs:true}, (err, designDocs) ->
            async.forEachSeries designDocs, (designDoc, next) =>
                designDoc = designDoc.doc
                console.log '\n', designDoc._id
                async.forEachSeries Object.keys(designDoc.views), (type, cb) =>
                    total += 1
                    console.log ' ->', type
                    docType = designDoc._id.replace('_design/', '')
                    console.log type, docType
                    if views[docType]?[type]?
                        console.log views[docType][type]
                        if appIsInstalled views[docType][type], apps
                            console.log 'OK -> '
                        else
                            console.log 'FALSE -> '
                            remove += 1
                    else
                        if type is 'all' or type is 'dball'
                            all += 1
                        else
                            if type.split('-').length > 1
                                if type.split('-')[1] is 'all'
                                    all += 1
                                else
                                    if appIsInstalled [type.split('-')[0]], apps
                                        duplicateInstalled += 1
                                        sharedView = designDoc.views[type.split('-')[1]].map.toString()
                                        appView = designDoc.views[type].map.toString()
                                        [similare, warning] = isSimilare sharedView, appView
                                        if similare
                                            count_similare += 1
                                    else
                                        duplicateUninstalled += 1
                            else
                                console.log 'UNKONWN'
                                count += 1
                    cb()
                , next
            , () ->
                console.log apps
                console.log 'END'
                console.log 'all/dball: ', all
                console.log 'duplicateUninstalled: ', duplicateUninstalled
                console.log 'duplicateInstalled: ', duplicateInstalled
                console.log 'similare', count_similare
                console.log 'oldApp: ', remove
                console.log 'unknown: ', count
                toRemove = all + count_similare + remove
                console.log "to remove: ", toRemove
                mount = toRemove + unknown
                console.log "to remove with unknown: ", mount
                console.log "total: ", total