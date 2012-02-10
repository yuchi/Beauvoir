
# Dependencies

winston = require 'winston'
_ = require 'underscore'
_.mixin require 'underscore.string'
hashlib = require './utils/hashlib'
helpers = require './utils/helpers'
{ cascade, multiLoad } = helpers

redis = require 'redis'
persistence = redis.createClient()

nohm = (require 'nohm').Nohm
nohm.setClient persistence

nohm.setPrefix 'beauvoir'
nohm.logError = (err) ->
	if err
		winston.error err
		console.trace()

###
# Top Models
###


User = nohm.model 'User',
	properties:
		username:
			type: 'string'
			unique: true
			index: true
			validations: ['notEmpty']
		salt:
			type: 'timestamp'
			validations: ['notEmpty']
		password:
			type: 'string'
			validations: ['notEmpty']
		email:
			type: 'string'
			unique: true
			defaultValue: 'error@error.com'
			validations: ['notEmpty','email']
		fullname:
			type: 'string'
			unique: false # !!!
		kind:
			type: 'integer'
			defaultValue: -> User.kinds.PERSON
		profile:
			type: 'json'

	#idGenerator: 'increment'

	methods:
		expose: ->
			id: @id
			fullname: @p 'fullname'
			username: @p 'username'
			#emailhash: @getEmailHash()
		###
		info: (parameter) ->
			profile = @p 'profile'
			if parameter
				profile[parameter]
			else
				parameter
		###
		getGravatar: (size=55) -> "https://secure.gravatar.com/avatar/#{@getEmailHash()}?s=#{size}&d=retro"
		getEmailHash: -> hashlib.md5 String::toLowerCase.call _.trim @p 'email'
		isOrganization: -> User.kinds.ORGANIZATION == @p 'kind'
		isPerson: -> User.kinds.PERSON == @p 'kind'

		getAllowedUsers: (callback) ->
			broken = false
			callback = _.once callback
			this.getAll 'User', (err, ids) ->
				if not err
					users = []
					(pass = _.after ids.length+1, ->
						callback null, users
					)()
					for id in ids
						User.load id, (err, properties) ->
							if not err
								users.push @
								pass()
							else if not broken
								broken = true
								callback err
				else
					callback err

		disallow: (id, callback) ->
			context = @
			target = null
			User.load id, (err, properties) ->
				target = @
				if not err
					context.unlink target
					context.save (err) ->
						winston.info "Context #{context.id} has successfully disallowed User #{target.id}" unless err
						callback err
				else
					callback err

		allow: (id, callback) ->
			context = @
			target = null
			User.load id, (err, properties) ->
				target = @
				if not err and context.id != @id
					context.link target
					context.save (err) ->
						console.log 'here 2'
						winston.info "Context #{context.id} has successfully allowed User #{target.id}" unless err
						callback err
				else
					callback err

		allowBySearch: (search, callback) ->
			context = @
			broken = false
			found = []
			pass = _.after 2, ->
				found = _.uniq _.flatten found
				(pass = _.after found.length+1, ->
					callback null
				)()
				for id in found
					context.allow id, (err) ->
						if not err
							callback null
						else if not broken
							broken = true
							callback err
 

			User.find username: search, (err, ids) ->
				if not err
					found.push ids
					pass()
				else if not broken
					broken = true
					callback err
			User.find email: search, (err, ids) ->
				if not err
					found.push ids
					pass()
				else if not broken
					broken = true
					callback err

User.kinds =
	PERSON: 0
	ORGANIZATION: 1

User.kinds.reverse =
	0: 'person'
	1: 'organization'

Task = nohm.model 'Task',
	properties:
		name:
			type: 'string'
			unique: false
		context:
			type: 'string'
			index: true
		creator:
			type: 'string'
			defaultValue: ''
		priority:
			type: 'integer'
			index: false
			defaultValue: 0
			validations: [
				'notEmpty'
				['min', 1]
				['max', 3]
			]
		minimum:
			type: 'integer'
			defaultValue: -1
		archived:
			type: 'boolean'
			index: true
			defaultValue: false
		dueDate:
			type: 'timestamp'
			index: true
		createDate:
			type: 'timestamp'
			defaultValue: -> new Date()
			validations: ['notEmpty']
		modifiedDate:
			type: 'timestamp'
			validations: ['notEmpty']

	#idGenerator: 'increment'

	methods:

		isArchived: ->
			arch = @p 'archived'
			if !!arch == arch
				arch
			else
				arch != 'false'


		hasPermission: (user, action, callback) ->
			task = @

			if user.id in [ @p('context'), @p('creator') ]
				return callback null, true

			User.load @p('context'), (err, props) ->
				return callback err if err
				switch action

					when 'act', 'view'
						@.belongsTo user, 'child', callback

					when 'update', 'delete'
						@.belongsTo user, 'admin', callback


		expose: ( actor, callback ) ->

			task = @

			if typeof actor == 'function'
				callback = actor
				actor = null

			attributes = @allProperties()
			attributes.archived = @isArchived()
			attributes.assignedTo = []

			cascade this,

				( next ) ->

					@getAll 'User', 'assignedTo', (err, ids) ->

						if err
							winston.error "Error retrieving assigned users to task \##{@id}"
							return callback err

						pass = _.after ids.length, next

						for userId in ids
							# console.dir userId
							User.load userId, (err, properties) ->
								if not err
									userAttributes = @expose()
									task.belongsTo @, 'closedBy', (err, closed) ->
										if not err
											userAttributes.closed = closed
											attributes.assignedTo.push userAttributes
										else
											callback err
											winston.error "Error retrieving closing status for user \##{userId}"
										pass()
								else
									pass()
									callback err
									winston.error "Error retrieving user \##{userId}"

				( next ) ->

					attributes.archived = @isArchived()
					attributes.closed = @isClosed attributes

					if actor
						task.hasPermission actor, 'update', next
					else
						next null, false

				( next, err, editable ) ->

					attributes.editable = true if editable

					callback null, attributes


		isClosed: (json) ->
			minimum = @property 'minimum'

			calculate = (json) ->
				minimum or= json.assignedTo.length
				if minimum < 0
					return (_ json.assignedTo).chain().pluck('closed').compact().value().length > 0
				else
					for assigned in json.assignedTo
						if assigned.closed
							minimum--
					return minimum <= 0

			if _.isFunction json
				callback = json
				@expose (err, json) ->
					if not err
						callback null, calculate json
					else
						callback err
			else
				calculate json

		###
		getName: ->
			return @p 'name'
		close: ->
			@p 'status', 'closed'
		###

# Publishing objects
_.extend exports,
	User: User
	Task: Task
