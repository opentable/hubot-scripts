# Description:
#   Show current reviews api status page
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot status review productfeed  - Returns the current state of the Reviews API ProductFeed
#   hubot status <application> [<monitor>] - Returns the current state of the given application

aliases = {
	review:
    'prod-web1': 'http://192.168.220.181/review/service-status/'
    'prod-web2': 'http://192.168.220.182/review/service-status/'
    'preprod-web1': 'http://10.21.6.26/review/service-status/'
    'preprod-web2': 'http://10.21.4.101/review/service-status/'
  promotedoffer:
    'prod-web1': 'http://192.168.220.181/promoted-offer/service-status/'
    'prod-web2': 'http://192.168.220.182/promoted-offer/service-status/'
    'preprod-web1': 'http://10.21.6.26/promoted-offer/service-status/'
    'preprod-web2': 'http://10.21.4.101/promoted-offer/service-status/'
}

module.exports = (robot) ->
  robot.respond /status (.*) (.*) (.*)$/i, (msg) ->
    status msg

# NOTE: messages contains new lines for some reason.
formatString = (string) ->
  decodeURIComponent(string.replace(/(\n)/gm," "))

status = (msg) ->
  bits =
    app: msg.match[1]
    monitor: msg.match[2]
    server: msg.match[3]

  validateRequest(bits, msg, () ->
    sendRequest buildUrl(bits), msg
  )

validateRequest = (bits, msg, callback) ->
  if not aliases[bits.app]
    msg.send "the alias '#{bits.app}' does not exist you fuckhead"
    return
  if not aliases[bits.app][bits.server]
    msg.send "the server '#{bits.server}' does not exist for app '#{bits.app}' you tosspot"
    return
  callback()

buildUrl = (bits) ->
  "#{aliases[bits.app][bits.server]}#{bits.monitor}"

sendRequest = (url, msg) ->
  msg.http(url)
    .get() (err, res, body) ->
      json = JSON.parse(body)
      status = json.Status || json.status
      if not status
        msg.send "I didn't get a valid response, you're SOL, sorry"
        return
      if status is "Unknown"
        msg.send "That monitor does not exist you wanker"
        return
      msg.send "Current Status: #{json.Status || json.status}"