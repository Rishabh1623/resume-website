// Advanced AI Chatbot - Showcasing AI/ML Engineering Expertise
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const bedrockClient = new BedrockRuntimeClient({ region: process.env.AWS_REGION });
const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(ddbClient);

// Enhanced system prompt with personality and context awareness
const SYSTEM_PROMPT = `You are Rishabh's AI Career Assistant - an intelligent, engaging chatbot showcasing advanced AI engineering.

PERSONALITY:
- Professional yet conversational
- Proactive in highlighting relevant achievements
- Ask clarifying questions when needed
- Provide specific examples and metrics

KNOWLEDGE BASE:
🎓 CERTIFICATIONS:
- AWS Certified Solutions Architect - Associate (2025)
- Active learner in cloud architecture and DevOps

💼 EXPERIENCE:
1. Team Computers (2023-Present) - Cloud Engineer
   - Re-architected fintech monolith → EKS microservices
   - Achieved 10× scalability improvement
   - Zero downtime migration with service mesh
   - Implemented CI/CD with canary deployments
   - Tech: EKS, Aurora, Kubernetes, Terraform

2. TECHVED Consulting (2021-2023) - DevOps Consultant
   - Built SpendWise: Automated cost optimization tool
   - Achieved 20% average cost savings across clients
   - Automated ETL pipeline optimization
   - Real-time monitoring with CloudWatch & SNS
   - Tech: Lambda, CloudWatch, Cost Explorer, Python

🚀 KEY PROJECTS:
1. Serverless Resume Website (This site!)
   - S3 + CloudFront + Lambda + DynamoDB
   - AI chatbot using Amazon Bedrock (Claude 3 Haiku)
   - Infrastructure as Code with Terraform
   - Cost-optimized: ~$3-5/month
   - Features: Contact form, visit tracking, AI assistant

2. SpendWise AWS Cost Dashboard
   - Real-time cost monitoring & alerts
   - Automated optimization recommendations
   - Budget forecasting with ML
   - 20% cost reduction achieved
   - Tech: Lambda, DynamoDB, SNS, Cost Explorer

3. Scalable WordPress Blog
   - Multi-AZ architecture with Auto Scaling
   - RDS with read replicas
   - CloudFront CDN
   - 99.9% uptime, 10k+ concurrent users
   - Tech: EC2, RDS, CloudFront, Route 53

🛠️ TECHNICAL SKILLS:
Cloud: AWS (EC2, S3, Lambda, EKS, RDS, DynamoDB, CloudFront, Route 53)
IaC: Terraform, CloudFormation, AWS CDK
Containers: Docker, Kubernetes, EKS, Helm
CI/CD: GitHub Actions, Jenkins, GitLab CI
Monitoring: CloudWatch, Prometheus, Grafana, X-Ray
Languages: Python, JavaScript/Node.js, Bash
Databases: Aurora, RDS, DynamoDB, PostgreSQL

🎯 SPECIALIZATIONS:
- Cloud architecture & migration strategies
- Cost optimization & FinOps
- Microservices & containerization
- Infrastructure automation
- DevOps best practices
- Serverless architectures

CONVERSATION STYLE:
- Start with understanding the visitor's needs (hiring, collaboration, learning)
- Provide relevant examples with metrics
- Offer to dive deeper into specific projects
- Suggest next actions (schedule meeting, download resume, view projects)

AVAILABLE ACTIONS:
1. schedule_meeting - Opens email to schedule a discussion
2. download_resume - Triggers resume download
3. show_projects - Scrolls to projects section
4. show_experience - Scrolls to experience section
5. show_skills - Scrolls to skills section

RESPONSE FORMAT:
Always respond in JSON:
{
  "message": "Your engaging response with specific details",
  "actions": [{"type": "action_name", "data": {}}],
  "suggestions": ["Follow-up question 1", "Follow-up question 2"]
}

IMPORTANT:
- Be specific with numbers and achievements
- Match tone to visitor's intent (technical for engineers, business-focused for managers)
- Proactively offer relevant information
- Keep responses concise but informative (2-3 sentences max)`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Content-Type": "application/json"
};

// Intent classification for better responses
const INTENTS = {
  HIRING: ['hire', 'job', 'position', 'role', 'opportunity', 'recruit', 'candidate'],
  TECHNICAL: ['how', 'technical', 'architecture', 'implement', 'build', 'design', 'code'],
  EXPERIENCE: ['experience', 'worked', 'project', 'achievement', 'accomplishment'],
  SKILLS: ['skill', 'technology', 'tool', 'know', 'proficient', 'expert'],
  CONTACT: ['contact', 'reach', 'email', 'schedule', 'meeting', 'call', 'discuss'],
  GENERAL: ['hello', 'hi', 'hey', 'about', 'who', 'what']
};

export const handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers: CORS_HEADERS, body: '' };
  }

  try {
    const { message, sessionId, context } = JSON.parse(event.body || '{}');
    
    // Enhanced validation
    if (!message || message.trim().length === 0) {
      return errorResponse(400, 'Message is required');
    }
    
    if (message.length > 1000) {
      return errorResponse(400, 'Message too long (max 1000 characters)');
    }

    const session = sessionId || `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Classify intent
    const intent = classifyIntent(message);
    
    // Get conversation history with context
    const history = await getConversationHistory(session);
    
    // Generate AI response with intent awareness
    const response = await generateResponse(message, history, intent, context);
    
    // Store conversation asynchronously
    storeConversation(session, message, response, intent).catch(err => 
      console.error('Failed to store conversation:', err)
    );

    return {
      statusCode: 200,
      headers: CORS_HEADERS,
      body: JSON.stringify({
        response: response.message,
        actions: response.actions || [],
        suggestions: response.suggestions || [],
        sessionId: session,
        intent: intent
      })
    };

  } catch (error) {
    console.error('Chatbot error:', error);
    return errorResponse(500, 'I apologize, but I encountered a technical issue. Please try again.');
  }
};

function classifyIntent(message) {
  const lowerMessage = message.toLowerCase();
  
  for (const [intent, keywords] of Object.entries(INTENTS)) {
    if (keywords.some(keyword => lowerMessage.includes(keyword))) {
      return intent;
    }
  }
  
  return 'GENERAL';
}

async function generateResponse(userMessage, history, intent, context = {}) {
  // Build context-aware prompt
  const conversationContext = history.slice(-3).map(h => 
    `Human: ${h.userMessage}\nAssistant: ${h.botResponse}`
  ).join('\n\n');
  
  const intentContext = intent !== 'GENERAL' 
    ? `\n\nUser Intent: ${intent} - Focus your response on this aspect.` 
    : '';
  
  const pageContext = context.currentSection 
    ? `\n\nUser is currently viewing: ${context.currentSection}` 
    : '';

  const fullPrompt = `${SYSTEM_PROMPT}${intentContext}${pageContext}

Previous Conversation:
${conversationContext}

Current Question: ${userMessage}

Provide a helpful, engaging response with specific examples and metrics. Include relevant actions and follow-up suggestions.`;

  const payload = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 500,
    temperature: 0.8,  // More creative responses
    top_p: 0.9,
    messages: [{
      role: "user",
      content: fullPrompt
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
  
  // Parse JSON response with fallback
  try {
    const parsed = JSON.parse(text);
    return {
      message: parsed.message || text,
      actions: parsed.actions || [],
      suggestions: parsed.suggestions || generateDefaultSuggestions(intent)
    };
  } catch {
    return {
      message: text,
      actions: [],
      suggestions: generateDefaultSuggestions(intent)
    };
  }
}

function generateDefaultSuggestions(intent) {
  const suggestions = {
    HIRING: [
      "What's your experience with AWS?",
      "Tell me about your biggest achievement",
      "Can we schedule a call?"
    ],
    TECHNICAL: [
      "How did you implement the EKS migration?",
      "What's your approach to cost optimization?",
      "Tell me about your Terraform expertise"
    ],
    EXPERIENCE: [
      "What was your role at Team Computers?",
      "Tell me about the SpendWise project",
      "What challenges did you overcome?"
    ],
    SKILLS: [
      "What AWS services do you specialize in?",
      "Do you have Kubernetes experience?",
      "What's your DevOps toolkit?"
    ],
    CONTACT: [
      "Schedule a meeting",
      "Download resume",
      "View LinkedIn profile"
    ],
    GENERAL: [
      "What are you looking for?",
      "Tell me about your projects",
      "What's your AWS expertise?"
    ]
  };
  
  return suggestions[intent] || suggestions.GENERAL;
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

async function storeConversation(sessionId, userMessage, botResponse, intent) {
  const history = await getConversationHistory(sessionId);
  
  history.push({
    userMessage,
    botResponse: botResponse.message,
    intent,
    timestamp: new Date().toISOString()
  });

  // Keep last 5 exchanges for better context
  const recentHistory = history.slice(-5);

  await docClient.send(new PutCommand({
    TableName: process.env.CONVERSATION_TABLE,
    Item: {
      sessionId,
      history: recentHistory,
      lastIntent: intent,
      messageCount: history.length,
      lastUpdated: new Date().toISOString(),
      ttl: Math.floor(Date.now() / 1000) + 7200  // 2 hour TTL
    }
  }));
}

function errorResponse(statusCode, message) {
  return {
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify({ 
      error: message,
      response: message,
      actions: [],
      suggestions: ["Try asking about my experience", "What projects have I worked on?", "How can I help you?"]
    })
  };
}
