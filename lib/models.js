(function() {
  var Task, User, hashlib, nohm, persistence, redis, winston, _;
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
        validations: ['notEmpty', 'email']
      },
      name: {
        type: 'string',
        unique: false
      },
      profile: {
        type: 'json'
      }
    },
    methods: {
      test: function() {
        return console.log('hallo');
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
      status: {
        type: 'string',
        index: true
      },
      archived: {
        type: 'boolean',
        index: true,
        defaultValue: false
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
    methods: {
      isArchived: function() {
        var arch;
        arch = this.p('archived');
        return !arch || arch !== 'false';
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
