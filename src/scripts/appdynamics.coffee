# Description:
#   Display current app performance stats from AppDynamics
#
# Configuration:
#   HUBOT_APPDYNAMICS_ACCOUNTID
#   HUBOT_APPDYNAMICS_USER
#   HUBOT_APPDYNAMICS_PASSWORD
#
# Commands:
#   hubot appdynamics [server] applications - Returns the application listing from appdynamics
#   hubot appdynamics [server] [application] response time - Returns the response times for the application over the past 60 minutes
#   hubot appdynamics [server] [application] requests per miniute - Returns the response times for the application over the past 60 minutes
#
# Author:
#   pstack

module.exports = (robot) ->

  response = (msg, controller, application) ->
    user = process.env.HUBOT_APPDYNAMICS_USER
    password = process.env.HUBOT_APPDYNAMICS_PASSWORD
    account = process.env.HUBOT_APPDYNAMICS_ACCOUNTID
    url = "#{user}@#{account}:#{password} '#{controller}/rest/applications?output=JSON'"
    msg.http(url)
      .get() (err, res, body) ->
        json = JSON.parse(body)
        msg.send(json)
    #    msg.send "#{json.metricPath}\nCurrent: #{json.metricValues.current}\nMax: #{json.metricValues.max}\nMin: #{json.metricValues.min}"

  applications = (msg, controller) ->
    user = process.env.HUBOT_APPDYNAMICS_USER
    password = process.env.HUBOT_APPDYNAMICS_PASSWORD
    account = process.env.HUBOT_APPDYNAMICS_ACCOUNTID
    url = "#{user}@#{account}:#{password} '#{controller}/rest/applications?output=JSON'"
    msg.http(url)
      .get() (err, res, body) ->
        json = JSON.parse(body)
        msg.send(json)
  #    msg.send "#{json.metricPath}\nCurrent: #{json.metricValues.current}\nMax: #{json.metricValues.max}\nMin: #{json.metricValues.min}"


  robot.respond /appdynamics (.*) applications/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    applications msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /appdynamics (.*) (.*) response time/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    response msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /appdynamics (.*) (.*) requests per minute/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    requests msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)