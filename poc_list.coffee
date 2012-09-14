should = require('chai').Should()
async = require('async')
Client = require('./common/test/client').Client
app = require('./server')

client = new Client("http://localhost:8888/")

# connection to DB for "hand work"
cradle = require 'cradle'
connection = new cradle.Connection
    cache: false,
    raw: false
db = connection.database('poc-list')

randomString = (length=32) ->
    string = ""
    string += Math.random().toString(36).substr(2) while string.length < length
    string.substr 0, length

# Clear DB, create a new one, then init data for tests.
initDB = (cb) ->
    db.destroy ->
        console.log 'DB destroyed'
        db.create ->
            console.log 'DB recreated'
            docs = ({'type':'dumb_doc', 'num':num} for num in [0..10])
            db.save docs, ->
                cb()

initDB ->
    db.all {include_docs: true}, (err, res) ->
        console.log err if err?
        console.log JSON.stringify res, null, 4 if res?
