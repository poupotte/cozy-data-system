# See documentation on https://github.com/frankrousseau/americano#routes

data = require './data'
requests = require './requests'
attachments = require './attachments'
binaries = require './binaries'
connectors = require './connectors'
indexer = require './indexer'
mails = require './mails'
user = require './user'
account = require './accounts'
access = require './access'
replication = require './replication'
disk = require('../lib/disk_space')

utils = require '../middlewares/utils'

module.exports =

    # Information page
    '':  get: data.index

    # Data management
    'data/': post: [
            utils.checkPermissionsByBody
            disk.check
            data.encryptPassword
            data.create
        ]
    'data/:id/':
        get: [
            utils.getDoc
            utils.checkPermissionsByDoc
            data.decryptPassword
            data.find
        ]
        post: [
            utils.checkPermissionsByBody
            disk.check
            data.encryptPassword
            data.create
        ]
        put: [
            utils.lockRequest
            utils.checkPermissionsByBody
            utils.getDoc
            disk.check
            data.encryptPassword
            data.update
            utils.unlockRequest
        ]
        delete: [
            utils.lockRequest
            utils.getDoc
            utils.checkPermissionsByDoc
            disk.addWrite
            data.delete
            utils.unlockRequest
        ]
    'data/exist/:id/': get: data.exist
    'data/upsert/:id/': put: [
        utils.lockRequest
        utils.checkPermissionsByBody
        disk.check
        data.encryptPassword
        data.upsert
        utils.unlockRequest
    ]
    'data/merge/:id/': put: [
        utils.lockRequest
        utils.checkPermissionsByBody
        disk.check
        utils.getDoc
        utils.checkPermissionsByDoc
        data.encryptPassword
        data.merge
        utils.unlockRequest
    ]

    # Requests management
    'request/:type/:req_name/':
        post: [utils.checkPermissionsByType, requests.results]
        put: [
            utils.checkPermissionsByType
            utils.lockRequest
            disk.check
            requests.definition
            utils.unlockRequest
        ]
        delete: [
            utils.checkPermissionsByType
            utils.lockRequest
            disk.addWrite
            requests.remove
            utils.unlockRequest
        ]
    'request/:type/:req_name/destroy/': put: [
        utils.checkPermissionsByType
        requests.removeResults
    ]

    # Tags API
    'tags': get: requests.tags

    # Doctypes API
    'doctypes': get: requests.doctypes

    # File management
    # attachment API is deprecated
    'data/:id/attachments/': post: [
        utils.lockRequest
        utils.getDoc
        utils.checkPermissionsByDoc
        disk.check
        attachments.add
        utils.unlockRequest
    ]
    'data/:id/attachments/:name':
        get: [utils.getDoc, utils.checkPermissionsByDoc, attachments.get]
        delete: [
            utils.lockRequest
            utils.getDoc
            utils.checkPermissionsByDoc
            disk.addWrite
            attachments.remove
            utils.unlockRequest
        ]

    'data/:id/binaries/convert': get: [
        utils.lockRequest
        utils.getDoc
        utils.checkPermissionsByDoc
        binaries.convert
        utils.unlockRequest
    ]

    'data/:id/binaries/': post: [
        utils.lockRequest
        utils.getDoc
        utils.checkPermissionsByDoc
        disk.check
        binaries.add
        utils.unlockRequest
    ]
    'data/:id/binaries/:name':
        get: [utils.getDoc, utils.checkPermissionsByDoc, binaries.get]
        delete: [
            utils.lockRequest
            utils.getDoc
            utils.checkPermissionsByDoc
            disk.addWrite
            binaries.remove
            utils.unlockRequest
        ]

    # Scrapper connectors
    'connectors/bank/:name/': post: connectors.bank
    'connectors/bank/:name/history': post: connectors.bankHistory

    # Access management
    'access/': post: [utils.checkPermissionsFactory('access'), 
            disk.check, access.create]
    'access/:id/':
        'put': [utils.checkPermissionsFactory('access'), 
            disk.check, access.update]
        'delete': [
            utils.checkPermissionsFactory('access')
            utils.lockRequest
            utils.getDoc
            disk.addWrite
            access.remove
            utils.unlockRequest
        ]

    'replication/*':
        'post': [
            utils.checkPermissionsPostReplication
            disk.check
            replication.proxy
        ]
        'get': [
            replication.proxy
            # Permissions manage in request
        ]
        'put':[
            utils.checkPermissionsPutReplication
            disk.check
            replication.proxy
        ]

    # Indexer management
    'data/index/clear-all/':
        'delete': [
            utils.checkPermissionsFactory('all')
            indexer.removeAll
        ]

    'data/index/:id':
        post: [
            utils.lockRequest
            utils.getDoc
            utils.checkPermissionsByDoc
            indexer.index
            utils.unlockRequest
        ]
        'delete': [
            utils.lockRequest
            utils.getDoc
            utils.checkPermissionsByDoc
            indexer.remove
            utils.unlockRequest
        ]
    'data/search/:type': post: [utils.checkPermissionsByType, indexer.search]
    'data/search/': post: [utils.checkPermissionsFactory('all'), indexer.search]

    # Mail management
    'mail/': post: [utils.checkPermissionsFactory('send mail'), mails.send]
    'mail/to-user': post: [
        utils.checkPermissionsFactory('send mail to user')
        mails.sendToUser
    ]
    'mail/from-user': post: [
        utils.checkPermissionsFactory('send mail from user')
        mails.sendFromUser
    ]

    #User management
    'user/': post: [utils.checkPermissionsFactory('User'), 
            disk.check, user.create]
    'user/merge/:id': put: [
        utils.lockRequest
        utils.checkPermissionsFactory('User')
        disk.check
        utils.getDoc
        user.merge
        utils.unlockRequest
    ]

    #Account management
    'accounts/password/':
        post: [account.checkPermissions, account.initializeKeys]
        put: [account.checkPermissions, account.updateKeys]
    'accounts/reset/': delete: [account.checkPermissions, account.resetKeys]
    'accounts/': delete: [account.checkPermissions, account.deleteKeys]
