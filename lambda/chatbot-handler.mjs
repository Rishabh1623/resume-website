// Optimized Chatbot Handler - AWS Best Practices
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

// Initialize clients outside handler for reuse
const bedrockClient = new BedrockRuntimeClient({ region: process.env.AWS_REGION });
const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

const SYSTEM_PROMPT = `You are Rishabh's AI assistant. Key info:
- AWS Certified Solutions Architect (2025)
- 4+ years experience (fintech, retail, healthcare)
- Team Computers: EKS microservices (10× scalability)
- TECHVED: SpendWise tool (20% cost savings)
- Terraform: 75% faster provisioning

Keep responses concise and professional. Respond in JSON: {"message": "response", "actions": []}`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Content-Type": "application/json"
};

export const handler = async (event) => {
  // Handle OPTIONS for CORS
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers: CORS_HEADERS, body: '' };
  }

  try {
    const { message, sessionId } = JSON.parse(event.body || '{}');
    
    // Validation
    if (!message || message.trim().length === 0) {
      return errorResponse(400, 'Message is required');
    }
    
    if (message.length > 500) {
      return errorResponse(400, 'Message too long (max 500 characters)');
    }

    const session = sessionId || `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Get conversation history
    const history = await getConversationHistory(session);
    
    // Generate AI response
    const response = await generateResponse(message, history);
    
    // Store conversation (async, don't wait)
    storeConversation(session, message, response).catch(err => 
      console.error('Failed to store conversation:', err)
    );

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({
        response: response.message,
        actions: response.actions || [],
        sessionId: session
      })
    };

  } catch (error) {
    console.error('Chatbot error:', error);
    return errorResponse(500, 'Service temporarily unavailable');
  }
};

async function generateResponse(userMessage, history) {
  const context = history.slice(-2).map(h => 
    `Human: ${h.userMessage}\nAssistant: ${h.botResponse}`
  ).join('\n');

  const payload = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 300,  // Reduced for cost optimization
    temperature: 0.7,
    messages: [{
      role: "user",
      content: `${SYSTEM_PROMPT}\n\nContext:\n${context}\n\nHuman: ${userMessage}\n\nAssistant:`
    }]
  };

  const command = new InvokeModelCommand({
    modelId: "anthropic.claude-3-haiku-20240307-v1:0",
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(payload)
  });

  const response = await bedrockClient.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  const text = responseBody.content[0].text;
  
  // Try to parse as JSON, fallback to plain text
  try {
    return JSON.parse(text);
  } catch {
    return { message: text, actions: [] };
  }
}

async function getConversationHistory(sessionId) {
  try {
    const result = await docClient.send(new GetCommand({
      TableName: process.env.CONVERSATION_TABLE,
      Key: { sessionId }
    }));
    
    return result.Item?.history || [];
  } catch (error) {
    console.error('Failed to get history:', error);
    return [];
  }
}

async function storeConversation(sessionId, userMessage, botResponse) {
  const history = await getConversationHistory(sessionId);
  
  history.push({
    userMessage,
    botResponse: botResponse.message,
    timestamp: new Date().toISOString()
  });

  // Keep only last 3 exchanges
  const recentHistory = history.slice(-3);

  await docClient.send(new PutCommand({
    TableName: process.env.CONVERSATION_TABLE,
    Item: {
      sessionId,
      history: recentHistory,
      lastUpdated: new Date().toISOString(),
      ttl: Math.floor(Date.now() / 1000) + 3600  // 1 hour TTL
    }
  }));
}

function errorResponse(statusCode, message) {
  return {
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify({ 
      error: message,
      response: "I'm having trouble right now. Please try again.",
      actions: []
    })
  };
}
