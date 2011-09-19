(function() {
  var models, nohm, parse, update, winston, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore');
  nohm = require('nohm');
  models = require('../models');
  winston = require('winston');
  update = function(req, res) {
    return null;
  };
  parse = function(user) {
    return {
      id: user.id,
      username: user.username,
      fullname: user.fullname
    };
  };
  _.extend(exports, {
    index: function(req, res) {
      var mock, objects, search, send;
      objects = [];
      mock = new models.User;
      search = (req.query.q || '').toLowerCase();
      send = __bind(function(users) {
        return res.send((_(objects)).chain().filter(function(user) {
          if (search === '*') {
            return true;
          }
          if ((user.fullname.toLowerCase().indexOf(search)) >= 0) {
            return true;
          }
          if ((user.username.toLowerCase().indexOf(search)) >= 0) {
            return true;
          }
          return false;
        }).map(parse).value());
      }, this);
      return mock.find(function(err, ids) {
        var pass;
        if (err) {
          winston.error("Users list could not be retrieved");
          return res.send(500);
        } else {
          pass = _.after(ids.length, function() {
            winston.info("Users list successfully retrieved");
            return send();
          });
          return _.each(ids, function(id) {
            var user;
            user = new models.User;
            return user.load(id, function(err, properties) {
              var attributes;
              if (err) {
                winston.error("Some error occured loading User \#" + id);
              } else {
                console.dir(attributes);
                attributes = JSON.parse(user.allProperties(true));
                if (!attributes.archived) {
                  objects.push(attributes);
                }
              }
              return pass();
            });
          });
        }
      });
    },
    show: function(req, res) {
      return res.send(parse(JSON.parse(req.user.allProperties(true))));
    },
    load: function(id, fn) {
      var task;
      task = new models.User;
      return task.load(id, function(err, properties) {
        if (err) {
          return fn(new Error('No such user'));
        }
        return fn(null, task);
      });
    }
  });
}).call(this);
