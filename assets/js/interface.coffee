$ ->

	($ 'html').addClass 'loaded'

	($ '.dd-icon:not(.fake)').bind 'click keyup', (e) ->
		if e.type == 'click' or +event.which == +13
			self = ($ @)
			panel = self.closest('.dd-wrapper')
			active = panel.hasClass 'opened'
			self.closest('.dd-list').find('.dd-wrapper').removeClass 'opened'
			panel.toggleClass 'opened', not active

	($ '.input')
		.live( 'focusin', (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', true
		)
		.live( 'focusout', (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', false
		)

	($ '.modal-closer')
		.live( 'click', (event) ->
			self = $ event.target
			self.closest('.modal').hide()
		)

	($ '.modal-opener')
		.live( 'click', (event) ->
			self = $ event.target
			($ self.attr 'href').show()
			event.preventDefault()
		)

	assign = $ '#assign'
	assign.manifest

		required: true

		formatDisplay: (data, $item) -> data.username

		formatValue: (data, $item) -> data.id

		formatRemove: -> '\u00D7'

		marcoPolo:

			url: '/users'

			formatItem: (data, $item) ->
				"<b>#{e(data.fullname)}</b> <i>#{e(data.username)}</i>"

			###
			onChange: (q) ->
				this.data {user: null}
				this.siblings('.validator').andSelf().removeClass 'valid'

			onSelect: (data, $item) ->
				this.data {user: data}
				this.val data.username
				this.siblings('.validator').andSelf().addClass 'valid'
			###

	###
	assign.bind 'change marcopolochange', ->
		self = $ this
		self.toggleClass 'filled', !!self.val()
	assign.marcoPolo
		url: '/users'
		required: true
		formatItem: (data, $item) ->
			"<b>#{e(data.fullname)}</b> <i>#{e(data.username)}</i>"
		onChange: (q) ->
			this.data {user: null}
			this.siblings('.validator').andSelf().removeClass 'valid'
		onSelect: (data, $item) ->
			this.data {user: data}
			this.val data.username
			this.siblings('.validator').andSelf().addClass 'valid'
	###

	name = $ '#name'
	priority = $ '#priority'
	name.bind 'change keypress keyup paste focus blur', ->
		self = $ this
		foreseen = Task::foreseePriority self.val()
		if foreseen == 1
			priority.text ''
		if foreseen == 2
			priority.text '!'
		if foreseen == 3
			priority.text '!!'
		for i in [1,2,3]
			priority.toggleClass 'priority-'+i, i == foreseen

	due = $ '#due'
	due.bind 'blur change focus', _.throttle ((event) ->
			dueDate = new Date due.val()
			due.siblings('.validator').andSelf().toggleClass 'valid', !isNaN +dueDate
		), 100
	due.datepicker();

	resetters = $ '.reset'
	resetters.bind 'click keyup', (event) ->
		if event.type == 'click' or +event.which == +13
			input = $(event.target).siblings 'input'
			input.val ''
			input.focus()

	# Datepicker is not as cool as Marcopolo, so it's appended as an absolutely positioned div
	# directly to the document. When the page resizes the input moves... but not the Darepicker.
	($ window).resize ->
		due.datepicker 'hide'

e = escape = (string='') ->
    string.replace(/&(?!\w+;|#\d+;|#x[\da-f]+;)/gi, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')

	###
	w = ($ window)
	w.delegate 'input.h', 'focus', (event) ->
		self = $ event.target
		parent = self.closest '.input'
		parent.addClass 'focus'
	w.blur 'input.h', 'blur', (event) ->
		self = $ event.target
		parent = self.closest '.input'
		parent.removeClass 'focus'
	###
