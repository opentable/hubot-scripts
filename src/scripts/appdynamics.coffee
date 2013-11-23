# Description:
#   Display current app performance stats from AppDynamics
#
# Configuration:
#   HUBOT_APPDYNAMICS_ACCOUNTID
#   HUBOT_APPDYNAMICS_USER
#   HUBOT_APPDYNAMICS_PASSWORD
#   HUBOT_APPDYNAMICS_CONTROLLER
#
# Commands:
#   hubot appd applications - Returns the application listing from appdynamics
#   hubot appd response time [service] - Returns the last recorded response time (ms) for the service
#   hubot appd calls [service] - Returns the calls made to the service in the past minute
#   hubot appd errors [service] - Returns the errors returned from the service in the past minute
#   hubot appd exceptions [service] - Returns the exceptions returned from the service in the past minute
#   hubot appd httperrors [service] - Returns the errors returned from the service in the past minute
#   hubot appd slowcalls [service] - Returns the slow calls returned from the service in the past minute
#   hubot appd veryslowcalls [service] - Returns the very slow calls returned from the service in the past minute
#
# Author:
#   pstack

module.exports = (robot) ->

  user = process.env.HUBOT_APPDYNAMICS_USER
  password = process.env.HUBOT_APPDYNAMICS_PASSWORD
  account = process.env.HUBOT_APPDYNAMICS_ACCOUNTID
  auth = 'Basic ' + new Buffer("#{user}@#{account}:#{password}").toString('base64');
  url = "#{process.env.HUBOT_APPDYNAMICS_CONTROLLER}/rest/applications?output=JSON"

  applications = (msg) ->
    msg.http(url)
      .headers
        'Authorization': auth
      .get() (err, res, body) ->
        msg.send(body)

  robot.respond /appd applications/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    applications msg, (text) ->
      msg.send(text)

  robot.respond /appd response time (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd calls (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd errors (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd exceptions (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd httperrors (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd slowcalls (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

  robot.respond /appd veryslowcalls (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

