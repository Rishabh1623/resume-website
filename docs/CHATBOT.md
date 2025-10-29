# Chatbot Configuration

## Overview
The chatbot uses Amazon Bedrock with Claude 3 Haiku for cost-effective AI conversations.

## Features
- Natural conversation about Rishabh's experience
- Action execution (schedule meetings, download resume)
- Conversation history (5 exchanges per session)
- 1-hour session TTL for cost optimization

## Customization

### Modify System Prompt
Edit `lambda/chatbot-handler.mjs`:
```javascript
const SYSTEM_PROMPT = `You are Rishabh's AI assistant...`;
```

### Add New Actions
```javascript
// In generateResponse function
case 'new_action':
    return {
        message: "Action response",
        actions: [{"type": "new_action", "data": {...}}]
    };
```

### Frontend Integration
```javascript
// Handle new actions in website/index.html
function handleActions(actions) {
    actions.forEach(action => {
        switch (action.type) {
            case 'new_action':
                // Handle new action
                break;
        }
    });
}
```

## Cost Optimization

### Current Settings
- **Model**: Claude 3 Haiku (cheapest option)
- **Max Tokens**: 500 per response
- **Memory**: 256MB Lambda
- **Timeout**: 15 seconds
- **History**: 5 exchanges (vs 10)
- **TTL**: 1 hour (vs 24 hours)

### Expected Costs
- **1000 conversations/month**: ~$1-3
- **Input**: $0.25 per 1M tokens
- **Output**: $1.25 per 1M tokens

### Further Optimization
1. Reduce max_tokens to 300
2. Implement conversation caching
3. Use shorter system prompts
4. Add conversation limits per session

## Monitoring
- CloudWatch logs: `/aws/lambda/chatbot-handler`
- DynamoDB metrics: `chatbot-conversations` table
- Bedrock usage: AWS Console > Bedrock > Usage
