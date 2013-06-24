# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# For private use only.

async = require 'async'
Mailer = require '../../lib/mailer'

exports.setup = (callback) ->

	@on 'connect.callback', (data) =>
		@db.timelines.addUse target:'co:' + data.status, (->)

	@on 'connect.auth', (data) =>
		@db.timelines.addUse target:'co', (->)

	@server.post @config.base + '/api/adm/users/:id/invite', @auth.adm, (req, res, next) =>
		# send mail with u:{{iduser}}:key
		# https://oauth.io/#/validate/:iduser/:key
		iduser = req.params.id
		prefix = 'u:' + iduser + ':'
		@db.redis.mget [
			prefix+'mail',
			prefix+'key',
			prefix+'validated'
		], (err, replies) ->
			return next err if err
			if replies[2] != '0'
				return next new check.Error "not validable"
			options = 
				to:
					email: replies[0]
				from:
					name: 'OAuth.io'
					email: 'team@oauth.io'
				subject: ''
				body: 'Hello,\n\n
You are in the first wave of invitation and you can now connect you on OAuth.io!\n
You just have to click on this link http://oauth.io/validate/' + iduser + '/' + replies[1] + ' to validate your email and start playing with OAuth.\n
As we are in beta, your feedbacks are the most important thing we need to keep moving!\n\n
Thanks a lot for signed up to OAuth.io!\n\n
--\n
OAuth.io Team'

			data =
				body: options.body.replace(/\n/g, "<br />")
				id: iduser
				key: replies[1]
			mailer = new Mailer options, data
			mailer.send (err, result) ->
				return next err if err
				res.send result
				next()

	# get users list
	@server.get @config.base + '/api/adm/users', @auth.adm, (req, res, next) =>
		@db.redis.hgetall 'u:mails', (err, users) =>
			return next err if err
			cmds = []
			for mail,iduser of users
				cmds.push ['get', 'u:' + iduser + ':date_inscr']
				cmds.push ['smembers', 'u:' + iduser + ':apps']
				cmds.push ['get', 'u:' + iduser + ':key']
				cmds.push ['get', 'u:' + iduser + ':validated']
			@db.redis.multi(cmds).exec (err, r) =>
				return next err if err
				i = 0
				for mail,iduser of users										
					users[mail] = email:mail, id:iduser, date_inscr:r[i*4], apps:r[i*4+1], key:r[i*4+2], validated:r[i*4+3]
					i++
				res.send users
				next()

	# get app info with ID
	@server.get @config.base + 'api/adm/app/:id', @auth.adm, (req, res, next) =>
		id_app = req.params.id
		prefix = 'a:' + id_app + ':'
		cmds = []
		cmds.push ['mget', prefix + 'name', prefix + 'key']
		cmds.push ['smembers', prefix + 'domains']		
		cmds.push ['keys', prefix + 'k:*']
	
		@db.redis.multi(cmds).exec (err, results) ->
			return next err if err
			app = id:id_app, name:results[0][0], key:results[0][1], domains:results[1], providers:( result.substr(prefix.length + 2) for result in results[2] )
			res.send app
			next()

	# delete a user
	@server.del @config.base + 'api/adm/users/:id', @auth.adm, (req, res, next) =>
		@db.users.remove req.params.id, @server.send(res, next)

	# get any statistics
	@server.get new RegExp(@config.base + 'api/adm/stats/(.+)'), @auth.adm, (req, res, next) =>
		async.parallel [
			(cb) => @db.timelines.getTimeline req.params[0], req.query, cb
			(cb) => @db.timelines.getTotal req.params[0], cb
		], (e, r) ->
			return next e if e
			res.send total:r[1], timeline:r[0]
			next()

	callback()