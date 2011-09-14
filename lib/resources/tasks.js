(function() {
  var models, nohm, update, winston, _;
  _ = require('underscore');
  nohm = require('nohm');
  models = require('../models');
  winston = require('winston');
  update = function(req, res) {
    var action, attributes, id, now, task;
    attributes = _.clone(req.body);
    id = attributes.id;
    delete attributes.id;
    task = req.task || new models.Task(id);
    action = task.id === id || id ? 'update' : 'create';
    now = (new Date()).getTime();
    if (action === 'create') {
      attributes.createDate = now;
    }
    attributes.modifiedDate = now;
    if (task.isArchived !== attributes.archived && attributes.archived) {
      action = 'archive';
    }
    task.p(attributes);
    return task.save(function(err) {
      if (err) {
        winston.error("Task \#" + task.id + " could not be " + action + "d");
        console.dir(task);
        return res.send(500);
      } else {
        winston.info("Task \#" + task.id + " " + action + "d successfully");
        return res.send(JSON.parse(task.allProperties(true)));
      }
    });
  };
  _.extend(exports, {
    index: function(req, res) {
      var mock, objects;
      objects = [];
      mock = new models.Task;
      return mock.find(function(err, ids) {
        var pass;
        if (err) {
          winston.error("Task list could not be retrieved");
          return res.send(500);
        } else {
          pass = _.after(ids.length, function() {
            winston.info("Tasks list successfully retrieved");
            return res.send(objects);
          });
          return _.each(ids, function(id) {
            var task;
            task = new models.Task;
            return task.load(id, function(err, properties) {
              var attributes;
              if (err) {
                winston.error("Some error occured loading Task \#" + id);
              } else {
                console.dir(attributes);
                attributes = JSON.parse(task.allProperties(true));
                attributes.archived = task.isArchived();
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
      return res.send(JSON.parse(req.task.allProperties(true)));
    },
    create: update,
    update: update,
    destroy: function(req, res) {
      var id;
      id = req.task.id;
      return req.task.remove(function(err) {
        if (err) {
          winston.error("Task \#" + id + " could not be removed");
          return res.send(500);
        } else {
          winston.info("Task \#" + id + " removed successfully");
          return res.send(req.task.allProperties(true));
        }
      });
    },
    load: function(id, fn) {
      var task;
      task = new models.Task;
      return task.load(id, function(err, properties) {
        if (err) {
          return fn(new Error('No such task'));
        }
        return fn(null, task);
      });
    }
  });
}).call(this);
