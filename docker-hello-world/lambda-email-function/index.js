const AWS = require('aws-sdk');

// Configure AWS services
const ses = new AWS.SES({ region: 'us-east-1' });
const ssm = new AWS.SSM({ region: 'us-east-1' });

// Parameter Store helper function
async function getParameter(name) {
    try {
        const result = await ssm.getParameter({
            Name: name,
            WithDecryption: true
        }).promise();
        return result.Parameter.Value;
    } catch (error) {
        console.error(`Failed to get parameter ${name}:`, error);
        throw error;
    }
}

exports.handler = async (event) => {
    console.log('Lambda was triggered!');
    console.log('Number of messages received:', event.Records.length);

    try {
        const firstMessage = event.Records[0];
        const guestbookData = JSON.parse(firstMessage.body);

        console.log('Sending email for:', guestbookData.name);

        // Load email configuration from Parameter Store
        console.log('Loading email configuration from Parameter Store...');
        const fromEmail = await getParameter('guestbook-ses-from-email');
        const toEmail = await getParameter('guestbook-ses-to-email');

        // Create email parameters
        const emailParams = {
            Source: fromEmail, 
            Destination: {
                ToAddresses: [toEmail] 
            },
            Message: {
                Subject: {
                    Data: 'New Guestbook Entry!'
                },
                Body: {
                    Text: {
                        Data: `Name: ${guestbookData.name}\nMessage: ${guestbookData.message}`
                    }
                }
            }
        };

        // Send the email
        const result = await ses.sendEmail(emailParams).promise();     
        console.log('Email sent! Message ID:', result.MessageId);      

        return {
            statusCode: 200,
            body: 'Email sent successfully!'
        };

    } catch (error) {
        console.error('Lambda failed:', error);
        throw error;
    }
};