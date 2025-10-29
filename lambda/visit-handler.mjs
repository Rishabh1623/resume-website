// Optimized Visit Handler - AWS Best Practices
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST,GET,OPTIONS",
  "Content-Type": "application/json"
};

export const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers: CORS_HEADERS, body: '' };
  }

  try {
    const path = '/';  // Single counter for entire site
    const timestamp = new Date().toISOString();

    // Atomic increment
    await docClient.send(new UpdateCommand({
      TableName: process.env.TABLE_NAME,
      Key: { path },
      UpdateExpression: 'ADD visitCount :inc SET lastVisit = :timestamp',
      ExpressionAttributeValues: {
        ':inc': 1,
        ':timestamp': timestamp
      }
    }));

    // Get updated count
    const result = await docClient.send(new GetCommand({
      TableName: process.env.TABLE_NAME,
      Key: { path }
    }));

    const visitCount = result.Item?.visitCount || 1;

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({ 
        visitCount,
        timestamp
      })
    };

  } catch (error) {
    console.error('Visit counter error:', error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ 
        visitCount: 0,
        error: 'Failed to update visit count'
      })
    };
  }
};
