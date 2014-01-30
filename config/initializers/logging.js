// Generated by CoffeeScript 1.6.3
var logging;

logging = require('../../lib/logging');

module.exports = function(compound) {
  var _this = this;
  if (process.env.NODE_ENV !== "test") {
    console.log = function() {
      return logging.write.apply(logging, arguments);
    };
    console.info = function() {
      return logging.write.apply(logging, arguments);
    };
    console.error = function() {
      return logging.write.apply(logging, arguments);
    };
    return console.warm = function() {
      return logging.write.apply(logging, arguments);
    };
  }
};
