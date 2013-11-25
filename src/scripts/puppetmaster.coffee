# Description:
#   Display current puppetmaster node status
#
#
# Commands:
#   hubot puppetmaster status [alias] - gets the status of the puppetmaster for a specific alias
#   hubot puppetmaster show aliases - shows the aliases for the list of pupeptmasters
#   hubot puppetmaster add alias [alias name] [url] - sets the alias for a given url
#   hubot puppetmaster clear alias [alias name] - please note that this needs to include any port numbers as appropriate
#
# Author:
#   pstack

cheerio = require('cheerio')
_puppetmasterAliases = {}

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    if robot.brain.data.puppetmaster_aliases?
      _puppetmasterAliases = robot.brain.data.puppetmaster_aliases

  status = (msg, alias) ->
    host = _puppetmasterAliases[alias]
    console.log(host)
    if host == "" || host == undefined
      msg.send("No host found for #{alias}")
    else
      msg.http("#{host}/radiator")
        .get() (err, res, body) ->
          $ = cheerio.load(body)
          unresponsive = $('tr.unresponsive td.count_column .count').text()
          failed = $('tr.failed td.count_column .count').text()
          changed = $('tr.changed td.count_column .count').text()
          unchanged = $('tr.unchanged td.count_column .count').text()
          msg.send("Current Node Status on #{host}\nUnresponsive: #{unresponsive}\nFailed: #{failed}\nChanged: #{changed}\nUnchanged: #{unchanged}")

  showAliases = (msg) ->
    for alias of _puppetmasterAliases
      msg.send("I found '#{alias}' as an alias for #{_puppetmasterAliases[alias]}")

  clearAlias = (msg, alias) ->
    delete _puppetmasterAliases[alias]
    robot.brain.data.puppetmaster_aliases = _puppetmasterAliases
    msg.send("The alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _puppetmasterAliases[alias] = url
    robot.brain.data.puppetmaster_aliases = _puppetmasterAliases
    msg.send("The alias #{alias} for #{url} has been added to the brain")

  robot.respond /puppetmaster status (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    status msg, msg.match[1], (text) ->
      msg.send(text)

  robot.respond /puppetmaster show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.respond /puppetmaster add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /puppetmaster clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)