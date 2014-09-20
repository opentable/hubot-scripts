# Description:
#   Get ElasticSearch Cluster Information
#
# Commands:
#   hubot: elasticsearch cluster [server] - Gets the cluster information for the given server or alias
#   hubot: elasticsearch cat nodes [server] - Gets the information from the cat nodes endpoint for the given server or alias
#   hubot: elasticsearch cat indexes [server] - Gets the information from the cat indexes endpoint for the given server or alias
#   hubot: elasticsearch show aliases - shows the aliases for the list of ElasticSearch instances
#   hubot: elasticsearch add alias [alias name] [url] - sets the alias for a given url
#   hubot: elasticsearch clear alias [alias name] - please note that this needs to include any port numbers as appropriate
#
# Notes:
#   The server must be a fqdn (with the port!) to get to the elasticsearch cluster
#
# Author:
#  Paul Stack

_esAliases = {}

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    if robot.brain.data.elasticsearch_aliases?
      _esAliases = robot.brain.data.elasticsearch_aliases

  cluster_health = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("No ES Cluster found for #{alias}")
    else
      msg.http("#{cluster_url}/_cluster/health")
        .get() (err, res, body) ->
          json = JSON.parse(body)
          cluster_name = json['cluster']
          status = json['status']
          number_of_nodes = json['number_of_nodes']
          msg.send "Cluster: #{cluster_url} \nStatus: #{status} \n Nodes: #{number_of_nodes}"

  cat_nodes = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("No ES Cluster found for #{alias}")
    else
      msg.send("Getting the cat stats for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/nodes?h=host,heapPercent,load,segmentsMemory,fielddataMemory,filterCacheMemory,idCacheMemory,percolateMemory,u,heapMax,nodeRole,master")
        .get() (err, res, body) ->
          lines  = body.split("\n")
          header = lines.shift()
          list   = [header].concat(lines.sort().reverse()).join("\n")
          msg.send("/code #{list}")

  cat_indexes = (msg, alias) ->
    cluster_url = _esAliases[alias]

    if cluster_url == "" || cluster_url == undefined
      msg.send("No ES Cluster found for #{alias}")
    else
      msg.send("Getting the cat indices for the cluster: #{cluster_url}")
      msg.http("#{cluster_url}/_cat/indices/logstash-*?h=idx,sm,fm,fcm,im,pm,ss,sc,dc&v")
        .get() (err, res, body) ->
          lines  = body.split("\n")
          header = lines.shift()
          list   = [header].concat(lines.sort().reverse()).join("\n")
          msg.send("/code #{list}")

  robot.hear /elasticsearch cat nodes (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    cat_nodes msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cat indexes (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    cat_indexes msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch cluster (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    cluster_health msg, msg.match[1], (text) ->
      msg.send text

  robot.hear /elasticsearch show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.hear /elasticsearch add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.hear /elasticsearch clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)

  showAliases = (msg) ->

    if _esAliases == null
      msg.send("I cannot find any ElasticSearch Cluster aliases")
    else
      for alias of _esAliases
        msg.send("I found '#{alias}' as an alias for the cluster: #{_esAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _esAliases[alias]
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _esAliases[alias] = url
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The cluster alias #{alias} for #{url} has been added to the brain")
