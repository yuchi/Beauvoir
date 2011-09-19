
_ = require 'underscore'
nohm = require 'nohm'
models = require '../models'
winston = require 'winston'

update = (req, res) ->
	null

parse = (user) ->
	{
		id: user.id
		username: user.username
		fullname: user.fullname
	}

_.extend exports,

	index: (req, res) ->
		objects = []
		mock = new models.User

		search = ( req.query.q or '' ).toLowerCase()

		send = (users) =>
			res.send (_ objects).chain().filter( (user) ->
					return true if search == '*'
					return true if (user.fullname.toLowerCase().indexOf search) >= 0
					return true if (user.username.toLowerCase().indexOf search) >= 0
					return false
				).map( parse ).value()

		mock.find (err, ids) -> # find all
			if err
				winston.error "Users list could not be retrieved"
				res.send 500
			else

				pass = _.after ids.length, ->
					winston.info "Users list successfully retrieved"
					send()

				_.each ids, (id) ->
					user = new models.User
					user.load id, (err, properties) ->
						if err
							winston.error "Some error occured loading User \##{id}"
						else
							console.dir attributes
							attributes = JSON.parse user.allProperties true
							objects.push attributes if not attributes.archived
						pass()

	show: (req, res) ->
		res.send parse JSON.parse req.user.allProperties true

	load: (id, fn) ->
		task = new models.User
		task.load id, (err, properties) ->
			return fn new Error 'No such user' if err
			fn null, task
