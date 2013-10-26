# Allows Hubot to find out how the Tube is running.
#
# show tube status for <line> line -  Queries the endpoint for the status of that line
# show tube is the <line> working -  Queries the endpoint for the status of that line

_  = require("underscore")

module.exports = (robot) ->

  good_service_statuses = ['Good Service']
  average_statuses = ['Minor Delays', 'Part Suspended']
  bad_statuses = ['Severe Delays']
  closed_statuses = ['Planned Closure', 'Part Closure']

  robot.respond /tube status/i, (msg) ->
    msg.http("http://service-disruption.herokuapp.com/network")
      .get() (err, res, body) ->
        if res.statusCode == 200
          response = JSON.parse(body)
          return_text = ""
          for line in response.network.lines
            do (line) ->
              return_text += "\nThe #{line.line.name} line is currently running with #{line.line.status.status_description}"
          msg.send return_text
        else
          msg.send "NEIN, NEIN, NEIN, NEIN, NEIN!"

  robot.respond /tube is the (.*) line ok\?/i, (msg) ->
    query = msg.match[1].trim().replace(/\s+/g, '-').toLowerCase()
    msg.http("http://service-disruption.herokuapp.com/network/#{query}")
      .get() (err, res, body) ->
        if res.statusCode == 200
          line = JSON.parse(body)
          if _(good_service_statuses).include(line.line.status.status_description)
            msg.send "Nope it's all good, no problems reported"
          if _(average_statuses).include(line.line.status.status_description)
            msg.send "Well it's semi-fucked, TfL says: '#{line.line.status.status_details}'"
          if _(bad_statuses).include(line.line.status.status_description)
            msg.send "Totally fuckeyed mate, best to avoid, Tfl says: '#{line.line.status.status_details}'"
          if _(closed_statuses).include(line.line.status.status_description)
            msg.send "No chance, it's a planned closure, you should really pay attention to the TfL website..."
        else
          msg.send "No line by that name sonny, you sure you even live in London?"