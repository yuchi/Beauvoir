
_ = require 'underscore'
nohm = require 'nohm'
models = require '../models'
winston = require 'winston'

update = (req, res) ->
	attributes = _.clone req.body
	id = attributes.id
	delete attributes.id

	# remove assignations
	assignedTo = attributes.assignedTo
	delete attributes.assignedTo

	if _.isArray assignedTo
		assignedTo = assignedTo[0]

	# is updating?
	task = req.task or new models.Task id
	action = if task.id == id || id then 'update' else 'create'

	# set modifiedDate and (if necessary) createDate
	now = (new Date()).getTime()
	attributes.createDate = now if action == 'create'
	attributes.modifiedDate = now

	### TODO move to .propertyDiff ###
	if task.isArchived() != attributes.archived
		action = if attributes.archived then 'archive' else action 

	# Action from json payload
	closing = !!attributes.closing
	opening = !!attributes.opening

	# `assigning` attributes from json
	assigning = !!attributes.assigning

	for prop in ['closed','open','opening','closing','assigning','status']
		delete attributes[prop]

	# setting things up
	task.p attributes

	complete = ->
		if assigning or not req.task?
			console.log 'passo di qui'
			task.link assignedUser, 'assignedTo'
		if closing
			task.link actor, 'assignedTo'
			task.link actor, 'closedBy'
		else if opening
			task.unlink actor, 'closedBy'

		#task.link owner, 'createdBy'

		task.save (err, relationError, relationName) ->
			if not err
				winston.info "Task \##{task.id} #{action}d successfully"
				task.expose (err, json) ->
					if not err
						res.send json
					else
						winston.error "Error retrieving task data"
			else if relationError
				action = if relationName == 'assignedTo' then 'assign' else 'completely create'
				if relationName
					winston.error "There has been a relationError"
				winston.error "Task \##{task.id} could not be #{action}d"
				winston.debug JSON.stringify task.errors
				res.send 500
			else
				winston.error "Task \##{task.id} could not be #{action}d"
				winston.debug JSON.stringify task.errors
				res.send 500

	actor = new models.User req.session.userId

	if assignedTo
		# assignedToId = assignedTo.id or assignedTo
		assignedUser = new models.User (assignedTo.id or assignedTo)
		assignedUser.load (assignedTo.id or assignedTo), (err, props) ->
			if not err
				actor.load req.session.userId, (err, props) ->
					if not err
						complete()
					else
						winston.error 'Error retrieving users'
			else
				winston.error 'Error retrieving user \#'+(assignedTo.id or assignedTo)
	else
		assignedUser = actor
		actor.load req.session.userId, (err, props) ->
			if not err
				complete()
			else
				winston.error 'Error retrieving users'

_.extend exports,

	index: (req, res) ->
		objects = []
		models.Task.find (err, ids) ->
			if not err
				(pass = _.after ids.length+1, ->
					winston.info "Tasks list successfully retrieved"
					res.send objects
				)()
				_.each ids, (id) ->
					models.Task.load id, (err, properties) ->
						if not err
							@expose (err, object) =>
								if not err
									objects.push object
									pass()
								else
									winston.error 'Error retrieving task properties'

						else
							winston.error "Some error occured loading Task \##{id}"
							pass()
			else
				winston.error "Task list could not be retrieved"
				res.send 500

	show: (req, res) ->
		req.task.expose (err, json) ->
			if not err
				res.send json
			else
				res.send 500

	create: update
	update: update

	destroy: (req, res) ->
		id = req.task.id
		req.task.remove (err) ->
			if not err
				winston.info "Task \##{id} removed successfully"
				res.send req.task.allProperties true
			else
				winston.error "Task \##{id} could not be removed"
				res.send 500

	load: (id, fn) ->
		task = new models.Task
		task.load id, (err, properties) ->
			return fn new Error 'No such task' if err
			fn null, task
