# Description:
#   Interact with Nagios from Hubot. Currently the script allows it to acknowledge issues, schedule downtime
#   as well as turn notifications on / off.
#
#  URLS:
#  http://192.168.201.90:8080/nagios/state
#  http://dcnagios:8080/nagios/state
#
# Commands:
#   hubot nagios ack [host] [service] [server]
#   hubot nagios unack [host] [service] [server]
#   hubot nagios notifications [on|off] [name] [hostgroup|servicegroup|host)
#   hubot nagios downtime [host] [time (in minutes)] [server]
#   hubot nagios cancel downtime [host] [server]
#   hubot nagios check [host] [service] [server]
#   hubot nagios show aliases - shows the aliases for the list of Nagios instances
#   hubot nagios add alias [alias name] [url] - sets the alias for a given url
#   hubot nagios clear alias [alias name] - please note that this needs to include any port numbers as appropriate
#
# Author:
#   pstack

_nagiosAliases = {}

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    if robot.brain.data.nagios_aliases?
      _nagiosAliases = robot.brain.data.nagios_aliases

  showAliases = (msg) ->
    if _nagiosAliases?
      msg.send("I cannot find any Nagios aliases")
    else
      for alias of _nagiosAliases
        msg.send("I found '#{alias}' as an alias for #{_nagiosAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _nagiosAliases[alias]
    robot.brain.data.nagios_aliases = _nagiosAliases
    msg.send("The alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _nagiosAliases[alias] = url
    robot.brain.data.nagios_aliases = _nagiosAliases
    msg.send("The alias #{alias} for #{url} has been added to the brain")

  disable = (msg, name, type) ->
    msg.send("")

  acknowledge = (msg, host, service, server) ->
    msg.send("")

  downtime = (msg, host, time) ->
    msg.send("")

  robot.respond /nagios ack (.*) (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    #acknowledge msg, msg.match[1], msg.match[2], msg.match[3] (text) ->
    msg.send("In Progress")

  robot.respond /nagios notifications (.*) (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    #disable msg, msg.match[1], msg.match[2] (text) ->
    msg.send("In Progress")

  robot.respond /nagios downtime (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    #downtime msg, msg.match[1], msg.match[2] (text) ->
    msg.send("In Progress")

  robot.respond /nagios show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.respond /nagios add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /nagios clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)
