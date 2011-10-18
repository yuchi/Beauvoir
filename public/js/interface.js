(function() {
  var e, escape;
  $(function() {
    var assign, due, name, priority, resetters;
    ($('html')).addClass('loaded');
    ($('.dd-icon')).bind('click keyup', function(e) {
      var active, panel, self;
      if (e.type === 'click' || +event.which === +13) {
        self = $(this);
        panel = self.closest('.dd-wrapper');
        active = panel.hasClass('opened');
        self.closest('.dd-list').find('.dd-wrapper').removeClass('opened');
        return panel.toggleClass('opened', !active);
      }
    });
    ($('.input')).live('focusin', function(event) {
      var self;
      self = $(event.target);
      return self.closest('.input').andSelf().toggleClass('focus', true);
    }).live('focusout', function(event) {
      var self;
      self = $(event.target);
      return self.closest('.input').andSelf().toggleClass('focus', false);
    });
    ($('.modal-closer')).live('click', function(event) {
      var self;
      self = $(event.target);
      return self.closest('.modal').hide();
    });
    ($('.modal-opener')).live('click', function(event) {
      var self;
      self = $(event.target);
      ($(self.attr('href'))).show();
      return event.preventDefault();
    });
    assign = $('#assign');
    assign.bind('change marcopolochange', function() {
      var self;
      self = $(this);
      return self.toggleClass('filled', !!self.val());
    });
    assign.marcoPolo({
      url: '/users',
      required: true,
      formatItem: function(data, $item) {
        return "<b>" + (e(data.fullname)) + "</b> <i>" + (e(data.username)) + "</i>";
      },
      onChange: function(q) {
        this.data({
          user: null
        });
        return this.siblings('.validator').andSelf().removeClass('valid');
      },
      onSelect: function(data, $item) {
        this.data({
          user: data
        });
        this.val(data.username);
        return this.siblings('.validator').andSelf().addClass('valid');
      }
    });
    name = $('#name');
    priority = $('#priority');
    name.bind('change keypress keyup paste focus blur', function() {
      var foreseen, i, self, _i, _len, _ref, _results;
      self = $(this);
      foreseen = Task.prototype.foreseePriority(self.val());
      if (foreseen === 1) {
        priority.text('');
      }
      if (foreseen === 2) {
        priority.text('!');
      }
      if (foreseen === 3) {
        priority.text('!!');
      }
      _ref = [1, 2, 3];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        _results.push(priority.toggleClass('priority-' + i, i === foreseen));
      }
      return _results;
    });
    due = $('#due');
    due.bind('blur change focus', _.throttle((function(event) {
      var dueDate;
      dueDate = new Date(due.val());
      return due.siblings('.validator').andSelf().toggleClass('valid', !isNaN(+dueDate));
    }), 100));
    due.datepicker();
    resetters = $('.reset');
    resetters.bind('click keyup', function(event) {
      var input;
      if (event.type === 'click' || +event.which === +13) {
        input = $(event.target).siblings('input');
        input.val('');
        return input.focus();
      }
    });
    return ($(window)).resize(function() {
      return due.datepicker('hide');
    });
  });
  e = escape = function(string) {
    if (string == null) {
      string = '';
    }
    return string.replace(/&(?!\w+;|#\d+;|#x[\da-f]+;)/gi, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g, '&#x2F;');
  };
  /*
  	w = ($ window)
  	w.delegate 'input.h', 'focus', (event) ->
  		self = $ event.target
  		parent = self.closest '.input'
  		parent.addClass 'focus'
  	w.blur 'input.h', 'blur', (event) ->
  		self = $ event.target
  		parent = self.closest '.input'
  		parent.removeClass 'focus'
  	*/
}).call(this);
