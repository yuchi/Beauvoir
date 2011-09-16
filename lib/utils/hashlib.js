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
		hashlib = {
			sha512: require('./sha512').sha512,
			md5:    require('./md5').md5
		};
	}

	module.exports = hashlib;

})()