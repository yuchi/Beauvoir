
_ = require 'underscore'
nohm = require 'nohm'
models = require '../models'
winston = require 'winston'

update = (req, res) ->
	attributes = _.clone req.body
	id = attributes.id
	delete attributes.id

	assignedTo = attributes.assignedTo
	delete attributes.assignedTo

	task = req.task or new models.Task id
	action = if task.id == id || id then 'update' else 'create'

	now = (new Date()).getTime()
	attributes.createDate = now if action == 'create'
	attributes.modifiedDate = now

	### TODO move to .propertyDiff ###
	if task.isArchived() != attributes.archived
		action = if attributes.archived then 'archive' else action 

	task.p attributes

	complete = ->
		task.link assignedUser, 'assignedTo'
		#task.link owner, 'createdBy'

		task.save (err, relationError, relationName) ->
			if not err
				winston.info "Task \##{task.id} #{action}d successfully"
				res.send JSON.parse task.allProperties true
			else if relationError
				action = if relationName == 'assignedTo' then 'assign' else 'completely create'
				winston.error "Task \##{task.id} could not be #{action}d"
				winston.debug JSON.stringify task.errors
				res.send 500
			else
				winston.error "Task \##{task.id} could not be #{action}d"
				winston.debug JSON.stringify task.errors
				res.send 500

	owner = new models.User req.session.userId

	if assignedTo
		# assignedToId = assignedTo.id or assignedTo
		assignedUser = new models.User (assignedTo.id or assignedTo)
	else
		assignedUser = owner

	complete();

_.extend exports,

	index: (req, res) ->
		objects = []
		mock = new models.Task
		mock.find (err, ids) -> # find all
			if not err
				(pass = _.after ids.length+1, ->
					winston.info "Tasks list successfully retrieved"
					res.send objects
				)()
				_.each ids, (id) ->
					task = new models.Task id
					task.load id, (err, properties) ->
						if not err
							attributes = JSON.parse task.allProperties true
							attributes.archived = task.isArchived()
							if attributes.archived
								pass()
							else
								# This whole thing here sucks. It's better to create some ServiceUtils.
								task.getAll 'User', 'assignedTo', (err, userIds) ->
									(pass2 = _.after userIds.length+1, ->
										objects.push attributes
										pass()
									)()
									_.each userIds, (assignedId) ->
										assigned = new models.User assignedId
										assigned.load assignedId, (err, properties) ->
											if err
												winston.error "User \##{assignedId} could not be retrieved"
											else
												attributes['assignedTo'] = assigned.expose()
												#do something with user
											pass2()

						else
							winston.error "Some error occured loading Task \##{id}"
							pass()
			else
				winston.error "Task list could not be retrieved"
				res.send 500

	show: (req, res) ->
		res.send JSON.parse req.task.allProperties true

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
