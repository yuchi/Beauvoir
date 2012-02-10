
var _ = require( 'underscore' ),
	models = require( '../models' );

module.exports.fastest = function () {
	
	var i, close, current,
		calls = _.initial( arguments ),
		finalize = _.once( _.last( arguments ) ),
		l = calls.length;

	for (i = 0; i<l; ++i) {
		current = calls[ i ];
		current( finalize );
	}

};

module.exports.multiLoad = function ( ids, callback ) {
	var i, current,
		results = [],
		l = ids.length,
		finalize = _.after( l, function() {
			callback( null, results );
		});

	for ( i=0; i<l; ++i ) {
		current = ids[ i ];
		current = current.id || current;
		models.User.load( current, function ( err, props ) {
			if ( !err ) {
				results.push( this );
			}
			finalize();
		});
	}
};

module.exports.cascade = function ( context ) {

	var current,
		last,
		calls = _.tail(arguments),
		counter = 0,
		next = function () {
			last = Array.prototype.slice.call(arguments);
			last.unshift( next );
			current = calls[ counter ];
			if (current) {
				++counter;
				current.apply( context, last );
			}
		};

		next();
};