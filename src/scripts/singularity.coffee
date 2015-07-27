# Description:
#   Script to interact with Singularity
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot singularity show aliases
#   hubot singularity add alias <alias> <url>
#   hubot singularity clear alias <alias>
#   hubot singularity show requests in <alias>
#   hubot singularity bounce <request> in <alias>
#
# Author:
#   Arca Artem - <aartem@opentable.com>

_singularityAliases = {}

module.exports = (robot) ->

  showAliases = (msg) ->
    if _singularityAliases == null || Object.keys(_singularityAliases).length == 0
      msg.send("I cannot find any singularity aliases")
    else
      for alias of _singularityAliases
        msg.send("I found '#{alias}' as an alias for singularity here at: #{_singularityAliases[alias]['url']}")

  clearAlias = (msg, alias) ->
    delete _singularityAliases[alias]
    robot.brain.data.singularity_aliases = _singularityAliases
    msg.send("The singularity alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _singularityAliases[alias] = { url: url }
    robot.brain.data.singularity_aliases = _singularityAliases
    msg.send("The singularity alias #{alias} for #{url} has been added")

  showRequests = (msg, alias) ->
    if not _singularityAliases[alias]?
      msg.send "I don't know that singularity alias"
      return

    url = _singularityAliases[alias].url + '/api/requests'
    robot.http(url)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if (err)
          msg.send "There was an error while making the request:"
          msg.send err
          return

        data = null
        try
          requests = JSON.parse body
          for request in requests
            msg.send "I found request '#{request.request.id} (#{request.request.requestType} - #{request.state})' for '#{alias}'"
        catch error
          msg.send "Ran into an error parsing JSON :"
          msg.send error

  showCommands = (msg) ->
    msg.send "Singularity commands:"
    msg.send "hubot singularity show aliases"
    msg.send "hubot singularity add alias <alias> <url>"
    msg.send "hubot singularity clear alias <alias>"
    msg.send "hubot singularity show requests in <alias>"
    msg.send "hubot singularity bounce <request> in <alias>"

  bounceRequest = (msg, alias, request) ->
    if not _singularityAliases[alias]?
      msg.send "I don't know that singularity alias"
      return

    url = _singularityAliases[alias].url + '/api/requests/request/' + request + '/bounce'

    robot.http(url)
      .post() (err, res, body) ->
        if (err)
          msg.send "There was an error while making the request:"
          msg.send err
          return
        msg.send "Bouncing '#{request}' on '#{alias}'"

  robot.brain.on 'loaded', ->
    if robot.brain.data.singularity_aliases?
      _singularityAliases = robot.brain.data.singularity_aliases

  robot.respond /singularity show aliases/i, (msg) ->
    showAliases(msg)

  robot.respond /singularity add alias (.*) (.*)/i, (msg) ->
    setAlias msg, msg.match[1], msg.match[2]

  robot.respond /singularity clear alias (.*)/i, (msg) ->
    clearAlias msg, msg.match[1]

  robot.respond /singularity show requests on (.*)/i, (msg) ->
    showRequests msg, msg.match[1]

  robot.respond /singularity bounce (.*) on (.*)/i, (msg) ->
    bounceRequest msg, msg.match[2], msg.match[1]

  robot.respond /singularity\?/i, (msg) ->
    showCommands(msg)
