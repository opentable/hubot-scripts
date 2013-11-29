# Description:
#   Script to interact with foreman
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_FOREMAN_URL
#   HUBOT_FOREMAN_USER
#   HUBOT_FOREMAN_PASSWORD
#
# Commands:
#   hubot foreman hosts - gets a list of hosts from foreman
#
# Author:
#   pstack

module.exports = (robot) ->

  user = process.env.HUBOT_FOREMAN_USER
  password = process.env.HUBOT_FOREMAN_PASSWORD
  url = process.env.HUBOT_FOREMAN_URL
  auth = 'Basic ' + new Buffer("#{user}#{password}").toString('base64');

  hosts = (msg, path) ->
    msg.send(path)
    msg.http("#{url}/#{path}?format=json")
      .headers
        'Authorization': auth
      .get({'strictSSL': false}) (err, res, body) ->
        msg.send(body)

  host = (msg, host) ->
    msg.send(path)
    msg.http("#{url}/#{host}/facts?format=json")
      .headers
        'Authorization': auth
      .get({'strictSSL': false}) (err, res, body) ->
        msg.send(body)

  robot.respond /foreman (hosts|environments|users|facts})/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    hosts msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /foreman (.*) facts/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    host msg, msg.match[1], (text) ->
      msg.send(text)