
_ = require 'underscore'
nohm = require 'nohm'
auth = require '../authentication'
models = require '../models'
winston = require 'winston'
helpers = require '../utils/helpers'
{ cascade, multiLoad } = helpers

update = (req, res) -> auth.loadActor req, res, ->

	actor = null

	attributes = _.clone req.body
	id = attributes.id
	delete attributes.id

	assignedTo = _.compact _.flatten [ attributes.assignedTo ]
	assignedUsers = []

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

	# Removing polluted attributes
	for prop in ['closed', 'open', 'opening', 'closing', 'assigning', 'status', 'assignedTo', 'editable']
		delete attributes[ prop ]

	# setting things up
	unless closing or opening 
		task.p attributes

	if not task.p 'creator'
		task.p creator: req.session.userId

	actor = req.actor

	cascade this,

		( next ) ->

			permission = if closing or opening then 'act' else 'update'

			task.hasPermission actor, permission, (err, can) ->
				unless err or not can
					next()
				else
					winston.error err or "Permission denied"

		( next ) ->

			multiLoad assignedTo, ( err, results ) ->
				assignedUsers = results
				if results.length == 0
					assignedUsers.push actor
				next()

		( next ) ->

			if assigning or not req.task?
				##task.link assignedUser, 'assignedTo'
				for assignedUser in assignedUsers
					task.link assignedUser, 'assignedTo'

			if closing
				task.link actor, 'assignedTo'
				task.link actor, 'closedBy'
			else if opening
				task.unlink actor, 'closedBy'

			#task.link owner, 'createdBy'

			task.save next

		( next, err, relationError, relationName ) ->

			if not err
				winston.info "Task #{task.id} #{action}d successfully"
				task.expose actor, next

			else if relationError
				action = if relationName == 'assignedTo' then 'assign' else 'completely create'
				if relationName
					winston.error "There has been a relationError"
				winston.error "Task #{task.id} could not be #{action}d"
				res.send 500
			else
				winston.error "Task #{task.id} could not be #{action}d"
				res.send 500

		( next, err, json ) -> 

			if not err
				res.send json
			else
				winston.error "Error retrieving task data"

_.extend exports,

	index: (req, res) -> auth.loadActor req, res, ->

		objects = []

		cascade null,

			( next ) ->

				if req.user?
					models.Task.find { context: req.user.id }, next
				else
					models.Task.find next

			( next, err, ids ) ->

				if err
					winston.error "Task list could not be retrieved"
					res.send 500
					return

				pass = _.after ids.length, next

				for id in ids

					models.Task.load id, (err, properties) ->

						if err
							winston.error "Some error occured loading Task #{id}"
							return pass()

						if @isArchived()
							return pass()

						@expose req.actor, (err, object) ->

							if err then winston.error 'Error retrieving task properties'
							objects.push object 
							pass()

			( next ) ->

				winston.info "Tasks list successfully retrieved"
				res.send objects


	show: (req, res) ->	auth.loadActor req, res, ->

		req.task.hasPermission req.actor, 'view', ( err, can ) ->

			if err or not can
				return res.send 500

			req.task.expose req.actor, (err, json) ->
				if err
					return res.send 500

				res.send json


	create: update

	update: update

	destroy: (req, res) -> auth.loadActor req, res, ->

		id = req.task.id
		req.task.hasPermission req.actor, 'delete', ( err, can ) ->

			if err or not can
				return res.send 500

			req.task.remove (err) ->
				if not err
					winston.info "Task #{id} removed successfully"
					res.send req.task.allProperties true
				else
					winston.error "Task #{id} could not be removed"
					res.send 500

	load: (id, fn) ->

		task = new models.Task
		task.load id, (err, properties) ->
			return fn new Error 'No such task' if err
			fn null, task
