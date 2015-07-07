
db = require('../helpers/db_connect_helper').db_connect()


# Prepare the deletion doc. It's required to make couch raised the required
# events.
getDeletedDoc = (doc) ->
    _id: doc._id
    _rev: doc._rev
    _deleted: true
    docType: doc.docType
    binary: doc.binary


# Remove givend document.
exports.remove = (doc, callback) =>
    deletedDoc = getDeletedDoc doc
    db.save doc._id, deletedDoc, callback


# Take advantage of bulk update to delete a batch of docs.
exports.removeAll = (docs, callback) =>
    console.log docs
    deletedDocs = []
    for doc in docs
        if doc.doc?
            doc = doc.doc
        else
            doc = doc.value
        console.log doc
        deletedDocs.push getDeletedDoc doc

    db.save deletedDocs, callback
