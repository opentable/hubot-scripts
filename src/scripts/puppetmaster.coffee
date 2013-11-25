# Description:
#   Display current puppetmaster node status
#
#
# Commands:
#   hubot puppetmaster status [server] - please note that this needs to include any port numbers as appropriate
#   hubot puppetmaster show aliases - shows the aliases for the list of pupeptmasters
#   hubot puppetmaster set alias [alias name] [url] - sets the alias for a given url
#   hubot puppetmaster clear alias [alias name] [url] - please note that this needs to include any port numbers as appropriate
#
# Author:
#   pstack

cheerio = require('cheerio')

module.exports = (robot) ->

  robot.brain.on 'loaded', ->
    puppetmasterAliases = robot.brain.data.puppermaster_aliases or {}

  status = (msg, host) ->
    msg.http("#{host}/radiator")
      .get() (err, res, body) ->
        $ = cheerio.load(body)
        unresponsive = $('tr.unresponsive td.count_column .count').text()
        failed = $('tr.failed td.count_column .count').text()
        changed = $('tr.changed td.count_column .count').text()
        unchanged = $('tr.unchanged td.count_column .count').text()
        msg.send("Current Node Status on #{host}\nUnresponsive: #{unresponsive}\nFailed: #{failed}\nChanged: #{changed}\nUnchanged: #{unchanged}")

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

    setAlias msg, msg.match[1], msg.match[2] (text) ->
      msg.send(text)

  robot.respond /puppetmaster clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], msg.match[2] (text) ->
      msg.send(text)