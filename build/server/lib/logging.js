// Generated by CoffeeScript 1.9.1
var fs, path, util;

fs = require('fs');

path = require('path');

util = require('util');

exports.stream = null;

exports.init = (function(_this) {
  return function(compound, callback) {
    var app, logDir, logFile;
    app = compound.app;
    logDir = path.join(compound.root, 'log');
    logFile = path.join(logDir, app.get('env') + '.log');
    return fs.exists(logDir, function(exists) {
      var options;
      if (exists) {
        options = {
          flags: 'a',
          mode: 0x1b6,
          encoding: 'utf8'
        };
        exports.stream = fs.createWriteStream(logFile, options);
        return callback(exports.stream);
      } else {
        return callback(null);
      }
    });
  };
})(this);

exports.write = (function(_this) {
  return function() {
    var stream, text;
    text = util.format.apply(util, arguments);
    stream = exports.stream || process.stdout;
    return stream.write(text + '\n' || console.log(text));
  };
})(this);
