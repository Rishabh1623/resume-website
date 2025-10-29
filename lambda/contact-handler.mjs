// Optimized Contact Handler - AWS Best Practices
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

// Initialize clients outside handler
const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);
const sesClient = new SESClient({ region: process.env.AWS_REGION });

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Content-Type": "application/json"
};

// Email validation regex
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers: CORS_HEADERS, body: '' };
  }

  try {
    const { name, email, message } = JSON.parse(event.body || '{}');

    // Validation
    const errors = [];
    if (!name || name.trim().length < 2) errors.push('Name must be at least 2 characters');
    if (!email || !EMAIL_REGEX.test(email)) errors.push('Valid email is required');
    if (!message || message.trim().length < 10) errors.push('Message must be at least 10 characters');
    
    if (errors.length > 0) {
      return {
        statusCode: 400,
        headers: CORS_HEADERS,
        body: JSON.stringify({ error: errors.join(', ') })
      };
    }

    const id = `contact_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const timestamp = new Date().toISOString();

    // Store in DynamoDB
    await docClient.send(new PutCommand({
      TableName: process.env.TABLE_NAME,
      Item: {
        id,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        message: message.trim(),
        timestamp,
        status: 'new'
      }
    }));

    // Send email notification (async, don't block response)
    sendEmailNotification(name, email, message).catch(err =>
      console.error('Email send failed:', err)
    );

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({ 
        message: 'Message sent successfully!',
        id
      })
    };

  } catch (error) {
    console.error('Contact form error:', error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Failed to send message. Please try again.' })
    };
  }
};

async function sendEmailNotification(name, email, message) {
  await sesClient.send(new SendEmailCommand({
    Source: process.env.SES_FROM,
    Destination: { ToAddresses: [process.env.TO_EMAIL] },
    Message: {
      Subject: { 
        Data: `New Contact: ${name}`,
        Charset: 'UTF-8'
      },
      Body: {
        Text: {
          Data: `New contact form submission:\n\nName: ${name}\nEmail: ${email}\n\nMessage:\n${message}\n\nTimestamp: ${new Date().toISOString()}`,
          Charset: 'UTF-8'
        }
      }
    }
  }));
}
