throw 'Node only' if not exports?

winston = require 'winston'
_ = require 'underscore'
redis = require 'redis'
persistence = redis.createClient()
hashlib = require './utils/hashlib'

models = require './models'

encrypt = (pass, salt) ->
	hashlib.sha512 salt+'_'+pass

restrict = exports.restrict = (reverse = false, redirect = '/login') ->
	return (req, res, next) ->
		able = req?.session?.user?
		if able == not reverse
			next()
		else if req.session?
			req.session.error = 'Permission denied'
			redirect = redirect req, res if _.isFunction redirect
			res.redirect redirect

restrict.reverse = (redirect) ->
	restrict true, redirect

create = exports.create = (username, password, fullname, email, fn) ->

	salt = new Date().getTime()
	hashed = encrypt password, salt

	user = new models.User
	user.prop(
		{
			username: username
			fullname: fullname
			password: hashed
			email: email
			salt: salt
		}, true
	)

	user.save (err) ->
		if err
			fn err, user
		else
			fn null, user

	###
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
	###

authenticate = exports.authenticate = (username, password, fn) ->

	mock = new models.User
	mock.find { username: username }, (err, ids) ->
			return fn err if err
			return fn new Error 'No user associated with that username' if not ids.length
			user = new models.User
			user.load ids[0], (err, properties) ->
				return fn err if err
				verify username, password, user.allProperties(true), user, fn

	###
	ns = '[Authentication::authenticate] '

	rKey = 'user:'+username
	persistence.get rKey, (err, data) ->
		return fn new Error( ns+ "GET failed for key: #{rKey}") if err
		return fn new Error( ns+ "user '#{username} not found in realm") if not data
	
		verify data, username, password, fn
	###

verify = (username, password, properties, user, fn) ->
	salt = user.p('salt')
	hashed = encrypt password, salt
	if user.p('password') == hashed
		fn null, user, properties
	else
		fn new Error 'password mismatch'
	###
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
	###

###
# Unused
loadActor = exports.loadActor = (req, res, next) ->
	models.User.load req.session.userId, (err, properties) ->
		if err
			res.send 500
		else
			req.actor = @
			next()
###

# I love coffeescript...
_.extend exports,
	actorHelper: (req, res) -> req.actor
	contextHelper: (req, res) -> req.context
	availableContextsHelper: (req, res) -> req.availableContexts

loadActor = exports.loadActor = (req, res, next) ->
	if req.session?.userId
		models.User.load req.session.userId, (err, properties) ->
			if not err
				req.actor = @
				next()
			else
				res.send 500
	else
		next()

loadContextName = exports.loadContextName = (req, res, next) ->
	if req.params?.context?
		req.contextName = req.params.context
	else if req.actor?
		req.contextName = req.actor.property 'username'
	next()

loadContext = exports.loadContext = (req, res, next) ->
	loadContextName req, res, ->
		if req.contextName?
			models.User.find { username: req.contextName }, (err, ids) ->
				res.send 500 if not ids?.length
				models.User.load ids[0], (err, properties) ->
					if not err
						req.context = @
						next()
					else
						res.send 500
		else
			# TODO
			res.send 500

loadAvailableContexts = exports.loadAvailableContexts = (req, res, next) ->
	complete = ->
		req.availableContexts = [req.actor]
		req.actor.getAll 'User', 'parent', (err, ids) ->
			if not err
				(pass = _.after ids.length+1, ->
					next()
				)()
				_.each ids, (id) ->
					models.User.load id, (err, properties) ->
						req.availableContexts.push @ unless err
						pass()
			else
				res.send 500

	if req.context
		complete()
	else
		loadContext req, res, complete
