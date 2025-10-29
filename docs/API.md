# API Documentation

## Base URL
```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod
```

## Endpoints

### Contact Form
**POST** `/contact`

Submit contact form message.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com", 
  "message": "Hello, I'd like to connect!"
}
```

**Response:**
```json
{
  "message": "Message sent successfully!"
}
```

### Visit Counter
**POST** `/visit`

Increment and get visit count.

**Response:**
```json
{
  "visitCount": 42,
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Chatbot
**POST** `/chatbot`

Interact with AI assistant.

**Request Body:**
```json
{
  "message": "Tell me about Rishabh's experience",
  "sessionId": "session_123"
}
```

**Response:**
```json
{
  "response": "Rishabh has 4+ years of AWS experience...",
  "actions": [
    {
      "type": "schedule_meeting",
      "data": {"email": "rishabhmadne16@outlook.com"}
    }
  ],
  "sessionId": "session_123",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Error Responses

All endpoints return errors in this format:
```json
{
  "error": "Error message description"
}
```

Common HTTP status codes:
- `400` - Bad Request (missing/invalid parameters)
- `500` - Internal Server Error
- `200` - Success
