var AWS = require('aws-sdk');
var ses = new AWS.SES();

var RECEIVER = 'nelemansc@gmail.com';
var SENDER = 'contact-form@cassidynelemans.com';

var response = {
    "isBase64Encoded": false,
    "headers": { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    "statusCode": 200,
    "body": "{\"result\": \"Success.\"}"
};

exports.handler = function (event, context, callback) {
    console.log(event);
    const body = JSON.parse(event.body)
    sendEmail(body, function (err, data) {
        context.done(err, null);
    });
    callback(null, response);
};

function sendEmail(event, done) {
    var params = {
        Destination: {
            ToAddresses: [
                RECEIVER
            ]
        },
        Message: {
            Body: {
                Text: {
                    Data: 'name: ' + event['name'] + '\nemail: ' + event['email'] + '\nmessage: ' + event['message'],
                    Charset: 'UTF-8'
                }
            },
            Subject: {
                Data: 'Contact Form: ' + event.name,
                Charset: 'UTF-8'
            }
        },
        Source: SENDER
    };
    ses.sendEmail(params, done);
}
