// Description:
//   Ask a question of the form 'should we ...'
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot should we <query>
//   hubot should I <query>
//
// Author:
//   andyroyle

var responses = [
    'It is certain',
    'It is decidedly so',
    'Without a doubt',
    'Yes definitely',
    'You may rely on it',
    'As I see it, yes',
    'Most likely',
    'Outlook good',
    'Yes',
    'Signs point to yes',
    'Reply hazy try again',
    'Ask again later',
    'Better not tell you now',
    'Cannot predict now',
    'Concentrate and ask again',
    'Don\'t count on it',
    'My reply is no',
    'My sources say no',
    'Outlook not so good',
    'Very doubtful'
]

module.exports = function(robot){
    logger = robot.logger;

    robot.respond(/should we (.*)/i, function(msg){
        msg.send(getRandom())
    });

    robot.respond(/should I (.*)/i, function(msg){
        msg.reply(getRandom())
    });
};

var getRandom = function(){
    return responses[Math.floor(Math.random() * responses.length)];
};