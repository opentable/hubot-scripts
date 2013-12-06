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
#   hubot foreman hosts        - gets a list of hosts from foreman
#   hubot foreman environments - gets a lot of environments from foreman
#   hubot foreman users        - gets a list of users from foreman
#   hubot foreman facts        - gets a list of facts from foreman
#   hubot foreman [HOST] facts - gets a list of hosts for a specific host
#
# Author:
#   pstack

module.exports = (robot) ->

  password = "0pentab1e"
  url = "https://tyson"
  user = "hubot"
  auth = 'Basic ' + new Buffer("#{user}:#{password}").toString('base64')

  query = (msg, path) ->
    msg.http("#{url}/#{path}?format=json")
      .headers
        'Authorization': auth
      .request({rejectUnauthorized: false}) (err, res, body) ->
        msg.send(body)

  host = (msg, host) ->
    msg.http("#{url}/#{host}/facts?format=json")
    .headers
        'Authorization': auth
    .request({rejectUnauthorized: false}) (err, res, body) ->
      msg.send(body)

  robot.respond /foreman (hosts|environments|users|facts})/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    query msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /foreman (.*) facts/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    host msg, msg.match[1], (text) ->
      msg.send(text)