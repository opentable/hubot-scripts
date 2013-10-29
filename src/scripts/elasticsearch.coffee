# Description:
#   Get ElasticSearch Cluster Information
#
# Dependencies:
#   None
#
# Commands:
#   hubot: elasticsearch cluster health [server] - Gets the cluster information for the given server
#   hubot: elasticsearch query [server] [query details] - Runs a specific query against an ElasticSearch cluster
#
# Notes:
#   The server must be a fqdn to get to the elasticsearch cluster
#
# Author:
#  Paul Stack


module.exports = (robot) ->

  robot.respond /elasticsearch cluster health (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    server = msg.match[1]
    status = "OK"
    msg.send("#{server} reports Status: #{status}")
