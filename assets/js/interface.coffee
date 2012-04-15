$ ->

	($ 'html').addClass 'loaded'

	$('.dd-wrapper').toolbox
		triggerSelector: '.dd-icon'
		panelSelector: '.dd-panel'
		actionsSelector: 'a, .action'

	$(document).on(

		# focusable forms

		focusin: (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', true
		focusout: (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', false
		'.input'

	).on(

		# Modal openers

		click: (event) ->
			self = $ event.target
			self.closest('.modal').hide()
		'.modal-closer'

	).on(

		# Modal closers

		click: (event) ->
			self = $ event.target
			($ self.attr 'href').show()
			event.preventDefault()
		'.modal-opened'

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

	# Priority

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

	# Filters

	filters = $ '#filters'
	

# Utils
# =====

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
