
root = this
App = null

# Setting up templates
# --------------------

$ ->
	tmpl = $ '#single-task-view'
	dust.loadSource dust.compile (tmpl.html() or ''), 'task'
	tmpl.remove()

# Client side models
# ------------------

Task = Backbone.Model.extend
	defaults: ->
		name: ''
		priority: 1
		editable: false
		closed: false
		archived: false
		context: App.context.id

	reverse:
		'open' : 'completed'
		'completed' : 'open'

	initialize: (attributes = {}) ->
		# Not elegant...
		if not attributes.priority? or attributes.priority == 1
			attributes.name or= ''
			this.set
				priority: @foreseePriority()
		@

	closedByActor: () ->
		mine = (_ @get 'assignedTo').select (a) -> a.id == App.actor.id
		!! (mine and mine[0] and mine[0].closed)

	archive: (options) ->
		@save {archived: true}, options

	foreseePriority: (name = @get 'name') ->
		return 1 if not name
		match = name.match /(!+)\s*$/i
		if match and match[1]
			excls = match[1].length
			priority = if excls > 1 then 3 else 2
		priority or 1

TaskList = Backbone.Collection.extend
	model: Task

	url: -> "/users/#{App.context.id}/tasks"

	initialize: (options) ->
		options or= {}
		_.extend @, options

	done: ->
		@filter (todo) ->
			todo.get('status') == 'completed'

	__flush: ->
		(execute = =>
			@first()?.destroy
				success: execute )()

Tasks = new TaskList

# Views
# -----

TaskView = Backbone.View.extend

	tagName: 'li'
	model: Task

	events:
		'keyup'          : 'keyHandler'
		'keydown'        : 'keyHandler'
		'click .toggle'  : 'toggle'
		'click .archive' : 'archive'
		'click .trash'   : 'trash'
	#	'dblclick .name' : 'open'
	#	'blur .name'     : 'close'

	keyEvents:
		keyup:
			# Enter
			13: 'toggle'
			# Delete
			8:  'archive'
			# Canc
			46: 'trash'
			# Up
			38: 'focusPrev'
			# Down
			40: 'focusNext'
		keydown:
			8:  'noop'

	initialize: (options) ->
		options or= {}
		_.extend this, options
		@model.view = this
		@model.bind 'change',          _.bind @render,    @
		@model.bind 'destroy',         _.bind @remove,    @
		@model.bind 'change:archived', _.bind @onArchive, @

	render: ->
		json = @model.toJSON()
		json.status = if @model.get 'closed' then 'completed' else 'open'
		if @model.get 'dueDate'
			json.due = => (new Date @model.get 'dueDate').toLocaleDateString()

		dust.render 'task', json, (err, out) =>
			newel = $ out
			$(@el).html newel.html()
			$(@el).attr
				class: newel.attr 'class'
				tabindex: newel.attr 'tabindex'
		@

	keyHandler: (event) ->
		@[@keyEvents?[event.type]?[event.which] or '']? event

	toggleClass: (classname, toggle) ->
		($ @el).toggleClass classname, !!toggle

	toggle: (event) ->
		event?.preventDefault()
		params = {}
		if @model.closedByActor()
			params.opening = true
		else
			params.closing = true

		@model.save params,
			success: => @model.unset 'closing'			

	isEditable: -> !! @model.get 'editable'

	archive: (event) ->
		if @isEditable()
			event?.preventDefault()
			return if not @model.get 'closed'
			@toggleClass 'archiving', true
			root.App.confirm "Do you really want to archive this task?", (really) =>
				@model.archive() unless not really
				@toggleClass 'archiving', false
		@

	trash: (event) ->
		if @isEditable()
			event?.preventDefault()
			@toggleClass 'trashing', true
			root.App.confirm "Do you really want to trash this task?", (really) =>

				if @el is document.activeElement
					@focusPrev() or @focusNext()

				@model.destroy() unless not really
				@toggleClass 'trashing', false
		@

	noop: -> false

	focusPrev: (event) -> !! ($ @el).prev().focus().length
	focusNext: (event) -> !! ($ @el).next().focus().length

	###
	open: (event) ->
		self = $(event.target)
		self.attr 'contenteditable', true

	close: (event) ->
		self = $(event.target)
		self.attr 'contenteditable', false
		@model.save
			name: (@$ '.name').text()
	###

	onArchive: (model, archived) ->
		if archived
			@hide()
		@

	hide: ->
		$(@el).slideUp 'slow'

AppView = Backbone.View.extend

	initialize: (options) ->
		options or=
			el: $ '#tasks'
		_.extend this, options

		_.bindAll @, 'addAll', 'addOne'
		Tasks.bind 'add', @addOne
		Tasks.bind 'reset', @addAll

		@actor = window.actor
		@context = window.context or @actor

		throw "Environment not initialized" unless @actor? and @context?

		@creation = new Creation { app: @ }

	addOne: (task) ->
		view = new TaskView { model: task }
		$(@el).append view.render().el

	addAll: (collection) ->
		collection.each @addOne

	create: (name, assignedTo, due, priority = 1) ->

		if assignedTo?.length > 0
			assignedTo = _.compact _.flatten assignedTo
		else
			assignedTo = []

		props =
			dueDate: due
			name: name
			priority: priority
			assignedTo: assignedTo

		Tasks.create props

	# Interface

	confirm: (message, callback) ->
		result = confirm message
		callback result
	prompt: (message, callback) ->
		result = prompt message
		callback result

Creation = Backbone.View.extend
	events:
		'submit' : 'submit'

	defaults: (dynamic) ->
		el: $ '#creation'
		$name: $ '#name'
		$assign: $ '#assign'
		$due: $ '#due'

	initialize: (options) ->
		options or= {}
		_.extend @, @defaults(), options
		@delegateEvents()

	empty: (callback) ->
		($ @el).animate( {opacity:0}, 200, =>
			callback()
			(@$name.val '').change()
			(@$due.val '').change()
			@$assign.manifest 'remove'
		).animate {opacity:1}, 200
		@

	submit: (event) ->
		event.preventDefault()
		name = @getName()
		if name.length < 3
			@$name.focus()
		else
			@empty => @app.create name, @getAssignedTo(), @getDue()
		false

	getAssignedTo: -> @$assign.manifest 'values'

	getName: -> @$name.val()

	getDue: ->
		val = + new Date @$due.val()
		if isNaN val then null else val

# Build and expose
# ----------------

$ ->
	App = root.App = new AppView
	Tasks.fetch()

_.extend root,
	Tasks: Tasks
	Task: Task
