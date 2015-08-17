// Generated by CoffeeScript 1.9.3
var User, db, request;

db = require('../helpers/db_connect_helper').db_connect();

request = require('./request');

module.exports = User = (function() {
  function User() {}

  User.prototype.getUser = function(callback) {
    return request.viewAll('user', (function(_this) {
      return function(err, res) {
        if (err) {
          return callback(err);
        } else {
          if (res.length > 0) {
            return callback(null, res[0].doc);
          } else {
            return callback(new Error("No user found"));
          }
        }
      };
    })(this));
  };

  return User;

})();
