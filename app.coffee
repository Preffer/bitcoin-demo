'use strict'
express = require('express')
app = express()
http = require('http').Server(app)
io = require('socket.io')(http)
mysql = require('mysql')

app.use(express.static(__dirname + '/wwwfiles'))
conn = mysql.createConnection
    host: 'localhost',
    user: 'coin',
    database:'coin',
    port: 3306
conn.connect()

io.on 'connection', (socket)->
	global.birthdayHit = 0 if not global.birthdayHit?
	global.nameHit = 0 if not global.nameHit?
	socket.emit('regBirthday', global.birthdayHit)
	socket.emit('regName', global.nameHit)

	socket.on 'reqRegister', (msg)->
		sql = 'INSERT INTO `nicknames`(`nickname`) VALUES (?)'
		inserts = [msg]
		sql = mysql.format(sql, inserts);
		conn.query sql, (err)->
			if err
				socket.emit('resRegister', -1)
			else
				socket.emit('resRegister', 1)

	socket.on 'reqBirthday', (msg)->
		sql = 'INSERT INTO `birthdays_hit`(`birthday`, `nickname`) VALUES (?, ?)'
		sql = mysql.format(sql, msg)
		conn.query sql, (err, rows)->
			console.log err
			if err
				if err.errno == 1062
					socket.emit('resBirthday', 'duplicate')
				else
					socket.emit('resBirthday', 'nobody')
			else
				io.emit('regBirthday', rows.insertId)
				global.birthdayHit = rows.insertId

				sql = 'SELECT `birthdays`.`name`, `birthdays`.`birthday` FROM `birthdays` JOIN birthdays_hit ON `birthdays_hit`.`birthday` = ? AND `birthdays`.`birthday` = `birthdays_hit`.`birthday`'
				sql = mysql.format(sql, msg[0])
				conn.query sql, (err, rows)->
					socket.emit('resBirthday', rows[0])
	
	socket.on 'reqName', (msg)->
		sql = 'INSERT INTO `names_hit`(`name`, `nickname`) VALUES (?, ?)'
		sql = mysql.format(sql, msg)
		conn.query sql, (err, rows)->
			if err
				if err.errno == 1062
					socket.emit('resName', 'duplicate')
				else
					socket.emit('resName', 'nobody')
			else
				io.emit('regName', rows.insertId)
				global.nameHit = rows.insertId
				socket.emit('resName', msg)		

http.listen 8004, ->
	console.log('Listening on *:8004')
