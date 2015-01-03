'use strict'
$ ->
	window.db = openDatabase('coin', '1.0', 'Coin DB', 2 * 1024 * 1024)
	window.db.transaction (tx)->
		tx.executeSql('CREATE TABLE IF NOT EXISTS birthdays (name, birthday)')
		tx.executeSql('CREATE TABLE IF NOT EXISTS names (name)')

	$(window).on 'load hashchange', (event) ->
		if location.hash == '#birthday'
			$('div#birthday input#datepicker').date("setDate", "1/1/1993")
			window.db.transaction (tx)->
				tx.executeSql 'SELECT name, birthday FROM birthdays', [], (tx, result)->
					window.myBirthdayHit = result.rows.length
					$('div#birthday p.textProgress').html("我记得<b>#{window.myBirthdayHit}</b>人 / 全班记得<b>#{window.allBirthdayHit}</b>人 / 共<b>39</b>人")
					for i in [0...result.rows.length]
						row = result.rows.item(i)
						$('div#birthday li.title').after("<li class='ui-li-static ui-body-inherit'>#{row.name} - #{row.birthday}</li>")
				, null

		if location.hash == '#name'
			window.db.transaction (tx)->
				tx.executeSql 'SELECT name FROM names', [], (tx, result)->
					window.myNameHit = result.rows.length
					$('div#name p.textProgress').html("我认识<b>#{window.myNameHit}</b>人 / 全班记得<b>#{window.allNameHit}</b>人 / 共<b>5753</b>人")
					for i in [0...result.rows.length]
						row = result.rows.item(i)
						$('div#name li.title').after("<li class='ui-li-static ui-body-inherit'>#{row.name}</li>")
				, null

	socket = io()
	socket.on 'resRegister', (msg)->
		$.mobile.loading('hide')
		if Number(msg) > 0
			location.hash = '#list'
		else
			alert('The name has been used.')
			localStorage.removeItem('nickname')

	socket.on 'resBirthday', (msg)->
		if(typeof(msg) == 'string')
			if msg == 'nobody'
				alert('没有人在这天生日呢')
			else
				alert('他已经被别人抢走了')
		else
			window.myBirthdayHit++
			$('div#birthday p.textProgress').html("我记得<b>#{window.myBirthdayHit}</b>人 / 全班记得<b>#{window.allBirthdayHit}</b>人 / 共<b>39</b>人")
			$('div#birthday li.title').after("<li class='ui-li-static ui-body-inherit'>#{msg.name} - #{msg.birthday}</li>")
			window.db.transaction (tx)->
				tx.executeSql('INSERT INTO birthdays (name, birthday) VALUES (?, ?)', [msg.name, msg.birthday])

	socket.on 'resName', (msg)->
		if(typeof(msg) == 'string')
			if msg == 'nobody'
				alert('没有这个人呢')
			else
				alert('他已经被别人抢走了')
		else
			window.myNameHit++;
			$('div#name p.textProgress').html("我认识<b>#{window.myNameHit}</b>人 / 全班记得<b>#{window.allNameHit}</b>人 / 共<b>5753</b>人")
			$('div#name li.title').after("<li class='ui-li-static ui-body-inherit'>#{msg[0]}</li>")
			window.db.transaction (tx)->
				tx.executeSql('INSERT INTO names (name) VALUES (?)', [msg[0]])

	socket.on 'regBirthday', (msg)->
		$('div#birthday progress').attr('value', msg)
		window.allBirthdayHit = msg 
		$('div#birthday p.textProgress').html("我记得<b>#{window.myBirthdayHit}</b>人 / 全班记得<b>#{window.allBirthdayHit}</b>人 / 共<b>39</b>人")

	socket.on 'regName', (msg)->
		$('div#name progress').attr('value', msg)
		window.allNameHit = msg
		$('div#name p.textProgress').html("我认识<b>#{window.myNameHit}</b>人 / 全班认识<b>#{window.allNameHit}</b>人 / 共<b>5753</b>人")

	$('div#registerButton').click ->
		nickname = $('#register #nickname').val()
		if nickname.length
			$.mobile.loading 'show',
				text: 'Registering',
				textVisible: true,
				textonly: false
			socket.emit('reqRegister', nickname)
			localStorage.setItem('nickname', nickname)
		else
			alert('Who are you?')

	$('div#birthday div.submit').click ->
		[month, day, year] = $('input#datepicker').val().split('/')
		dateString = "#{year}/#{month}/#{day}"
		socket.emit('reqBirthday', [dateString, localStorage.getItem('nickname')])

	$('div#name div.submit').click ->
		socket.emit('reqName', [$('input#name').val(), localStorage.getItem('nickname')])