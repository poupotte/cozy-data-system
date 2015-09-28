log = require('printit')
    date: true
    prefix: 'lib/init'

db = require('../helpers/db_connect_helper').db_connect()
quota = process.env.QUOTA
warning = process.env.WARNING
isEnough = true
SECOND = 1000
MINUTE = 60 * SECOND
count = 0
COUNT_WRITE = 100
COUNT_TIME = 5 * MINUTE

# TODOS :
# Count views : '<db>/_design/<view>/_info'  -> data_size (vs disk_size)


# Check disk space
checkDiskSpace = ->
    db.get '', (err, database) ->
        percentage = database.data_size/quota
        if database.data_size > quota
            if isEnough
                # TODOS: Display a pop-up !!!
                isEnough = false
                doc =
                    ref: 'warning_ds_enough'
                    app: 'home'
                    text: "WARNING : You have already use 100% of Cozy size : you can't write anymore"
                    docType: "Notification"
                    type: ""
                    publishDate: Date.now()
                db.save doc, (err, doc) ->
                    log.error err if err?
        else
            isEnough = true
            percentage = 100 * percentage
            if percentage > warning
                db.view 'notification/all', (err, docs) ->
                    for doc in docs
                        doc = doc.value
                        if doc.ref = 'warning_ds'
                            # Notification already exists
                            doc.text = "WARNING: You have already used #{Math.round(percentage)}% of Cozy space."
                            return db.save doc, (err, doc) ->
                                log.error err if err?
                    # Create a new notification
                    doc =
                        ref: 'warning_ds'
                        app: 'home'
                        text: "WARNING: You have already used #{Math.round(percentage)}% of Cozy space."
                        docType: "Notification"
                        type: "permanent"
                        publishDate: Date.now()
                    db.save doc, (err, doc) ->
                        log.error err if err?

# Initialize loop to check disk space
module.exports.init = () ->
    if quota
        checkDiskSpace()
        setTimeout checkDiskSpace, COUNT_TIME

# Check if user has enough disk space to write :
# Return error if user can't write in his Cozy
module.exports.check = (req, res, next) ->
    addWrite()
    if isEnough
        next()
    else
        err = new Error 'Not enough disk space'
        next err

# Count number of written operation
# Check disk space if necessary
addWrite = module.exports.addWrite = () ->
    # Increment counter
    count = count + 1
    if count > COUNT_WRITE
        if quota
            # Check disk space after COUNT_WRITE written
            checkDiskSpace()
        count = 0
