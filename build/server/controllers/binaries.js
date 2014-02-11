// Generated by CoffeeScript 1.7.1
var checkPermissions, db, deleteFiles, feed, fs, locker;

fs = require("fs");

db = require('../helpers/db_connect_helper').db_connect();

locker = require('../lib/locker');

feed = require('../helpers/db_feed_helper');

checkPermissions = require('../lib/token').checkDocType;

deleteFiles = function(req, callback) {
  var file, i, key, lasterr, _ref;
  i = 0;
  lasterr = null;
  _ref = req.files;
  for (key in _ref) {
    file = _ref[key];
    i++;
    fs.unlink(file.path, function(err) {
      i--;
      if (lasterr == null) {
        lasterr = err;
      }
      if (i === 0) {
        if (lasterr) {
          console.log(lasterr);
        }
        return callback(lasterr);
      }
    });
  }
  if (i === 0) {
    return callback();
  }
};

module.exports.lockRequest = function(req, res, next) {
  req.lock = "" + req.params.id;
  return locker.runIfUnlock(req.lock, (function(_this) {
    return function() {
      locker.addLock(req.lock);
      return next();
    };
  })(this));
};

module.exports.unlockRequest = function(req, res) {
  return locker.removeLock(req.lock);
};

module.exports.getDoc = function(req, res, next) {
  return db.get(req.params.id, (function(_this) {
    return function(err, doc) {
      if (err && err.error === "not_found") {
        locker.removeLock(req.lock);
        return deleteFiles(req, function() {
          return res.send(404, {
            error: "not found"
          });
        });
      } else if (err != null) {
        console.log("[Attachment] err: " + JSON.stringify(err));
        locker.removeLock(req.lock);
        return deleteFiles(req, function() {
          return res.send(500, {
            error: err.error
          });
        });
      } else if (doc != null) {
        req.doc = doc;
        return next();
      } else {
        locker.removeLock(req.lock);
        return deleteFiles(req, function() {
          return res.send(404, {
            error: "not found"
          });
        });
      }
    };
  })(this));
};

module.exports.permissions = function(req, res, next) {
  var auth;
  auth = req.header('authorization');
  return checkPermissions(auth, req.doc.docType, (function(_this) {
    return function(err, appName, isAuthorized) {
      if (!appName) {
        err = new Error("Application is not authenticated");
        return res.send(401, {
          error: err
        });
      } else if (!isAuthorized) {
        err = new Error("Application is not authorized");
        return res.send(403, {
          error: err
        });
      } else {
        feed.publish('usage.application', appName);
        return next();
      }
    };
  })(this));
};

module.exports.add = function(req, res, next) {
  var attach, binary, file, name, _ref;
  attach = (function(_this) {
    return function(binary, name, file, doc) {
      var fileData, stream;
      fileData = {
        name: name,
        "content-type": file.type
      };
      stream = db.saveAttachment(binary, fileData, function(err, binDoc) {
        var bin, newBin;
        if (err) {
          console.log("[Attachment] err: " + JSON.stringify(err));
          return deleteFiles(req, function() {
            next();
            return res.send(500, {
              error: err.error
            });
          });
        } else {
          bin = {
            id: binDoc.id,
            rev: binDoc.rev
          };
          if (doc.binary) {
            newBin = doc.binary;
          } else {
            newBin = {};
          }
          newBin[name] = bin;
          return db.merge(doc._id, {
            binary: newBin
          }, function(err) {
            return deleteFiles(req, function() {
              next();
              return res.send(201, {
                success: true
              });
            });
          });
        }
      });
      return fs.createReadStream(file.path).pipe(stream);
    };
  })(this);
  if (req.files["file"] != null) {
    file = req.files["file"];
    if (req.body.name != null) {
      name = req.body.name;
    } else {
      name = file.name;
    }
    if (((_ref = req.doc.binary) != null ? _ref[name] : void 0) != null) {
      return db.get(req.doc.binary[name].id, function(err, binary) {
        return attach(binary, name, file, req.doc);
      });
    } else {
      binary = {
        docType: "Binary"
      };
      return db.save(binary, function(err, binary) {
        return attach(binary, name, file, req.doc);
      });
    }
  } else {
    console.log("no doc for attachment");
    next();
    return res.send(400, {
      error: "No file send"
    });
  }
};

module.exports.get = function(req, res) {
  var name, stream;
  name = req.params.name;
  if (req.doc.binary && req.doc.binary[name]) {
    stream = db.getAttachment(req.doc.binary[name].id, name, function(err) {
      if (err && (err.error = "not_found")) {
        return res.send(404, {
          error: err.error
        });
      } else if (err) {
        return res.send(500, {
          error: err.error
        });
      } else {
        return res.send(200);
      }
    });
    if (req.headers['range'] != null) {
      stream.setHeader('range', req.headers['range']);
    }
    stream.pipe(res);
    return res.on('close', function() {
      return stream.abort();
    });
  } else {
    return res.send(404, {
      error: 'not_found'
    });
  }
};

module.exports.remove = function(req, res, next) {
  var id, name;
  name = req.params.name;
  if (req.doc.binary && req.doc.binary[name]) {
    id = req.doc.binary[name].id;
    delete req.doc.binary[name];
    if (req.doc.binary.length === 0) {
      delete req.doc.binary;
    }
    return db.save(req.doc, function(err) {
      return db.get(id, function(err, binary) {
        return db.remove(binary.id, binary.rev, function(err) {
          next();
          if ((err != null) && (err.error = "not_found")) {
            return res.send(404, {
              error: err.error
            });
          } else if (err) {
            console.log("[Attachment] err: " + JSON.stringify(err));
            return res.send(500, {
              error: err.error
            });
          } else {
            return res.send(204, {
              success: true
            });
          }
        });
      });
    });
  } else {
    next();
    return res.send(404, {
      error: 'not_found'
    });
  }
};
