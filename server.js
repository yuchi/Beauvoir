(function() {
  var RedisStore, app, auth, config_file, dev_port, express, fs, http, jade, path, resources, server_port, signInUser, stylus, version, winston, _, __l;
  version = '0.1.0';
  dev_port = 3000;
  server_port = 80;
  config_file = '~/beauvoir.json';
  /*
  # Starting point
  */
  _ = require('underscore');
  fs = require('fs');
  http = require('http');
  path = require('path');
  winston = require('winston');
  winston.add(winston.transports.File, {
    filename: 'beauvoir.log'
  });
  /*
  # Persistence
  
  redis = require('redis')
  persistence = redis.createClient()
  persistence.on 'error', (err) ->
  	winston.warn "Redis Client Error: #{ err }"
  */
  express = require('express');
  app = express.createServer();
  require('express-resource');
  auth = require('./lib/authentication');
  jade = require('jade');
  stylus = require('stylus');
  RedisStore = (require('connect-redis'))(express);
  app.set('view engine', 'jade');
  app.set('view options', {
    layout: false
  });
  app.use(express.bodyParser());
  app.use(express.cookieParser());
  app.use(express.session({
    store: new RedisStore(),
    secret: 'Secretly I am an unicorn'
  }));
  /*
  # Middlewares and helpers
  */
  app.use(auth.loadActor);
  app.dynamicHelpers({
    actor: auth.actorHelper,
    context: auth.contextHelper,
    availableContexts: auth.availableContextsHelper
  });
  /*
  # Routes
  */
  app.get('/logout', function(req, res) {
    winston.info('Session destroyed');
    return req.session.destroy(function() {
      return res.redirect('home');
    });
  });
  signInUser = function(req, res) {
    return auth.authenticate(req.body.username, req.body.password, function(err, user) {
      if (err) {
        winston.error('Error: ' + err);
      }
      if (user) {
        return req.session.regenerate(function() {
          winston.info('Setting info for ' + req.session.id);
          req.session.cookie.maxAge = 100 * 24 * 60 * 60 * 1000;
          req.session.cookie.httpOnly = false;
          req.session.user = user.allProperties(true);
          req.session.userId = user.id;
          return res.redirect('/');
        });
      } else {
        return res.render('login', {
          locals: {
            error: 'Authentication failed'
          }
        });
      }
    });
  };
  app.get('/login', function(req, res) {
    return res.render('login');
  });
  app.post('/login', signInUser);
  app.post('/signup', function(req, res) {
    if (!(req.body != null)) {
      winston.error('No body for signup');
      res.redirect('home');
      return;
    }
    return auth.create(req.body.username, req.body.password, req.body.fullname, req.body.email, function(err, data) {
      if (err) {
        winston.error(err);
        res.redirect('home');
      }
      if (data) {
        winston.info("User '" + req.body.username + "' successfully created.");
        return res.redirect('home');
      }
    });
  });
  app.get('/context-settings', auth.restrict(), auth.loadAvailableContexts, function(req, res) {
    return req.actor.getAllowedUsers(function(err, users) {
      if (!err) {
        return res.render('context-settings', {
          allowedUsers: users
        });
      } else {
        return res.send(500);
      }
    });
  });
  app.post('/context-settings', function(req, res) {
    return TODO;
  });
  app.get('/public/*.(js|css|png)', function(req, res) {
    return res.sendfile('./' + req.url);
  });
  /*
  # Resources
  */
  resources = {
    tasks: app.resource('tasks', require('./lib/resources/tasks')),
    users: app.resource('users', require('./lib/resources/users'))
  };
  resources.users.add(resources.tasks);
  app.get('/dynamic/user.js', auth.restrict(), auth.load, function(req, res) {
    return res.send("window.user=" + (JSON.stringify(req._user.expose())) + ";");
  });
  /*
  # The base route
  */
  __l = function(req, res, next) {
    console.dir(req.context);
    return next();
  };
  app.get('/', auth.restrict(), auth.loadAvailableContexts, function(req, res) {
    return res.render('index');
  });
  app.get('/~:context', auth.restrict(), auth.loadAvailableContexts, function(req, res) {
    return res.render('index');
  });
  /*
  # Opening app
  */
  path.exists(config_file, function(exists) {
    var port;
    if (!exists) {
      app.listen((port = dev_port));
    } else {
      app.listen((port = server_port));
    }
    return winston.info("Beauvoir started on port " + port);
  });
}).call(this);
