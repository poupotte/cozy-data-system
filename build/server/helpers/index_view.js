// Generated by CoffeeScript 1.8.0
var db, index, log, recoverDesignDocs, recoverDocs, updateDocs, updateViews;

log = require('printit')();

db = require('../helpers/db_connect_helper').db_connect();

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

updateViews = function(type, views, callback) {
  var view;
  if (views.length > 0) {
    view = views.pop();
    log.info("Update view " + type + "/" + view);
    return db.view("" + type + "/" + view, {}, function(err, res, body) {
      if (err != null) {
        log.error(err);
      }
      return updateViews(type, views, callback);
    });
  } else {
    return callback();
  }
};

updateDocs = function(docs, callback) {
  var doc, type;
  if (docs.length > 0) {
    doc = docs.pop();
    type = doc._id.substr(8, doc._id.length - 1);
    return updateViews(type, Object.keys(doc.views), function() {
      return updateDocs(docs, callback);
    });
  } else {
    return callback();
  }
};

index = module.exports = function(callback) {
  log.info("Update all views ....");
  return recoverDesignDocs((function(_this) {
    return function(docs) {
      return updateDocs(docs, function() {
        if (callback != null) {
          return callback();
        }
      });
    };
  })(this));
};

if (!module.parent) {
  index();
}
