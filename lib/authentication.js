(function() {
  var authenticate, create, encrypt, hashlib, load, models, persistence, redis, restrict, verify, winston, _;
  if (!(typeof exports !== "undefined" && exports !== null)) {
    throw 'Node only';
  }
  winston = require('winston');
  _ = require('underscore');
  redis = require('redis');
  persistence = redis.createClient();
  hashlib = require('./utils/hashlib');
  models = require('./models');
  encrypt = function(pass, salt) {
    return hashlib.sha512(salt + '_' + pass);
  };
  restrict = exports.restrict = function(reverse, redirect) {
    if (reverse == null) {
      reverse = false;
    }
    if (redirect == null) {
      redirect = '/login';
    }
    return function(req, res, next) {
      var able;
      able = req.session.user != null;
      if (able === !reverse) {
        return next();
      } else {
        req.session.error = 'Permission denied';
        if (_.isFunction(redirect)) {
          redirect = redirect(req, res);
        }
        return res.redirect(redirect);
      }
    };
  };
  restrict.reverse = function(redirect) {
    return restrict(true, redirect);
  };
  create = exports.create = function(username, password, fullname, email, fn) {
    var hashed, salt, user;
    salt = new Date().getTime();
    hashed = encrypt(password, salt);
    user = new models.User;
    user.prop({
      username: username,
      salt: salt,
      password: hashed,
      email: email
    }, true);
    return user.save(function(err) {
      if (err) {
        return fn(err);
      } else {
        return fn(null, user);
      }
    });
    /*
    	ns = '[Authentication::signup] '
    
    	newUser =
    		fullname: fullname
    		username: username
    		email: email
    
    	rKey = 'user:'+username
    
    	persistence.get rKey, (err, data) ->
    		return fn new Error( ns+ "GET failed for key: #{rKey} for value: #{username}") if err
    	
    		return fn new Error( ns+ "user already exists") if data
    
    		persistence.set rKey, username, (err, data) ->
    			return fn new Error( ns+ "SET failed for key: #{rKey} for value: #{username}") if err
    
    			salt = new Date().getTime()
    			persistence.set rKey+'.salt', salt, (err, data) ->
    				return fn new Error( ns+ "SET failed for key: #{rKey}.salt for value: #{salt}") if err
    
    				hashPass = hashlib.sha512(salt + '_' + pass)
    				persistence.set rKey+'.hashPass', hashPass, (err, data) ->
    					return fn new Error( ns+ "SET failed for key: #{rKey}.hashPass for value: #{hashPass}") if err
    
    					profile = JSON.stringify newUser
    					persistence.set rKey, profile, (err, data) ->
    						return fn new Error( ns+ "SET failed for key: #{rKey}.profile for value: #{profile}") if err
    
    						winston.info 'User created, sending back ' + profile
    						return fn null, newUser
    	*/
  };
  authenticate = exports.authenticate = function(username, password, fn) {
    var mock;
    mock = new models.User;
    return mock.find({
      username: username
    }, function(err, ids) {
      var user;
      if (err) {
        return fn(err);
      }
      if (!ids.length) {
        return fn(new Error('No user associated with that username'));
      }
      user = new models.User;
      return user.load(ids[0], function(err, properties) {
        if (err) {
          return fn(err);
        }
        return verify(username, password, user.allProperties(true), user, fn);
      });
    });
    /*
    	ns = '[Authentication::authenticate] '
    
    	rKey = 'user:'+username
    	persistence.get rKey, (err, data) ->
    		return fn new Error( ns+ "GET failed for key: #{rKey}") if err
    		return fn new Error( ns+ "user '#{username} not found in realm") if not data
    	
    		verify data, username, password, fn
    	*/
  };
  verify = function(username, password, properties, user, fn) {
    var hashed, salt;
    salt = user.p('salt');
    hashed = encrypt(password, salt);
    if (user.p('password') === hashed) {
      return fn(null, user, properties);
    } else {
      return fn(new Error('password mismatch'));
    }
    /*
    	user = JSON.parse data
    	return fn new Error() if user.username != username
    
    	rKey = 'user:'+username
    	persistence.get rKey+'.salt', (err, salt) ->
    		return fn new Error() if err
    		return fn new Error() if not salt
    
    		calculatedHash = hashlib.sha512 salt+'_'+password
    		persistence.get rKey+'.hashPass', (err, hashPass) ->
    			return fn new Error() if err
    
    			if hashPass == calculatedHash
    				winston.info 'Authentication succeeded for '+username
    
    				return fn null, user
    	*/
  };
  load = exports.load = function(req, res, next) {
    var id, user;
    id = req.session.userId;
    user = new models.User(id);
    return user.load(id, function(err, properties) {
      if (err) {
        return res.send(500);
      } else {
        req.user = user;
        return next();
      }
    });
  };
}).call(this);
