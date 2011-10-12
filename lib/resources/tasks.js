(function() {
  var models, nohm, update, winston, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  _ = require('underscore');
  nohm = require('nohm');
  models = require('../models');
  winston = require('winston');
  update = function(req, res) {
    var action, actor, assignedTo, assignedUser, assigning, attributes, closing, complete, id, now, opening, prop, task, _i, _len, _ref;
    attributes = _.clone(req.body);
    id = attributes.id;
    delete attributes.id;
    assignedTo = attributes.assignedTo;
    delete attributes.assignedTo;
    if (_.isArray(assignedTo)) {
      assignedTo = assignedTo[0];
    }
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
    closing = !!attributes.closing;
    opening = !!attributes.opening;
    assigning = !!attributes.assigning;
    _ref = ['closed', 'open', 'opening', 'closing', 'assigning', 'status'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      prop = _ref[_i];
      delete attributes[prop];
    }
    task.p(attributes);
    complete = function() {
      if (assigning || !(req.task != null)) {
        task.link(assignedUser, 'assignedTo');
      }
      if (closing) {
        task.link(actor, 'assignedTo');
        task.link(actor, 'closedBy');
      } else if (opening) {
        task.unlink(actor, 'closedBy');
      }
      return task.save(function(err, relationError, relationName) {
        if (!err) {
          winston.info("Task \#" + task.id + " " + action + "d successfully");
          return task.expose(function(err, json) {
            if (!err) {
              return res.send(json);
            } else {
              return winston.error("Error retrieving task data");
            }
          });
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
    actor = new models.User(req.session.userId);
    if (assignedTo) {
      console.dir(assignedTo);
      assignedUser = new models.User(assignedTo.id || assignedTo);
      return assignedUser.load(assignedTo.id || assignedTo, function(err, props) {
        if (!err) {
          return actor.load(req.session.userId, function(err, props) {
            if (!err) {
              return complete();
            } else {
              winston.error('Error retrieving users');
              return console.dir(err);
            }
          });
        } else {
          return winston.error('Error retrieving user \#' + (assignedTo.id || assignedTo));
        }
      });
    } else {
      assignedUser = actor;
      return actor.load(req.session.userId, function(err, props) {
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
      var complete, objects;
      objects = [];
      complete = function(err, ids) {
        var pass;
        if (!err) {
          (pass = _.after(ids.length + 1, function() {
            winston.info("Tasks list successfully retrieved");
            return res.send(objects);
          }))();
          return _.each(ids, function(id) {
            return models.Task.load(id, function(err, properties) {
              if (!err) {
                return this.expose(__bind(function(err, object) {
                  if (!err) {
                    if (!this.isArchived()) {
                      objects.push(object);
                    }
                    return pass();
                  } else {
                    return winston.error('Error retrieving task properties');
                  }
                }, this));
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
      };
      if (req.user != null) {
        return models.Task.find({
          context: req.user.id
        }, complete);
      } else {
        return models.Task.find(complete);
      }
    },
    show: function(req, res) {
      return req.task.expose(function(err, json) {
        if (!err) {
          return res.send(json);
        } else {
          return res.send(500);
        }
      });
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
