// Generated by CoffeeScript 1.7.1
var checkDocType, count, db, feed, fs, indexAllView, log, recoverDesignDocs, recoverDocs;

fs = require('fs');

feed = require('../lib/feed');

checkDocType = require('../lib/token').checkDocType;

db = require('../helpers/db_connect_helper').db_connect();

log = require('printit')();

count = 0;


/* Helpers */

recoverDocs = (function(_this) {
  return function(res, docs, callback) {
    var doc;
    if (res && res.length !== 0) {
      doc = res.pop();
      return db.get(doc.id, function(err, result) {
        docs.push(result);
        return recoverDocs(res, docs, callback);
      });
    } else {
      return callback(docs);
    }
  };
})(this);

recoverDesignDocs = (function(_this) {
  return function(callback) {
    var filterRange;
    filterRange = {
      startkey: "_design/",
      endkey: "_design0"
    };
    return db.all(filterRange, function(err, res) {
      return recoverDocs(res, [], callback);
    });
  };
})(this);

indexAllView = function() {
  log.info("Update all views ....");
  return recoverDesignDocs((function(_this) {
    return function(docs) {
      var body, doc, type, view, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = docs.length; _i < _len; _i++) {
        doc = docs[_i];
        _results.push((function() {
          var _ref, _results1;
          _ref = doc.views;
          _results1 = [];
          for (view in _ref) {
            body = _ref[view];
            type = doc._id.substr(8, doc._id.length - 1);
            log.info("Update view " + type + "/" + view);
            _results1.push(db.view("" + type + "/" + view, {}, function(err, res, body) {
              if (err != null) {
                return log.error(err);
              }
            }));
          }
          return _results1;
        })());
      }
      return _results;
    };
  })(this));
};

module.exports.deleteFiles = function(files) {
  var file, key, _results;
  if ((files != null) && Object.keys(files).length > 0) {
    _results = [];
    for (key in files) {
      file = files[key];
      _results.push(fs.unlinkSync(file.path));
    }
    return _results;
  }
};

module.exports.checkPermissions = function(req, permission, next) {
  return checkDocType(req.header('authorization'), permission, function(err, appName, isAuthorized) {
    if (!appName) {
      err = new Error("Application is not authenticated");
      err.status = 401;
      return next(err);
    } else if (!isAuthorized) {
      err = new Error("Application is not authorized");
      err.status = 403;
      return next(err);
    } else {
      feed.publish('usage.application', appName);
      req.appName = appName;
      return next();
    }
  });
};

module.exports.incrementCount = function(next) {
  count += 1;
  if (count > 100) {
    indexAllView();
    count = 0;
  }
  return next();
};
