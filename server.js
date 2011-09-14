var http = require('http');

http.createServer(function (req, res) {

	res.write('Hallo, world. This is Pier Paolo speaking. Hi to all.');
	res.end();

}).listen(80);

