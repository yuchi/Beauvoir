
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
		closed: false
		archived: false
		context: App.context.id

	reverse:
		'open' : 'completed'
		'completed' : 'open'

	initialize: (attributes = {}) ->
		### Not elegant... ###
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
		'click .toggle'  : 'toggle'
		'click .archive' : 'archive'
	#	'dblclick .name' : 'open'
	#	'blur .name'     : 'close'

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
		#$(@el).html @model.get 'name'
		@

	keyHandler: (event) ->
		if event.which == 13
			@toggle event

	toggle: (event) ->

		console.log _.clone @model.attributes

		params = {}
		if @model.closedByActor()
			params.opening = true
		else
			params.closing = true

		@model.save params,
			success: => @model.unset 'closing'			

	archive: (event) ->
		@model.archive()
		@

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

		@creation = new Creation
			app: @

	addOne: (task) ->
		view = new TaskView {model: task}
		$(@el).append view.render().el

	addAll: (collection) ->
		collection.each @addOne

	create: (name, assignedTo, due, priority = 1) ->
		console.log arguments
		Tasks.create
			dueDate: due
			name: name
			priority: priority
			assignedTo: [assignedTo]

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
			@$assign.marcoPolo 'change', ''
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

	getAssignedTo: -> @$assign.data 'user'

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
