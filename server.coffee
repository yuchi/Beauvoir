version = '0.1.0'
dev_port = 3000
server_port = 80
config_file = '~/beauvoir.json'


###
# Starting point
###


# Base dependencies
_ = require 'underscore'
fs = require 'fs'
http = require 'http'
path = require 'path'

# Logging

winston = require 'winston'
#winston.add winston.transports.File,
#	filename: 'beauvoir.log'

###
# Persistence

redis = require('redis')
persistence = redis.createClient()
persistence.on 'error', (err) ->
	winston.warn "Redis Client Error: #{ err }"
###

# Application

express = require 'express'
app = express.createServer()
require 'express-resource' # monkey patches

# Other dependencies

##connect = require 'connect'
auth = require './lib/authentication'
jade = require 'jade'
stylus = require 'stylus'
RedisStore = (require 'connect-redis') express

# Application configuration

app.set 'view engine', 'jade'
app.set 'view options',
	layout: false

app.use express.bodyParser()
app.use express.cookieParser()

app.use express.session
	store: new RedisStore()
	secret: 'Secretly I am an unicorn' # what about using a config file?

assets = require 'connect-assets'
app.use assets()

###
# Middlewares and helpers
###

app.use auth.loadActor
app.dynamicHelpers
	actor: auth.actorHelper
	context: auth.contextHelper
	availableContexts: auth.availableContextsHelper


###
# Routes
###


app.get '/logout', (req, res) ->
	winston.info 'Session destroyed'
	req.session.destroy ->
		res.redirect 'home'

signInUser = (req, res) ->
	auth.authenticate req.body.username, req.body.password, (err, user) ->
		winston.error 'Error: '+err if err

		if user
			req.session.regenerate ->
				winston.info 'Setting info for ' + req.session.id
				req.session.cookie.maxAge = 100*24*60*60*1000
				req.session.cookie.httpOnly = false
				req.session.user = user.allProperties true
				req.session.userId = user.id
				#req.hashpassword =
				res.redirect '/'
		else
			res.render 'login',
				locals:
					error: 'Authentication failed' 

app.get '/login', (req, res) ->
	res.render 'login'

app.post '/login', signInUser

app.post '/signup', (req, res) ->

	if not req.body?
		winston.error 'No body for signup'
		res.redirect 'home'
		return

	auth.create req.body.username, req.body.password, req.body.fullname, req.body.email, (err, data)->
		if err
			winston.error err
			res.redirect 'home'
		if data
			winston.info "User '#{req.body.username}' successfully created."
			res.redirect 'home'

app.get '/context-settings', auth.restrict(), auth.loadAvailableContexts, (req, res) ->
	req.actor.getAllowedUsers (err, users) ->
		if not err
			res.render 'context-settings'
				allowedUsers: users
		else
			res.send 500

app.post '/context-settings', (req, res) ->
	TODO

###
app.get '/public/*.(js|css|png)', (req, res) ->
	res.sendfile './' + req.url
###

###
# Resources
###


resources =
	tasks: app.resource 'tasks', require './lib/resources/tasks'
	users: app.resource 'users', require './lib/resources/users'
	#organizations: app.resource 'organizations', require './lib/resources/users'

resources.users.add resources.tasks
#resources.organizations.add resources.tasks


##
# Dynamic data
##


app.get '/dynamic/user.js', auth.restrict(), auth.load, (req, res) -> res.send "window.user=#{JSON.stringify req._user.expose()};"


###
# The base route
###


__l = (req, res, next) ->
	console.dir req.context
	next()

# (req, res) -> res.render 'index'
app.get '/', auth.restrict(), auth.loadAvailableContexts, (req, res) -> res.render 'index'
app.get '/~:context', auth.restrict(), auth.loadAvailableContexts, (req, res) -> res.render 'index'


###
# Opening app
###


# Opening configuration
path.exists config_file, (exists) ->
	if not exists
		app.listen (port = dev_port)
	else
		app.listen (port = server_port)

	winston.info "Beauvoir started on port #{port}"

## End ##
