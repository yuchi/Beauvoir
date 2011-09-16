(function(){

	/**
	 * SOME ENVIRONMENTS DO NO LIKE CPP MODULES.
	 * HASHLIB IS NOT ALWAYS COMPATIBLE.
	 * THIS PROVIDES AN ALTERNATIVE.
	 **/
	
	var hashlib;
	try {
		hashlib = require('hashlib');
	} catch (e) {
		hashlib = require('./sha512');
	}

	module.exports = hashlib;

})()