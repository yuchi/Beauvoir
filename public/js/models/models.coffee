
###
# Setting up templates
###

$ ->
	tmpl = $('#single-task-view').html()
	dust.loadSource dust.compile tmpl, 'task'

###
# Client side models
###

root = this

Task = Backbone.Model.extend
	defaults: ->
		{
			name: ''
			priority: 1
			status: 'open'
			archived: false
		}

	reverse:
		'open' : 'completed'
		'completed' : 'open'

	initialize: (attributes = {}) ->
		if not attributes.priority? or attributes.priority == 1
			attributes.name or= ''
			match = attributes.name.match /(!+)\s*$/i
			if match and match[1]
				excls = match[1].length
				this.set
					priority: if excls > 1 then 3 else 2
		@ 


	toggle: (options) ->
		newstatus = @reverse[ @get 'status' ]
		@save {status: newstatus}, options
		@

	archive: (options) ->
		@save {archived: true}, options
		@


TaskList = Backbone.Collection.extend
	model: Task
	url: '/tasks'

	initialize: (options) ->
		options or= {}
		_.extend @, options

	done: ->
		@filter (todo) ->
			todo.get('status') == 'completed'

Tasks = new TaskList

TaskView = Backbone.View.extend

	tagName: 'li'
	model: Task

	events:
		'click .toggle'  : 'toggle'
		'click .archive' : 'archive'
		'dblclick .name' : 'open'
		'blur .name'     : 'close'

	initialize: (options) ->
		options or= {}
		_.extend this, options
		@model.view = this
		@model.bind 'change:status',   _.bind @render,    @
		@model.bind 'destroy',         _.bind @remove,    @
		@model.bind 'change:archived', _.bind @onArchive, @

	render: ->
		dust.render 'task', @model.toJSON(), (err, out) =>
			newel = $ out
			$(@el).html newel.html()
			$(@el).attr 'class', newel.attr 'class'
		#$(@el).html @model.get 'name'
		@

	toggle: (event) ->
		@model.toggle()
		@

	archive: (event) ->
		@model.archive()
		@

	open: (event) ->
		self = $(event.target)
		self.attr 'contenteditable', true

	close: (event) ->
		self = $(event.target)
		self.attr 'contenteditable', false
		@model.save
			name: (@$ '.name').text()

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

	addOne: (task) ->
		view = new TaskView {model: task}
		$(@el).append view.render().el

	addAll: (collection) ->
		collection.each @addOne

	create: (name, priority = 1) ->
		Tasks.create
			name: name
			priority: priority

###
# Building things up
###


$ ->
	App = root.App = new AppView

Tasks.fetch()

_.extend root,
	Tasks: Tasks
	Task: Task
