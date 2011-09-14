(function() {
  /*
  # Setting up templates
  */
  var AppView, Task, TaskList, TaskView, Tasks, root;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  $(function() {
    var tmpl;
    tmpl = $('#single-task-view').html();
    return dust.loadSource(dust.compile(tmpl, 'task'));
  });
  /*
  # Client side models
  */
  root = this;
  Task = Backbone.Model.extend({
    defaults: function() {
      return {
        name: '',
        priority: 1,
        status: 'open',
        archived: false
      };
    },
    reverse: {
      'open': 'completed',
      'completed': 'open'
    },
    initialize: function(attributes) {
      var excls, match;
      if (attributes == null) {
        attributes = {};
      }
      if (!(attributes.priority != null) || attributes.priority === 1) {
        attributes.name || (attributes.name = '');
        match = attributes.name.match(/(!+)\s*$/i);
        if (match && match[1]) {
          excls = match[1].length;
          this.set({
            priority: excls > 1 ? 3 : 2
          });
        }
      }
      return this;
    },
    toggle: function(options) {
      var newstatus;
      newstatus = this.reverse[this.get('status')];
      this.save({
        status: newstatus
      }, options);
      return this;
    },
    archive: function(options) {
      this.save({
        archived: true
      }, options);
      return this;
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
      'click .archive': 'archive',
      'dblclick .name': 'open',
      'blur .name': 'close'
    },
    initialize: function(options) {
      options || (options = {});
      _.extend(this, options);
      this.model.view = this;
      this.model.bind('change:status', _.bind(this.render, this));
      this.model.bind('destroy', _.bind(this.remove, this));
      return this.model.bind('change:archived', _.bind(this.onArchive, this));
    },
    render: function() {
      dust.render('task', this.model.toJSON(), __bind(function(err, out) {
        var newel;
        newel = $(out);
        $(this.el).html(newel.html());
        return $(this.el).attr('class', newel.attr('class'));
      }, this));
      return this;
    },
    toggle: function(event) {
      this.model.toggle();
      return this;
    },
    archive: function(event) {
      this.model.archive();
      return this;
    },
    open: function(event) {
      var self;
      self = $(event.target);
      return self.attr('contenteditable', true);
    },
    close: function(event) {
      var self;
      self = $(event.target);
      self.attr('contenteditable', false);
      return this.model.save({
        name: (this.$('.name')).text()
      });
    },
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
      return Tasks.bind('reset', this.addAll);
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
    create: function(name, priority) {
      if (priority == null) {
        priority = 1;
      }
      return Tasks.create({
        name: name,
        priority: priority
      });
    }
  });
  /*
  # Building things up
  */
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
