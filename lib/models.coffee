
# Dependencies

winston = require 'winston'
_ = require 'underscore'
_.mixin require 'underscore.string'
hashlib = require './utils/hashlib'

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

###
Organization = nohm.model 'Organization',
	properties:
		username:
			type: 'string'
			unique: true
			index: true
			validations: ['notEmpty']
		email:
			type: 'string'
			unique: true
			defaultValue: 'error@error.com'
			validations: ['notEmpty','email']
		fullname:
			type: 'string'
			unique: false # !!!
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

		# Async!
		expose: (callback) ->

			task = @

			attributes = @allProperties()
			attributes.archived = @isArchived()
			attributes.assignedTo = []

			@getAll 'User', 'assignedTo', (err, ids) =>
				(pass = _.after ids.length+1, _.once =>
					attributes.archived = @isArchived()
					attributes.closed = @isClosed attributes
					callback null, attributes
				)()
				console.dir ids
				if not err
					for userId in ids
						console.dir userId
						User.load userId, (err, properties) ->
							if not err
								userAttributes = @expose()
								task.belongsTo @, 'closedBy', (err, closed) ->
									if not err
										userAttributes.closed = closed
										attributes.assignedTo.push userAttributes
										pass()
									else
										callback err
										winston.error "Error retrieving closing status for user \##{userId}"
							else
								callback err
								winston.error "Error retrieving user \##{userId}"
				else
					callback err
					winston.error "Error retrieving assigned users to task \##{@id}"
			return @

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
