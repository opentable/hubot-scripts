# Description
#   PuppetDB integration with hubot
#
# Commands:
#   hubot puppetdb show status in [environment]   - Shows the current status statistics
#   hubot puppetdb show stats in [environment]    - Shows the current resource/node statistics
#   hubot puppetdb show aliases                  - shows the aliases for the list of puppetboard instances
#   hubot puppetdb add alias [alias name] [url]  - sets the alias for a given url
#   hubot puppetdb clear alias [alias name]      - removed the given alias
#
# Notes:
#   The server must be a fqdn (including the http protocol prefix)
#
# Author:
#  Liam Bennett

sys = require 'sys' # Used for debugging
Browser = require('zombie')
_puppetdbAliases = {}


class PuppetDB
  constructor: (@robot) ->
    @logger = @robot.logger

  getFailed: (url, cb) ->
    browser = new Browser

    browser.visit "#{url}/", (e) ->
      browser.wait 5000, (f) ->
        cb browser.text('.ui.red.header.no-margin-bottom').trim() + " with status failed"

  getPending: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        cb browser.text('.ui.purple.header.no-margin-bottom').trim() + " with status pending"

  getChanged: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        cb browser.text('.ui.green.header.no-margin-bottom').trim() + " with status changed"

  getUnreported: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        cb browser.text('.ui.black.header.no-margin-bottom').trim() + " unreported in the last 3 hours"

  getPopulation: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        items = browser.querySelectorAll('.ui.header.darkblue.no-margin-bottom')
        value = items[0]._childNodes[0]._nodeValue.trim() + " Population"
        cb value

  getResources: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        items = browser.querySelectorAll('.ui.header.darkblue.no-margin-bottom')
        value = items[1]._childNodes[0]._nodeValue.trim() + " Resources managed"
        cb value

  getResPerNode: (url, cb) ->
    browserOpts =
      site: url

    browser = new Browser browserOpts

    browser.visit '/', (e) ->
      browser.wait 5000, (f) ->
        items = browser.querySelectorAll('.ui.header.darkblue.no-margin-bottom')
        value = items[2]._childNodes[0]._nodeValue.trim() + " Avg. resources/node"
        cb value

module.exports = (robot) ->
  logger = robot.logger

  robot.brain.on 'loaded', ->
    if robot.brain.data.puppetdb_aliases?
      _puppetdbAliases = robot.brain.data.puppetdb_aliases

  showAliases = (msg) ->
    if _puppetdbAliases == null || Object.keys(_puppetdbAliases).length == 0
      msg.send("I cannot find any puppetdb system aliases")
    else
      for alias of _puppetdbAliases
        msg.send("I found '#{alias}' as an alias for the system: #{_puppetdbAliases[alias]['url']}")

  clearAlias = (msg, alias) ->
    delete _puppetdbAliases[alias]
    robot.brain.data.puppetdb_aliases = _puppetdbAliases
    msg.send("The puppetdb system alias #{alias} has been removed")

  setAlias = (msg, alias, url) ->
    _puppetdbAliases[alias] = { url: url }
    robot.brain.data.puppetdb_aliases = _puppetdbAliases
    msg.send("The puppetdb system alias #{alias} for #{url} has been added to the brain")


  robot.respond /puppetdb show status in (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    alias =  msg.match[1]
    url = _puppetdbAliases[alias]['url']

    puppetdb = new PuppetDB(robot)

    status = []
    functions = ['getFailed', 'getPending', 'getChanged', 'getUnreported']
    count = 0
    functions.forEach (name) ->
      puppetdb[name] url, (callback) ->
        status.push callback
        msg.send status.join("\n") if count >= (functions.length-1)
        count++

  robot.respond /puppetdb show stats in (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    alias =  msg.match[1]
    url = _puppetdbAliases[alias]['url']

    puppetdb = new PuppetDB(robot)

    status = []
    functions = ['getPopulation', 'getResources', 'getResPerNode']
    count = 0
    functions.forEach (name) ->
      puppetdb[name] url, (callback) ->
        status.push callback
        msg.send status.join("\n") if count >= (functions.length-1)
        count++


  robot.respond /puppetdb show aliases/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    showAliases msg, (text) ->
      msg.send(text)

  robot.respond /puppetdb add alias (.*) (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    setAlias msg, msg.match[1], msg.match[2], (text) ->
      msg.send(text)

  robot.respond /puppetdb clear alias (.*)/i, (msg) ->
    if msg.message.user.id is robot.name
      return

    clearAlias msg, msg.match[1], (text) ->
      msg.send(text)
