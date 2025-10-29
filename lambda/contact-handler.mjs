import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

const dynamodb = new DynamoDBClient({ region: process.env.AWS_REGION });
const ses = new SESClient({ region: process.env.AWS_REGION });

export const handler = async (event) => {
    const headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Content-Type": "application/json"
    };

    if (event.httpMethod === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }

    try {
        const { name, email, message } = JSON.parse(event.body || '{}');

        if (!name || !email || !message) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: 'Missing required fields' })
            };
        }

        const id = `contact_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Store in DynamoDB
        await dynamodb.send(new PutItemCommand({
            TableName: process.env.TABLE_NAME,
            Item: {
                id: { S: id },
                name: { S: name },
                email: { S: email },
                message: { S: message },
                timestamp: { S: new Date().toISOString() }
            }
        }));

        // Send email notification
        await ses.send(new SendEmailCommand({
            Source: process.env.SES_FROM,
            Destination: { ToAddresses: [process.env.TO_EMAIL] },
            Message: {
                Subject: { Data: `New Contact Form Submission from ${name}` },
                Body: {
                    Text: {
                        Data: `Name: ${name}\nEmail: ${email}\nMessage: ${message}\n\nTimestamp: ${new Date().toISOString()}`
                    }
                }
            }
        }));

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ message: 'Message sent successfully!' })
        };

    } catch (error) {
        console.error('Contact form error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: 'Failed to send message' })
        };
    }
};
