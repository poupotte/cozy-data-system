// Generated by CoffeeScript 1.8.0
var checkDocType, count, db, feed, fork, fs, log;

fs = require('fs');

feed = require('../lib/feed');

fork = require('child_process').fork;

checkDocType = require('../lib/token').checkDocType;

db = require('../helpers/db_connect_helper').db_connect();

log = require('printit')();

count = 0;

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
  var child;
  count += 1;
  if (count > 100) {
    count = 0;
    child = fork(__dirname + "/index_view.coffee");
    child.on('message', function(m) {
      return console.log('received: ' + m);
    });
    child.on('close', function(code) {
      return console.log("process close with code " + code);
    });
  }
  return next();
};
