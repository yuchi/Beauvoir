/**
 * Toolbox v0.1
 *
 * a jQuery UI plugin which adds toolbar functionality.
 *
 * Copyright 2012 by Pier Paolo Ramon
 * Released under the MIT License
 * http://en.wikipedia.org/wiki/MIT_License
 */
;(function (factory) {
	// Register as an AMD module, compatible with script loaders like RequireJS.
	// Source: https://github.com/umdjs/umd/blob/master/jqueryPlugin.js
	if (typeof define === 'function' && define.amd) {
		define(['jquery'], factory);
	}
	else {
		factory(jQuery);
	}
}(function ($, undefined) {

	// jQuery UI's Widget Factory provides an object-oriented plugin framework
	// that handles the common plumbing tasks.
	$.widget( 'ui.toolbox', {
		
		options: {
			group: 'main',
			triggerSelector: '.ui-toolbox-trigger',
			panelSelector:   '.ui-toolbox-panel',
			actionsSelector: '.ui-toolbox-action'
		},

		_create: function () {
			var self = this,
				o = this.options;

			this.element.data( 'toolboxGroup', o.group );

			this.trigger = this.element.find( o.triggerSelector );
			this.panel = this.element.find( o.panelSelector );

			this.actions = this.panel.find( o.actionsSelector );
			this.actions.on( 'hover', this._onActionHover );

			this._onOutside = $.proxy( this._onOutside, this );
			this._onTrigger = $.proxy( this._onTrigger, this );
			this._onPanelNav = $.proxy( this._onPanelNav, this );
			//this._onFocusOut = $.proxy( this._onFocusOut, this );

			$( document ).on( 'mousedown.' + this.widgetName, this._onOutside );

			this.trigger.on( 'mousedown.' + this.widgetName, this._onTrigger );
			this.trigger.on( 'keydown.' + this.widgetName, this._onTrigger );
			//this.element.on( 'focusout.' + this.widgetName, this._onFocusOut )

			this.panel.on( 'keydown.' + this.widgetName, o.actionsSelector, this._onPanelNav );
			this.panel.on( 'hover.' + this.widgetName, o.actionsSelector, this._onPanelNav );
			this.panel.on( 'mouseup.' + this.widgetName, o.actionsSelector, this._onPanelNav );

		},

		_destroy: function () {

			this.element.off( '.' + this.widgetName );
			this.trigger.off( '.' + this.widgetName );
			this.panel.off( '.' + this.widgetName );

		},

		_onOutside: function ( event ) {
			if ( !this.isActive() ) return;
			if ( this.element.is( event.target ) ) return;
			if ( $.contains( this.element[0], event.target ) ) return;
			if ( $( event.target ).closest( ':data(toolbox)' ).length ) return;

			this.close();
		},

		/*
		_onFocusOut: function ( event ) {

			var self = this,
				rejected = false;

			this.panel.off( 'focusin.toolboxOnce');
			this.panel.one( 'focusin.toolboxOnce', function () {
				rejected = true;
			});

			setTimeout(function(){
				if (!rejected) self.close();
			},100)

		},
		*/

		_onPanelNav: function ( event ) {

			var top, direction, href,
				self = $( event.target ).closest( this.options.actionsSelector ),
				key = event.which,
				keys = $.ui.keyCode;

			if ( event.type === 'keydown' ) {

				if ( key !== keys.UP && key !== keys.DOWN ) {
					return;
				}


				event.preventDefault();

				direction = key == keys.DOWN ? 'next' : 'prev';
				to = self[ direction ]();

				if ( !to.length ) {
					to = self.parent()[ direction ]().find( this.options.actionsSelector );
					to = to.eq( direction === 'next' ? 0 : -1 );
				}

				if ( direction === 'prev' && !to.length ) {
					this.close();
					this.focusTrigger();
					return;
				}

				to.focus()

			} else if ( event.type === 'mouseenter' ) {
				self.addClass('hover');
			} else if ( event.type === 'mouseleave' ) {
				self.removeClass('hover');
			} else if ( event.type === 'mouseup' ) {
				href = self.attr('href');
				if ( href ) {
					self.one('click', function () {
						window.location.href = href;
					});
				}
				self.click();
			}

		},

		_onTrigger: function ( event ) {

			var key = event.which,
				keys = $.ui.keyCode;

			if ( key === keys.TAB ) {

				if ( this[ event.shiftKey ? 'focusPrevious' : 'focusNext' ]() ) {
					event.preventDefault();
				}

				return;
			}

			if ( event.type === 'keydown' && 0 > $.inArray( event.which, [ 13, 37, 38, 39, 40 ] ) ) {
				return;
			}

			event.preventDefault();

			if ( !this.isActive() && event.type === 'mousedown' ) {
				this.trigger.focus();
			}

			if ( this.isActive() && event.which === keys.DOWN ) {
				this.focusElementOnPanel( 0 );
				return;
			}

			if ( !this.isActive() && event.which === keys.UP ) {
				this.focusElementOnPanel( -1 );
				return;
			}

			if ( event.which === keys.LEFT ) {
				this.focusPrevious();
				return;
			}

			if ( event.which === keys.RIGHT ) {
				this.focusNext();
				return;
			}

			this.toggle();

		},

		toggle: function ( status ) {
			if ( status == undefined ) {
				status = !this.isActive();
			}

			this[ status ? 'open' : 'close' ]();
		},

		open: function () {

			var self = this,
				o = this.options;

			// Too slow!
			$(':data(toolbox)').filter(function(){
				return $(this).data('toolboxGroup') == o.group;
			}).toolbox( 'close' );

			this.active = true;

			this.element.addClass( 'ui-toolbox-opened opened' );
			this.panel.addClass( 'ui-toolbox-panel-opened opened' );
		},

		close: function () {
			this.active = false;
 
			this.element.removeClass( 'ui-toolbox-opened opened' );
			this.panel.removeClass( 'ui-toolbox-panel-opened opened' );
		},

		isActive: function () {
			return this.active;
		},

		focusElementOnPanel: function ( index ) {
			this.panel.find( this.options.actionsSelector ).eq( index ).focus();
		},

		focusTrigger: function () {
			this.trigger.focus();
		},

		focusPrevious: function () {
			var active = this.isActive(),
				prev = this.previousToolbox();

			prev.toolbox( 'focusTrigger' );
			if (active) {
				prev.toolbox( 'open' );
				this.close();
			}

			return prev.length;
		},

		focusNext: function () {
			var active = this.isActive(),
				next = this.nextToolbox();

			next.toolbox( 'focusTrigger' );
			if (active) {
				next.toolbox( 'open' );
				this.close();
			}

			return next.length;
		},

		previousToolbox: function () {		
			return this.element.prev( ':data(toolbox)');
		},

		nextToolbox: function () {		
			return this.element.next( ':data(toolbox)');
		}

	});

}));