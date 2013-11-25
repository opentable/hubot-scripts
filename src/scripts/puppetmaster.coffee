# Description:
#   Display current puppetmaster node status
#
#
# Commands:
#   hubot puppetmaster status [server] - please note that this needs to include any port numbers as appropriate
#
# Author:
#   pstack

cheerio = require('cheerio')

module.exports = (robot) ->

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