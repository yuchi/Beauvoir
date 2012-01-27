$ ->

	($ 'html').addClass 'loaded'

	dropdowns = $ '.dd-icon:not(.fake)'
	dropdowns.on 'mousedown keydown', (e) ->

		if e.type == 'mousedown' or e.which in [13, 37, 38, 39, 40]
			e.preventDefault()

			self = ($ @)
			wrapper = self.closest '.dd-wrapper'
			panel = wrapper.find '.dd-panel'
			active = wrapper.hasClass 'opened'

			if e.which == 40 and active
				panel.find( 'a, .action' ).eq(0).focus()
				return

			if e.which == 38 and not active
				return

			if e.which == 39
				next = wrapper.next().find('.dd-icon').focus()
				next.mousedown() if active
				return

			if e.which == 37
				prev = wrapper.prev().find('.dd-icon').focus()
				prev.mousedown() if active
				return

			self.closest('.dd-list').find('.dd-wrapper').removeClass 'opened'
			wrapper.toggleClass 'opened', not active

	dropdowns.next().find( 'a, .action' ).on
		hover: (e) ->
			$(this).toggleClass 'hover', e.type == 'mouseenter'

		keydown: (e) ->
			return if e.which not in [ 38, 40 ]

			e.preventDefault()

			dir = if e.which == 38 then 'prev' else 'next'
			self = $ this
			to = self[ dir ]()
			if not to.length
				to = self.parent()[ dir ]().find( 'a, .action' )
				to = to.eq if dir is 'next' then 0 else -1

			if dir is 'prev' and not to.length
				wrapper = self.closest '.dd-wrapper'
				#wrapper.removeClass 'opened'
				wrapper.find('.dd-icon').focus()
				return

			to.focus()
			

		mouseup: ->
			self = $(this).click (e) ->
				href = self.attr 'href'
				if href? and not e.isDefaultPrevented()
					window.location.href = href
			self.click()

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
