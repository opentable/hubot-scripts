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
#   hubot foreman build <role> <multiplier>
#   hubot foreman destroy <node>
#   hubot foreman set role <role> <spec>
#   hubot foreman list roles
#
# Author:
#   pstack

module.exports = (robot) ->

  password = ""
  url = ""
  user = ""
  auth = 'Basic ' + new Buffer("#{user}:#{password}").toString('base64')

  robot.respond /foreman build (.*)( .*)?/i, (msg) ->
    msg.send("This would build some boxes")

  robot.respond /foreman destroy (.*)/i, (msg) ->
    msg.send("This would destroy a box")

  robot.respond /foreman set role (.*) (.*)/i, (msg) ->
    msg.send("This will set up role specifics")

  robot.respond /foreman list roles/i, (msg) ->
    msg.send("This would list all the box types")
