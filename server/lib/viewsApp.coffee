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
        "withoutdoctype": ["ds"]
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
        "allopsbyday": ["kyou"]
        "nbbyday": ["kyou"]
    "binary":
        "bydoc": ["ds"]
    "bookmark":
        "bydate": ["quickmarks"]
    "bloodpressure":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
    "city":
        "bydate" : ["own"]
    "codebill":
        "bydate": ["konnectors"]
    "commit":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
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
        "nbbyday": ["kyou"]
    "favoritetag":
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
    "heartbeat":
        "bydate": ["konnectors"]
    "internetbill":
        "bydate": ["konnectors"]
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
    "phonebill":
        "bydate": ["konnectors"]
    "photo":
        "byalbum": ["photos"]
        "albumphotos": ["photos"]
    "rescuetimeactivity":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
    "sleep":
        "nbbyday": ["kyou"]
        "bydate": ["konnectors"]
    "step":
        "bydate": ["konnectors"]
    "steps":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
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
        "nbbyday": ["kyou"]
    "tasky":
        "byarchivestate": ["tasky"]
        "byorder": ["tasky"]
    "temperature":
        "bydate": ["konnectors"]
    "track":
        "byplaylist": ["cozic"]
    "tracker":
        "byname": ["kyou"]
    "trackeramount":
        "nbbyday": ["kyou"]
        "byday": ["kyou"]
    "tree":
        "bytype": ["notes", "todos"]
    "twittertweet":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
    "weight":
        "bydate": ["konnectors"]
        "nbbyday": ["kyou"]
    "zfparam":
        "byname": ["zero-feeds"]