(function() {
  var models, nohm, update, winston, _;
  _ = require('underscore');
  nohm = require('nohm');
  models = require('../models');
  winston = require('winston');
  update = function(req, res) {
    var action, assignedTo, assignedUser, attributes, complete, id, now, owner, task;
    attributes = _.clone(req.body);
    id = attributes.id;
    delete attributes.id;
    assignedTo = attributes.assignedTo;
    delete attributes.assignedTo;
    task = req.task || new models.Task(id);
    action = task.id === id || id ? 'update' : 'create';
    now = (new Date()).getTime();
    if (action === 'create') {
      attributes.createDate = now;
    }
    attributes.modifiedDate = now;
    /* TODO move to .propertyDiff */
    if (task.isArchived() !== attributes.archived) {
      action = attributes.archived ? 'archive' : action;
    }
    task.p(attributes);
    complete = function() {
      task.link(assignedUser, 'assignedTo');
      return task.save(function(err, relationError, relationName) {
        if (!err) {
          winston.info("Task \#" + task.id + " " + action + "d successfully");
          return res.send(JSON.parse(task.allProperties(true)));
        } else if (relationError) {
          action = relationName === 'assignedTo' ? 'assign' : 'completely create';
          if (relationName) {
            winston.error("There has been a relationError");
          }
          winston.error("Task \#" + task.id + " could not be " + action + "d");
          winston.debug(JSON.stringify(task.errors));
          return res.send(500);
        } else {
          winston.error("Task \#" + task.id + " could not be " + action + "d");
          winston.debug(JSON.stringify(task.errors));
          return res.send(500);
        }
      });
    };
    owner = new models.User(req.session.userId);
    if (assignedTo) {
      assignedUser = new models.User(assignedTo.id || assignedTo);
      return assignedUser.load(assignedTo.id || assignedTo, function(err, props) {
        if (!err) {
          return owner.load(req.session.userId, function(err, props) {
            if (!err) {
              return complete();
            } else {
              return winston.error('Error retrieving users');
            }
          });
        } else {
          return winston.error('Error retrieving users');
        }
      });
    } else {
      assignedUser = owner;
      return owner.load(req.session.userId, function(err, props) {
        if (!err) {
          return complete();
        } else {
          return winston.error('Error retrieving users');
        }
      });
    }
  };
  _.extend(exports, {
    index: function(req, res) {
      var mock, objects;
      objects = [];
      mock = new models.Task;
      return mock.find(function(err, ids) {
        var pass;
        if (!err) {
          (pass = _.after(ids.length + 1, function() {
            winston.info("Tasks list successfully retrieved");
            return res.send(objects);
          }))();
          return _.each(ids, function(id) {
            var task;
            task = new models.Task(id);
            return task.load(id, function(err, properties) {
              var attributes;
              if (!err) {
                attributes = JSON.parse(task.allProperties(true));
                attributes.archived = task.isArchived();
                if (attributes.archived && false) {
                  return pass();
                } else {
                  winston.info("Task \#" + id + " loaded");
                  return task.getAll('User', 'assignedTo', function(err, userIds) {
                    var pass2;
                    if (!err) {
                      (pass2 = _.after(userIds.length + 1, function() {
                        objects.push(attributes);
                        return pass();
                      }))();
                      return _.each(userIds, function(assignedId) {
                        var assigned;
                        assigned = new models.User(assignedId);
                        return assigned.load(assignedId, function(err, properties) {
                          if (err) {
                            winston.error("User \#" + assignedId + " could not be retrieved");
                          } else {
                            attributes['assignedTo'] = assigned.expose();
                          }
                          return pass2();
                        });
                      });
                    } else {
                      return winston.error("Error occured loading assigned users");
                    }
                  });
                }
              } else {
                winston.error("Some error occured loading Task \#" + id);
                return pass();
              }
            });
          });
        } else {
          winston.error("Task list could not be retrieved");
          return res.send(500);
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
        if (!err) {
          winston.info("Task \#" + id + " removed successfully");
          return res.send(req.task.allProperties(true));
        } else {
          winston.error("Task \#" + id + " could not be removed");
          return res.send(500);
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
