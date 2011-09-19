$ ->
	($ '.input')
		.live( 'focusin', (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', true
		)
		.live( 'focusout', (event) ->
			self = $ event.target
			self.closest('.input').andSelf().toggleClass 'focus', false
		)

	assign = $ '#assign'
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

	name = $ '#name'
	priority = $ '#priority'
	name.bind 'change keypress keyup paste', ->
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

e = (string='') ->
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