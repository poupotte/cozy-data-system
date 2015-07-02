log = require('printit')
    date: true
    prefix: 'lib/init'

db = require('../helpers/db_connect_helper').db_connect()
async = require 'async'
permissionsManager = require './token'
thumb = require('./thumb')
initTokens = require('./token').init


defaultPermissions =
    'File':
        'description' : 'Usefull to synchronize your files',
    'Folder':
        'description' : 'Usefull to synchronize your folder',
    'Notification':
        'description' : 'Usefull to synchronize your notification'
    'Binary':
        'description' : 'Usefull to synchronize your files'


# Get all lost binaries
#    A binary is considered as lost when isn't linked to a document.
getLostBinaries = exports.getLostBinaries = (callback) ->
    lostBinaries = []
    # Recover all binaries
    db.view 'binary/all', (err, binaries) ->
        if not err and binaries.length > 0
            # Recover all binaries linked to a/several document(s)
            db.view 'binary/byDoc', (err, docs) ->
                if not err and docs?
                    keys = []
                    for doc in docs
                        keys[doc.key] = true
                    for binary in binaries
                        # Check if binary is linked to a document
                        unless keys[binary.id]?
                            lostBinaries.push binary.id
                    callback null, lostBinaries
                else
                    callback null, []
        else
            callback err, []

# Remove binaries not linked with a document
exports.removeLostBinaries = (callback) ->
    # Recover all lost binaries
    getLostBinaries (err, binaries) ->
        return callback err if err?
        async.forEachSeries binaries, (binary, cb) =>
            log.info "Remove binary #{binary}"
            # Retrieve binary and remove it
            db.get binary, (err, doc) =>
                if not err and doc
                    db.remove doc._id, doc._rev, (err, doc) =>
                        log.error err if err
                        cb()
                else
                    log.error err if err
                    cb()
        , callback

# Patch 01/06/15
exports.addAccesses = (callback) ->
    addAccess = (docType, cb) ->
        db.view "#{docType}/all", (err, apps) ->
            return cb(err) if err? or apps.length is 0
            async.forEachSeries apps, (app, cb) ->
                # Check if access exists
                app = app.value
                db.view 'access/byApp', key:app._id, (err, accesses) ->
                    return cb(err) if err? or accesses.length > 0
                    if accesses?.length is 0
                        # Create it if necessary
                        if docType is "device"
                            app.permissions = defaultPermissions
                        permissionsManager.addAccess app, (err, access) ->
                            delete app.password
                            delete app.token
                            delete app.permissions
                            # Remove access information
                            # from application/device document
                            db.save app, (err, doc) ->
                                log.error err if err?
                                cb()
                    else
                        cb()
            , cb

    # Add access for all applications and devices
    addAccess 'application', (err) ->
        log.error err if err?
        addAccess 'device', (err) ->
            log.error err if err?
            # Initialize application access.
            initTokens (tokens, permissions) =>
                callback() if callback?

# Add thumbs for images without thumb
exports.addThumbs = (callback) ->
    # Retrieve images without thumb
    db.view 'file/withoutThumb', (err, files) ->
        if err
            callback err

        else if files.length is 0
            callback()

        else
            async.forEachSeries files, (file, cb) =>
                # Create thumb
                db.get file.id, (err, file) =>
                    if err
                        log.info "Cant get File #{file.id} for thumb"
                        log.info err
                        return cb()
                    thumb.create file, false
                    cb()
            , callback

exports.removeDocWithoutDocType = (callback) ->
    db.view 'withoutDocType/all', (err, docs) ->
        if err
            callback err

        else if docs.length is 0
            callback()

        else
            async.forEachSeries docs, (doc, cb) =>
                # Create thumb
                db.remove doc.value._id, doc.value._rev, (err, doc) =>
                    log.error err if err
                    cb()
            , callback

exports.removeOldAppView = (callback) ->
    # TODOS : Remove old device view
    # TODOS : dball ????
    # TODOS : all : check emit(doc._id, doc) => bloquer les autres
    # TODOS : docType toLowerCase / doc.docType&&
    # TODOS : on peut merger celle qui sont map/reduce & map seul, si on ajoute le paramètre ?reduce=false
    # TODOS : _ref vs ref
    count = 0
    total = 0
    db.view 'application/all', (err, docs) ->
        return callback err if err
        apps = docs.map (app) -> return app.slug
        apps.push 'home'
        apps.push 'proxy'
        console.log apps
        db.all {startkey:"_design", endkey:"_design0", include_docs:true}, (err, designDocs) ->
            async.forEachSeries designDocs, (designDoc, next) =>
                designDoc = designDoc.doc
                console.log '\n'
                async.forEachSeries Object.keys(designDoc.views), (type, cb) =>
                    total += 1
                    console.log designDoc._id, type
                    if type is 'all' or type is 'dball'
                        console.log '  -> REMOVE (all views)'
                        count +=1
                    else if type.indexOf('-') isnt -1
                        console.log '  -> specific view for application'
                        if type.split('-')[0] in apps
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


#removeOldView = (callback) ->
