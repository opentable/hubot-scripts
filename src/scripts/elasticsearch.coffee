# Description:
#   Get ElasticSearch Cluster Information
#
# Commands:
#   hubot: elasticsearch cluster [server] - Gets the cluster information for the given server
#   hubot: elasticsearch node [server] - Gets the node information for the given server
#   hubot: elasticsearch query [server] [query] - Runs a specific query against an ElasticSearch cluster
#   hubot: elasticsearch|es show aliases - shows the aliases for the list of ElasticSearch instances
#   hubot: elasticsearch|es add alias [alias name] [url] - sets the alias for a given url
#   hubot: elasticsearch|es clear alias [alias name] - please note that this needs to include any port numbers as appropriate
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

  search = (msg, server, query) ->
    msg.http("http://#{server}/_search?#{query}")
      .get() (err, res, body) ->
        json = JSON.parse(body)
        firsthit = JSON.stringify(json.hits.hits[0])
        msg.send("There are #{json.hits.total} results for the search http://#{server}/_search?#{query} \nThe first result is \n#{firsthit}")

  cluster_health = (msg, server) ->
    msg.http("http://#{server}/_cluster/health")
      .get() (err, res, body) ->
        json = JSON.parse(body)
        cluster_name = json['cluster']
        status = json['status']
        number_of_nodes = json['number_of_nodes']
        msg.send "Cluster: #{cluster_name} \nStatus: #{status} \n Nodes: #{number_of_nodes}"

  node_health = (msg, server) ->
    msg.http("http://#{server}/")
      .get() (err, res, body) ->
        json = JSON.parse(body)
        name = json['name']
        status = json['status']
        msg.send "Server: #{name} \nStatus: #{status}"

  robot.respond /elasticsearch query (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    search msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)


  robot.respond /elasticsearch node (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    node_health msg, msg.match[1], (text) ->
      msg.send text

  robot.respond /elasticsearch cluster (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    cluster_health msg, msg.match[1], (text) ->
      msg.send text

  robot.respond /(elasticsearch|es) show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.respond /(elasticsearch|es) add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /(elasticsearch|es) clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)

  showAliases = (msg) ->
    if _esAliases?
      msg.send("I cannot find any ElasticSearch Cluster aliases")
    else
      for alias of _esAliases
        msg.send("I found '#{alias}' as an alias for #{_esAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _esAliases[alias]
    robot.brain.data._esAliases = _esAliases
    msg.send("The alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _esAliases[alias] = url
    robot.brain.data.elasticsearch_aliases = _esAliases
    msg.send("The alias #{alias} for #{url} has been added to the brain")
