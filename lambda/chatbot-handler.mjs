import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient, PutItemCommand, GetItemCommand } from '@aws-sdk/client-dynamodb';

const bedrock = new BedrockRuntimeClient({ region: process.env.AWS_REGION });
const dynamodb = new DynamoDBClient({ region: process.env.AWS_REGION });

const SYSTEM_PROMPT = `You are Rishabh's AI assistant. Key info:
- AWS Certified Solutions Architect (2025)
- 4+ years experience (fintech, retail, healthcare)
- Team Computers: EKS microservices (10× scalability)
- TECHVED: SpendWise tool (20% cost savings)
- Terraform: 75% faster provisioning

Actions: schedule_meeting, download_resume, show_projects, highlight_achievement

Respond in JSON: {"message": "response", "actions": [{"type": "action", "data": {}}]}`;

export const handler = async (event) => {
    const headers = {
        "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN || "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Content-Type": "application/json"
    };

    if (event.httpMethod === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }

    try {
        const { message, sessionId } = JSON.parse(event.body || '{}');
        const session = sessionId || `session_${Date.now()}`;

        const history = await getConversationHistory(session);
        const response = await generateResponse(message, history);
        await storeConversation(session, message, response);

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                response: response.message,
                actions: response.actions || [],
                sessionId: session,
                timestamp: new Date().toISOString()
            })
        };

    } catch (error) {
        console.error("Chatbot error:", error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ 
                response: "I'm experiencing technical difficulties. Please try again.",
                actions: []
            })
        };
    }
};

async function generateResponse(userMessage, history) {
    const context = history.slice(-3).map(h => 
        `Human: ${h.userMessage}\nAssistant: ${h.botResponse}`
    ).join('\n');

    const prompt = `${SYSTEM_PROMPT}\n\nContext:\n${context}\n\nHuman: ${userMessage}\n\nAssistant:`;

    const payload = {
        anthropic_version: "bedrock-2023-05-31",
        max_tokens: 500,
        messages: [{ role: "user", content: prompt }]
    };

    const command = new InvokeModelCommand({
        modelId: "anthropic.claude-3-haiku-20240307-v1:0",
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify(payload)
    });

    const response = await bedrock.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    try {
        return JSON.parse(responseBody.content[0].text);
    } catch {
        return {
            message: responseBody.content[0].text,
            actions: [],
            confidence: 0.7
        };
    }
}

async function getConversationHistory(sessionId) {
    try {
        const command = new GetItemCommand({
            TableName: process.env.CONVERSATION_TABLE,
            Key: { sessionId: { S: sessionId } }
        });
        
        const result = await dynamodb.send(command);
        return result.Item ? JSON.parse(result.Item.history.S) : [];
    } catch (error) {
        return [];
    }
}

async function storeConversation(sessionId, userMessage, botResponse) {
    try {
        const history = await getConversationHistory(sessionId);
        history.push({
            userMessage,
            botResponse: botResponse.message,
            timestamp: new Date().toISOString()
        });

        const recentHistory = history.slice(-5);

        const command = new PutItemCommand({
            TableName: process.env.CONVERSATION_TABLE,
            Item: {
                sessionId: { S: sessionId },
                history: { S: JSON.stringify(recentHistory) },
                lastUpdated: { S: new Date().toISOString() },
                ttl: { N: String(Math.floor(Date.now() / 1000) + 3600) }
            }
        });

        await dynamodb.send(command);
    } catch (error) {
        console.error("Error storing conversation:", error);
    }
}
