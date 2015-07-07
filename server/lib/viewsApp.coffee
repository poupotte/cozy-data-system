# TODOS : Ajouter le stack (DS)

exports.views =
    "access":
        "byapp": ["ds"]
    "alarm":
        "bydate": ["calendar"]
        "tags": ["calendar"]
    "album":
        "bytitle": ["photos"]
    "all":
        "bydoctype": ["ds"]
        "withoutDocType": ["ds"]
    "application":
        "byslug": ["home"]
        "getpermissions": ["databrowser"]
    "bank:":
        "byname": ["kresus"]
        "byuuid": ["kresus"]
    "bankaccess":
        "allbybank": ["kresus"]
        "alllike": ["kresus"]
    "bankaccount":
        "bytitle": ["kresus"]
        "allbybankaccess": ["kresus"]
        "allbybank": ["kresus"]
        "alllike": ["kresus"]
        "bankwithaccounts": ["kresus"]
    "bankalert":
        "allbybankaccount": ["kresus"]
        "allreportsbyfrequency": ["kresus"]
        "allbybankaccountandtype": ["kresus"]
    "bankcategory":
        "byid": ["kresus"]
    "bankoperation":
        "bydate": ["konnectors"]
        "allbybankaccount": ["kresus"]
        "allbybankaccountanddate": ["kresus"]
        "allbycategory": ["kresus"]
        "alllike": ["kresus"]
    "binary":
        "bydoc": ["ds"]
    "bookmark":
        "bydate": ["quickmarks"]
    "city":
        "bydate" : ["own"]
    "contact":
        "byname": ["contact"]
        "mailbyemail" : ["emails"]
        "mailbyname": ["emails"]
        "byuri": ["sync"]
        "bytag": ["sync"]
        "tags": ["sync"]
    "dailynote":
        "byday": ["kyou"]
    "device":
        "bylogin": ["ds"]
    "doctypes":
        "getall": ["databrowser"]
        "getsums": ["databrowser"]
        "getallbyorigin": ["databrowser"]
    "documents":
        "bykey": ["remotestorage"]
    "event":
        "bydate": ["calendar"]
        "tags": ["calendar", "sync"]
        "bycalendar": ["calendar", "sync"]
        "byuri": ["sync"]
    "favorite_tag":
        "allbyapp": ["tasky"]
        "byappbylabel": ["tasky"]
    "feed":
        "bytags": ["zero-feeds"]
    "file":
        "bytag": ["files"]
        "byfolder": ["files"]
        "byfullpath": ["files"]
        "imagebydate": ["photos", "home"]
        "imagebymonth": ["home"]
        "withoutthumb": ["photos", "ds"]
    "folder":
        "bytag": ["files"]
        "byfolder": ["files"]
        "byfullpath": ["files", "konnectors"]
    "mailbox":
        "treemap": ["emails"]
    "message":
        "totalunreadbyaccount": ["emails"]
        "bymailboxrequest": ["emails"]
        "deduprequest": ["emails"]
        "conversationpatching": ["emails"]
        "byconversationid": ["emails"]
    "metadoctype":
        "getallbyrelated": ["databrowser"]
    "mood":
        "statusbyday": ["kyou"]
        "byday": ["kyou"]
    "note":
        "path": ["notes"]
        "tree": ["notes"]
        "lastmodified": ["notes"]
    "notification":
        "bydate": ["home"]
        "byapps": ["home"]
    "permissions":
        "bykey": ["remotestorage"]
        "bysame": ["remotestorage"]
    "photo":
        "byalbum": ["photos"]
        "albumphotos": ["photos"]
    "tag":
        "byname": ["calendar", "contact", "sync"]
    "tags":
        "list": ["ds"]
    "task":
        "archive": ["todos"]
        "todos": ["todos"]
        "archivelist": ["todos"]
        "todoslist": ["todos"]
        "archivetag": ["todos"]
        "todostag": ["todos"]
        "tags": ["todos"]
    "tasky":
        "byarchivestate": ["tasky"]
        "byorder": ["tasky"]
    "track":
        "byplaylist": ["cozic"]
    "tracker":
        "byname": ["kyou"]
    "trackeramount":
        "nbbyday": ["kyou"]
        "byday": ["kyou"]
    "tree":
        "bytype": ["notes", "todos"]
    "zfparam":
        "byname": ["zero-feeds"]