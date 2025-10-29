import { DynamoDBClient, UpdateItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';

const dynamodb = new DynamoDBClient({ region: process.env.AWS_REGION });

export const handler = async (event) => {
    const headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Content-Type": "application/json"
    };

    if (event.httpMethod === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }

    try {
        const path = event.path || '/';

        // Update visit count
        await dynamodb.send(new UpdateItemCommand({
            TableName: process.env.TABLE_NAME,
            Key: { path: { S: path } },
            UpdateExpression: 'ADD visitCount :inc SET lastVisit = :timestamp',
            ExpressionAttributeValues: {
                ':inc': { N: '1' },
                ':timestamp': { S: new Date().toISOString() }
            }
        }));

        // Get current count
        const result = await dynamodb.send(new GetItemCommand({
            TableName: process.env.TABLE_NAME,
            Key: { path: { S: path } }
        }));

        const visitCount = result.Item?.visitCount?.N || '1';

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ 
                visitCount: parseInt(visitCount),
                timestamp: new Date().toISOString()
            })
        };

    } catch (error) {
        console.error('Visit counter error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: 'Failed to update visit count' })
        };
    }
};
