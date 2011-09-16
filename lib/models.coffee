
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
			validations: ['notEmpty','email']
		name:
			type: 'string'
			unique: false # !!!
		profile:
			type: 'json'

	methods:
		test: ->
			console.log 'hallo'
		###
		info: (parameter) ->
			profile = @p 'profile'
			if parameter
				profile[parameter]
			else
				parameter
		###
		getGravatar: (size=55) ->
			"https://secure.gravatar.com/avatar/#{@getEmailHash()}?s=#{size}&d=retro"
		getEmailHash: ->
			hashlib.md5 String::toLowerCase.call _.trim @p 'email'


Task = nohm.model 'Task',
	properties:
		name:
			type: 'string'
			unique: false
		priority:
			type: 'integer'
			index: false
			defaultValue: 0
			validations: [
				'notEmpty'
				['min', 1]
				['max', 3]
			]
		status:
			type: 'string'
			index: true
		archived:
			type: 'boolean'
			index: true
			defaultValue: false
		createDate:
			type: 'timestamp'
			validations: ['notEmpty']
		modifiedDate:
			type: 'timestamp'
			validations: ['notEmpty']

	methods:
		isArchived: ->
			arch = @p 'archived'
			not arch or arch != 'false'
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
