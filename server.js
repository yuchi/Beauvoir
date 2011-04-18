var http = require('http');

http.createServer(function (req, res) {

	res.send('Hallo, world. This is Pier Paolo speaking. Hi to all.');

}).listen(80);

