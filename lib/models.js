(function() {
  var Task, User, hashlib, nohm, persistence, redis, winston, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  winston = require('winston');
  _ = require('underscore');
  _.mixin(require('underscore.string'));
  hashlib = require('./utils/hashlib');
  redis = require('redis');
  persistence = redis.createClient();
  nohm = (require('nohm')).Nohm;
  nohm.setClient(persistence);
  nohm.setPrefix('beauvoir');
  nohm.logError = function(err) {
    if (err) {
      winston.error(err);
      return console.trace();
    }
  };
  /*
  # Top Models
  */
  User = nohm.model('User', {
    properties: {
      username: {
        type: 'string',
        unique: true,
        index: true,
        validations: ['notEmpty']
      },
      salt: {
        type: 'timestamp',
        validations: ['notEmpty']
      },
      password: {
        type: 'string',
        validations: ['notEmpty']
      },
      email: {
        type: 'string',
        unique: true,
        defaultValue: 'error@error.com',
        validations: ['notEmpty', 'email']
      },
      fullname: {
        type: 'string',
        unique: false
      },
      profile: {
        type: 'json'
      }
    },
    idGenerator: 'increment',
    methods: {
      expose: function() {
        return {
          id: this.id,
          fullname: this.p('fullname'),
          username: this.p('username')
        };
      },
      /*
      		info: (parameter) ->
      			profile = @p 'profile'
      			if parameter
      				profile[parameter]
      			else
      				parameter
      		*/
      getGravatar: function(size) {
        if (size == null) {
          size = 55;
        }
        return "https://secure.gravatar.com/avatar/" + (this.getEmailHash()) + "?s=" + size + "&d=retro";
      },
      getEmailHash: function() {
        return hashlib.md5(String.prototype.toLowerCase.call(_.trim(this.p('email'))));
      }
    }
  });
  Task = nohm.model('Task', {
    properties: {
      name: {
        type: 'string',
        unique: false
      },
      priority: {
        type: 'integer',
        index: false,
        defaultValue: 0,
        validations: ['notEmpty', ['min', 1], ['max', 3]]
      },
      minimum: {
        type: 'integer',
        defaultValue: -1
      },
      archived: {
        type: 'boolean',
        index: true,
        defaultValue: false
      },
      dueDate: {
        type: 'timestamp',
        index: true
      },
      createDate: {
        type: 'timestamp',
        validations: ['notEmpty']
      },
      modifiedDate: {
        type: 'timestamp',
        validations: ['notEmpty']
      }
    },
    idGenerator: 'increment',
    methods: {
      isArchived: function() {
        var arch;
        arch = this.p('archived');
        if (!!arch === arch) {
          return arch;
        } else {
          return arch !== 'false';
        }
      },
      expose: function(callback) {
        var attributes, task;
        task = this;
        attributes = this.allProperties();
        attributes.archived = this.isArchived();
        attributes.assignedTo = [];
        this.getAll('User', 'assignedTo', __bind(function(err, ids) {
          var pass, userId, _i, _len, _results;
          (pass = _.after(ids.length + 1, _.once(__bind(function() {
            attributes.archived = this.isArchived();
            attributes.closed = this.isClosed(attributes);
            return callback(null, attributes);
          }, this))))();
          if (!err) {
            _results = [];
            for (_i = 0, _len = ids.length; _i < _len; _i++) {
              userId = ids[_i];
              _results.push(User.load(userId, function(err, properties) {
                var userAttributes;
                if (!err) {
                  userAttributes = this.expose();
                  return task.belongsTo(this, 'closedBy', function(err, closed) {
                    if (!err) {
                      userAttributes.closed = closed;
                      attributes.assignedTo.push(userAttributes);
                      return pass();
                    } else {
                      callback(err);
                      return winston.error("Error retrieving closing status for user \#" + userId);
                    }
                  });
                } else {
                  callback(err);
                  return winston.error("Error retrieving user \#" + userId);
                }
              }));
            }
            return _results;
          } else {
            callback(err);
            return winston.error("Error retrieving assigned users to task \#" + this.id);
          }
        }, this));
        return this;
      },
      isClosed: function(json) {
        var calculate, callback, minimum;
        minimum = this.property('minimum');
        calculate = function(json) {
          var assigned, _i, _len, _ref;
          minimum || (minimum = json.assignedTo.length);
          if (minimum < 0) {
            return (_(json.assignedTo)).chain().pluck('closed').compact().value().length > 0;
          } else {
            _ref = json.assignedTo;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              assigned = _ref[_i];
              if (assigned.closed) {
                minimum--;
              }
            }
            return minimum <= 0;
          }
        };
        if (_.isFunction(json)) {
          callback = json;
          return this.expose(function(err, json) {
            if (!err) {
              return callback(null, calculate(json));
            } else {
              return callback(err);
            }
          });
        } else {
          return calculate(json);
        }
      }
      /*
      		getName: ->
      			return @p 'name'
      		close: ->
      			@p 'status', 'closed'
      		*/
    }
  });
  _.extend(exports, {
    User: User,
    Task: Task
  });
}).call(this);
