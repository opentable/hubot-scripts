# Description:
#   Script to interact with service-discovery
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot discovery show aliases
#   hubot discovery add alias <alias> <url>
#   hubot discovery clear alias <alias>
#   hubot discovery show announcements on <alias>
#   hubot discovery show announcements for <serviceType> on <alias>
#
# Author:
#   Maria Jankowiak - <mjankowiak@opentable.com>

_discoveryAliases = {}

module.exports = (robot) ->

  showAliases = (msg) ->
    if _discoveryAliases == null || Object.keys(_discoveryAliases).length == 0
      msg.send("I cannot find any discovery aliases")
    else
      for alias of _discoveryAliases
        msg.send("I found '#{alias}' as an alias for discovery here at: #{_discoveryAliases[alias]['url']}")

  clearAlias = (msg, alias) ->
    delete _discoveryAliases[alias]
    robot.brain.data.discovery_aliases = _discoveryAliases
    msg.send("The discovery alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _discoveryAliases[alias] = { url: url }
    robot.brain.data.discovery_aliases = _discoveryAliases
    msg.send("The discovery alias #{alias} for #{url} has been added")

  isAliasDefined = (msg, alias) ->
    if not _discoveryAliases[alias]?
      msg.send "I don't know that discovery alias"
      return false
    return true

  showAnnouncements = (msg, alias, serviceType) ->
    if not (isAliasDefined msg, alias)
      return

    serviceQueryParam = if serviceType then '?serviceType=' + serviceType else ''
    url = _discoveryAliases[alias].url + '/announcement' + serviceQueryParam
    robot.http(url)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if (err)
          msg.send "There was an error while making the request:"
          msg.send err
          return

        try
          announcements = JSON.parse body
          msg.send "I found #{announcements.results.length} announcements:"
          for announcement in announcements.results
            msg.send "Service type: '#{announcement.serviceType}', service URI: #{announcement.serviceUri}, announcement time: '#{announcement.announceTime}'"
        catch error
          msg.send "Ran into an error parsing JSON :"
          msg.send error

  showCommands = (msg) ->
    msg.send "hubot discovery show aliases"
    msg.send "hubot discovery add alias <alias> <url>"
    msg.send "hubot discovery clear alias <alias>"
    msg.send "hubot discovery show announcements on <alias>"
    msg.send "hubot discovery show announcements for <serviceType> on <alias>"

  robot.brain.on 'loaded', ->
    if robot.brain.data.discovery_aliases?
      _discoveryAliases = robot.brain.data.discovery_aliases

  robot.respond /discovery show aliases/i, (msg) ->
    showAliases(msg)

  robot.respond /discovery add alias (.*) (.*)/i, (msg) ->
    setAlias msg, msg.match[1], msg.match[2]

  robot.respond /discovery clear alias (.*)/i, (msg) ->
    clearAlias msg, msg.match[1]

  robot.respond /discovery show announcements for (.*) on (.*)/i, (msg) ->
    showAnnouncements msg, msg.match[2], msg.match[1]

  robot.respond /discovery show announcements on (.*)/i, (msg) ->
    showAnnouncements msg, msg.match[1]

  robot.respond /discovery\?/i, (msg) ->
    showCommands(msg)
