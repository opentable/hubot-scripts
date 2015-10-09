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
#   hubot singularity show requests on <alias>
#   hubot singularity bounce <request> on <alias>
#   hubot singularity show active tasks for <request> on <alias>
#   hubot singularity kill task <taksId> on <alias>
#   hubot singularity show task updates for <taskId> on <alias>
#
# Author:
#   Arca Artem - <aartem@opentable.com>

util = require 'util'
singularityAliases = {}

module.exports = (robot) ->

  showAliases = (msg) ->
    if singularityAliases == null || Object.keys(singularityAliases).length == 0
      msg.send("I cannot find any singularity aliases")
    else
      for alias of singularityAliases
        msg.send("I found '#{alias}' as an alias for singularity here at: #{singularityAliases[alias]['url']}")

  clearAlias = (msg, alias) ->
    delete singularityAliases[alias]
    robot.brain.data.singularityaliases = singularityAliases
    msg.send("The singularity alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _singularityAliases[alias] = { url: url }
    robot.brain.data.singularity_aliases = _singularityAliases
    msg.send("The singularity alias #{alias} for #{url} has been added")

  isAliasDefined = (msg, alias) ->
    if not _singularityAliases[alias]?
      msg.send "I don't know that singularity alias"
      return false
    return true

  showRequests = (msg, alias) ->
    if not isAliasDefined msg, alias
      return

    singularityAliases[alias] = { url: url }
    robot.brain.data.singularityaliases = singularityAliases
    msg.send("The singularity alias #{alias} for #{url} has been added")

  getRequests = (alias, cb) ->
    url = singularityAliases[alias].url + '/api/requests'
    robot.http(url)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if (err)
          return cb(err)

        data = null
        try
          cb(null, JSON.parse(body))
        catch error
          cb(error)

  showRequests = (msg, alias) ->
    if not singularityAliases[alias]?
      msg.send "I don't know that singularity alias"
      return

    getRequests(alias, (err, requests) ->
      if (err)
        msg.send "There was an error calling Singularity API:"
        msg.send err
        return

      for request in requests
        msg.send "I found request '#{request.request.id} (#{request.request.requestType} - #{request.state})' for '#{alias}'"
    )

  validRequest = (alias, request, cb) ->
    getRequests(alias, (err, requests) ->
      if (err)
        cb(err)
        return

      for r in requests
        if r.request.id == request
          cb(null, true)
          return

      cb(null, false)
    )

  showCommands = (msg) ->
    msg.send "Singularity commands:"
    msg.send "hubot singularity show aliases"
    msg.send "hubot singularity add alias <alias> <url>"
    msg.send "hubot singularity clear alias <alias>"
    msg.send "hubot singularity show requests on <alias>"
    msg.send "hubot singularity bounce <request> on <alias>"
    msg.send "hubot singularity show active tasks for <request> on <alias>"
    msg.send "hubot singularity kill task <taksId> on <alias>"
    msg.send "hubot singularity show task updates for <taskId> on <alias>"

  showActiveTasks = (msg, request, alias) ->
    if not isAliasDefined msg, alias
      return

    url = _singularityAliases[alias].url + '/api/history/request/' + request + '/tasks/active'

    robot.http(url)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if err
          msg.send "There was an error while making the request:"
          msg.send error
          return

        try
          tasks = JSON.parse body
          msgEnd = if tasks.length != 1 then 's' else ''
          msg.send "I found #{tasks.length} active task#{msgEnd}:"
          for task in tasks
            taskUrl = _singularityAliases[alias].url + '/api/tasks/task/' + task.taskId.id
            robot.http(taskUrl)
              .get() (err, res, body) ->
                if (err)
                  msg.send "There was an error while making the request:"
                  msg.send error
                  return

                taskDetails = JSON.parse body
                host = taskDetails.offer.hostname
                portsResource = taskDetails.mesosTask.resources.filter (r) ->
                  r.name == 'ports'

                if (portsResource[0] and portsResource[0].ranges.range)
                  port = portsResource[0].ranges.range[0].begin;
                  msg.send "Task started on '#{host}:#{port}' at #{new Date(task.taskId.startedAt)} with id: '#{task.taskId.id}'"
                else
                  msg.send "Task started on '#{host}' at #{new Date(task.taskId.startedAt)} with id: '#{task.taskId.id}'"
        catch error
          msg.send "Ran into an error parsing JSON :"
          msg.send error

  killTask = (msg, taskId, alias) ->
    if not isAliasDefined msg, alias
      return

    url = _singularityAliases[alias].url + '/api/tasks/task/' + taskId

    robot.http(url)
      .del() (err, res, body) ->
        if err or res.statusCode == 404
          msg.send "There was an error while making the request:"
          msg.send err or body
          return
        msg.send "Killing '#{taskId}' on '#{alias}'"

  showTaskUpdates = (msg, taskId, alias) ->
    if not isAliasDefined msg, alias
      return

    url = _singularityAliases[alias].url + '/api/history/task/' + taskId

    robot.http(url)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        if err or res.statusCode == 404
          msg.send "There was an error while making the request:"
          msg.send error or body
          return

        try
          updates = JSON.parse body
          msg.send "Updates for task: '#{taskId}'"
          for update in updates.taskUpdates
            msg.send "Task state: '#{update.taskState}' started at #{new Date(update.timestamp)}; #{update.statusMessage || ''}"
        catch error
          msg.send "Ran into an error parsing JSON :"
          msg.send error

  bounceRequest = (msg, alias, request) ->
    if not isAliasDefined msg, alias
      return

    validRequest(alias, request, (err, isValid) ->
      if (err)
        msg.send "There was an error calling Singularity API:"
        msg.send err
        return

      if not isValid
        msg.send "I don't know request '#{request}' on '#{alias}'"
        return

      url = singularityAliases[alias].url + '/api/requests/request/' + request + '/bounce'

      robot.http(url)
        .post() (err, res, body) ->
          if (err)
            msg.send "There was an error while making the request:"
            msg.send err
            return

          msg.send "Bouncing '#{request}' on '#{alias}'"
    )

  robot.brain.on 'loaded', ->
    if robot.brain.data.singularityaliases?
      singularityAliases = robot.brain.data.singularityaliases

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

  robot.respond /singularity show active tasks for (.*) on (.*)/i, (msg) ->
    showActiveTasks msg, msg.match[1], msg.match[2]

  robot.respond /singularity kill task (.*) on (.*)/i, (msg) ->
    killTask msg, msg.match[1], msg.match[2]

  robot.respond /singularity show task updates for (.*) on (.*)/i, (msg) ->
    showTaskUpdates msg, msg.match[1], msg.match[2]

  robot.respond /singularity\?/i, (msg) ->
    showCommands(msg)
