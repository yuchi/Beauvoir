(function() {
  var AppView, Creation, Task, TaskList, TaskView, Tasks, root;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = this;
  $(function() {
    var tmpl;
    tmpl = $('#single-task-view');
    dust.loadSource(dust.compile(tmpl.html(), 'task'));
    return tmpl.remove();
  });
  Task = Backbone.Model.extend({
    defaults: function() {
      return {
        name: '',
        priority: 1,
        closed: false,
        archived: false
      };
    },
    reverse: {
      'open': 'completed',
      'completed': 'open'
    },
    initialize: function(attributes) {
      if (attributes == null) {
        attributes = {};
      }
      /* Not elegant... */
      if (!(attributes.priority != null) || attributes.priority === 1) {
        attributes.name || (attributes.name = '');
        this.set({
          priority: this.foreseePriority()
        });
      }
      return this;
    },
    archive: function(options) {
      return this.save({
        archived: true
      }, options);
    },
    foreseePriority: function(name) {
      var excls, match, priority;
      if (name == null) {
        name = this.get('name');
      }
      if (!name) {
        return 1;
      }
      match = name.match(/(!+)\s*$/i);
      if (match && match[1]) {
        excls = match[1].length;
        priority = excls > 1 ? 3 : 2;
      }
      return priority || 1;
    }
  });
  TaskList = Backbone.Collection.extend({
    model: Task,
    url: '/tasks',
    initialize: function(options) {
      options || (options = {});
      return _.extend(this, options);
    },
    done: function() {
      return this.filter(function(todo) {
        return todo.get('status') === 'completed';
      });
    }
  });
  Tasks = new TaskList;
  TaskView = Backbone.View.extend({
    tagName: 'li',
    model: Task,
    events: {
      'click .toggle': 'toggle',
      'click .archive': 'archive'
    },
    initialize: function(options) {
      options || (options = {});
      _.extend(this, options);
      this.model.view = this;
      this.model.bind('change', _.bind(this.render, this));
      this.model.bind('destroy', _.bind(this.remove, this));
      return this.model.bind('change:archived', _.bind(this.onArchive, this));
    },
    render: function() {
      var json;
      json = this.model.toJSON();
      json.status = this.model.get('closed') ? 'completed' : 'open';
      dust.render('task', json, __bind(function(err, out) {
        var newel;
        newel = $(out);
        $(this.el).html(newel.html());
        return $(this.el).attr({
          "class": newel.attr('class'),
          tabindex: newel.attr('tabindex')
        });
      }, this));
      return this;
    },
    toggle: function(event) {
      var params;
      console.log(_.clone(this.model.attributes));
      params = {};
      if (this.model.get('closed')) {
        params.opening = true;
      } else {
        params.closing = true;
      }
      return this.model.save(params, {
        success: __bind(function() {
          return this.model.unset('closing');
        }, this)
      });
    },
    archive: function(event) {
      this.model.archive();
      return this;
    },
    /*
    	open: (event) ->
    		self = $(event.target)
    		self.attr 'contenteditable', true
    
    	close: (event) ->
    		self = $(event.target)
    		self.attr 'contenteditable', false
    		@model.save
    			name: (@$ '.name').text()
    	*/
    onArchive: function(model, archived) {
      if (archived) {
        this.hide();
      }
      return this;
    },
    hide: function() {
      return $(this.el).slideUp('slow');
    }
  });
  AppView = Backbone.View.extend({
    initialize: function(options) {
      options || (options = {
        el: $('#tasks')
      });
      _.extend(this, options);
      _.bindAll(this, 'addAll', 'addOne');
      Tasks.bind('add', this.addOne);
      Tasks.bind('reset', this.addAll);
      return this.creation = new Creation({
        app: this
      });
    },
    addOne: function(task) {
      var view;
      view = new TaskView({
        model: task
      });
      return $(this.el).append(view.render().el);
    },
    addAll: function(collection) {
      return collection.each(this.addOne);
    },
    create: function(name, assignedTo, priority) {
      if (priority == null) {
        priority = 1;
      }
      console.log(arguments);
      return Tasks.create({
        name: name,
        priority: priority,
        assignedTo: [assignedTo]
      });
    }
  });
  Creation = Backbone.View.extend({
    events: {
      'submit': 'submit'
    },
    defaults: function(dynamic) {
      return {
        el: $('#creation'),
        $name: $('#name'),
        $assign: $('#assign')
      };
    },
    initialize: function(options) {
      options || (options = {});
      _.extend(this, this.defaults(), options);
      return this.delegateEvents();
    },
    empty: function(callback) {
      ($(this.el)).animate({
        opacity: 0
      }, 200, __bind(function() {
        callback();
        this.$name.val('');
        return this.$assign.marcoPolo('change', '');
      }, this)).animate({
        opacity: 1
      }, 200);
      return this;
    },
    submit: function(event) {
      event.preventDefault();
      this.empty(__bind(function() {
        return this.app.create(this.getName(), this.getAssignedTo());
      }, this));
      return false;
    },
    getAssignedTo: function() {
      return this.$assign.data('user');
    },
    getName: function() {
      return this.$name.val();
    }
  });
  $(function() {
    var App;
    return App = root.App = new AppView;
  });
  Tasks.fetch();
  _.extend(root, {
    Tasks: Tasks,
    Task: Task
  });
}).call(this);
