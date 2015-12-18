// Generated by CoffeeScript 1.10.0
var async, binaryManagement, createThumb, db, downloader, fs, gm, log, mime, queue, randomString, releaseStream, resize, whiteList,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

fs = require('fs');

gm = require('gm').subClass({
  imageMagick: true
});

mime = require('mime');

log = require('printit')({
  prefix: 'thumbnails'
});

db = require('../helpers/db_connect_helper').db_connect();

binaryManagement = require('../lib/binary');

downloader = require('./downloader');

async = require('async');

randomString = require('./random').randomString;

whiteList = ['image/jpeg', 'image/png'];

queue = async.queue(function(task, callback) {
  return db.get(task.file, function(err, file) {
    if (err) {
      log.info("Cant get File " + file.id + " for thumb");
      log.info(err);
      return callback();
    } else {
      return createThumb(file, task.force, callback);
    }
  });
}, 2);

releaseStream = function(stream) {
  stream.on('data', function() {});
  stream.on('end', function() {});
  return stream.resume();
};

resize = function(srcPath, file, name, mimetype, force, callback) {
  var buildThumb, data, e, err, error, error1, gmRunner;
  if ((file.binary[name] != null) && !force) {
    return callback();
  }
  data = {
    name: name,
    "content-type": mimetype
  };
  try {
    if (!fs.existsSync(srcPath)) {
      return callback("File doesn't exist");
    }
    try {
      fs.open(srcPath, 'r+', function(err, fd) {
        fs.close(fd);
        if (err) {
          return callback('Data-system has not correct permissions');
        }
      });
    } catch (error) {
      e = error;
      return callback('Data-system has not correct permissions');
    }
    gmRunner = gm(srcPath);
    if (name === 'thumb') {
      buildThumb = function(width, height) {
        return gmRunner.resize(width, height).crop(300, 300, 0, 0).stream(function(err, stdout, stderr) {
          if (err) {
            releaseStream(stdout);
            callback(err);
          } else {
            binaryManagement.addBinary(file, data, stdout, function(err) {
              if (err != null) {
                return callback(err);
              }
            });
          }
          return stdout.on("end", callback);
        });
      };
      return gmRunner.size(function(err, data) {
        if (err) {
          return callback(err);
        } else if (data.width > data.height) {
          return buildThumb(null, 300);
        } else {
          return buildThumb(300, null);
        }
      });
    } else if (name === 'screen') {
      return gmRunner.resize(1200, 800).stream(function(err, stdout, stderr) {
        if (err) {
          releaseStream(stdout);
          return callback(err);
        } else {
          binaryManagement.addBinary(file, data, stdout, function(err) {
            if (err != null) {
              return callback(err);
            }
          });
          return stdout.on('end', callback);
        }
      });
    }
  } catch (error1) {
    err = error1;
    return callback(err);
  }
};

module.exports.create = function(id, force) {
  return queue.push({
    file: id,
    force: force
  });
};

createThumb = function(file, force, callback) {
  var addThumb, id, mimetype, ref, ref1;
  addThumb = function(stream, mimetype) {
    var error, rawFile, writeStream;
    rawFile = "/tmp/" + file.name;
    if (fs.existsSync(rawFile)) {
      rawFile = "/tmp/" + (randomString(3)) + file.name;
    }
    try {
      writeStream = fs.createWriteStream(rawFile);
    } catch (error) {
      releaseStream(stream);
      return callback('Error in thumb creation.');
    }
    stream.pipe(writeStream);
    stream.on('error', callback);
    return stream.on('end', function() {
      return resize(rawFile, file, 'thumb', mimetype, force, function(err) {
        if (err != null) {
          log.error(err);
        }
        return resize(rawFile, file, 'screen', mimetype, force, function(err) {
          if (err != null) {
            log.error(err);
          }
          return fs.unlink(rawFile, function(err) {
            if (err) {
              log.error(err);
            } else {
              log.info("createThumb " + file.id + " /\n " + file.name + ": Thumbnail created");
            }
            return callback();
          });
        });
      });
    });
  };
  if (file.binary == null) {
    return callback(new Error('no binary'));
  }
  mimetype = mime.lookup(file.name);
  if ((((ref = file.binary) != null ? ref.thumb : void 0) != null) && (((ref1 = file.binary) != null ? ref1.screen : void 0) != null) && !force) {
    log.info("createThumb " + file.id + "/" + file.name + ": already created.");
    return callback();
  } else if (indexOf.call(whiteList, mimetype) < 0) {
    log.info("createThumb: " + file.id + " / " + file.name + ":\nNo thumb to create for this kind of file.");
    return callback();
  } else {
    log.info("createThumb: " + file.id + " / " + file.name + ": Creation started...");
    id = file.binary['file'].id;
    return downloader.download(id, 'file', function(err, stream) {
      if (err) {
        return callback(err);
      } else {
        return addThumb(stream, mimetype);
      }
    });
  }
};
