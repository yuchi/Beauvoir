
_ = require 'underscore'
nohm = require 'nohm'
models = require '../models'
winston = require 'winston'

update = (req, res) ->
		attributes = _.clone req.body
		id = attributes.id
		delete attributes.id

		task = req.task or new models.Task id
		action = if task.id == id || id then 'update' else 'create'

		now = (new Date()).getTime()
		attributes.createDate = now if action == 'create'
		attributes.modifiedDate = now

		action = 'archive' if task.isArchived != attributes.archived and attributes.archived

		task.p attributes
		task.save (err) ->
			if err
				winston.error "Task \##{task.id} could not be #{action}d"
				console.dir task
				res.send 500
			else
				winston.info "Task \##{task.id} #{action}d successfully"
				res.send JSON.parse task.allProperties true 

_.extend exports,

	index: (req, res) ->
		objects = []
		mock = new models.Task
		mock.find (err, ids) -> # find all
			if err
				winston.error "Task list could not be retrieved"
				res.send 500
			else
				pass = _.after ids.length, ->
					winston.info "Tasks list successfully retrieved"
					res.send objects
				_.each ids, (id) ->
					task = new models.Task
					task.load id, (err, properties) ->
						if err
							winston.error "Some error occured loading Task \##{id}"
						else
							console.dir attributes
							attributes = JSON.parse task.allProperties true
							attributes.archived = task.isArchived()
							objects.push attributes if not attributes.archived
						pass()

	show: (req, res) ->
		res.send JSON.parse req.task.allProperties true

	create: update
	update: update

	destroy: (req, res) ->
		id = req.task.id
		req.task.remove (err) ->
			if err
				winston.error "Task \##{id} could not be removed"
				res.send 500
			else
				winston.info "Task \##{id} removed successfully"
				res.send req.task.allProperties true

	load: (id, fn) ->
		task = new models.Task
		task.load id, (err, properties) ->
			return fn new Error 'No such task' if err
			fn null, task
