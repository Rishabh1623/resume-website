// Enhanced AI Chatbot Frontend - Showcasing Advanced Features
// This demonstrates modern web development and AI integration skills

class EnhancedChatbot {
  constructor(apiEndpoint) {
    this.apiEndpoint = apiEndpoint;
    this.sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    this.isTyping = false;
    this.messageQueue = [];
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.showWelcomeMessage();
  }

  setupEventListeners() {
    const sendBtn = document.getElementById('chatbot-send');
    const input = document.getElementById('chatbot-input');
    const toggle = document.getElementById('chatbot-toggle');

    sendBtn?.addEventListener('click', () => this.sendMessage());
    input?.addEventListener('keypress', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });
    toggle?.addEventListener('click', () => this.toggleChat());

    // Auto-resize input
    input?.addEventListener('input', (e) => {
      e.target.style.height = 'auto';
      e.target.style.height = e.target.scrollHeight + 'px';
    });
  }

  showWelcomeMessage() {
    const welcomeMessages = [
      {
        text: "👋 Hi! I'm Rishabh's AI assistant. I can help you learn about his AWS expertise, projects, and experience.",
        delay: 500
      },
      {
        text: "What would you like to know?",
        delay: 1500,
        suggestions: [
          "Tell me about your AWS experience",
          "What projects have you built?",
          "How did you achieve 10× scalability?"
        ]
      }
    ];

    welcomeMessages.forEach((msg, index) => {
      setTimeout(() => {
        this.addMessage(msg.text, 'bot');
        if (msg.suggestions) {
          this.showSuggestions(msg.suggestions);
        }
      }, msg.delay);
    });
  }

  async sendMessage(text = null) {
    const input = document.getElementById('chatbot-input');
    const message = text || input?.value.trim();
    
    if (!message || this.isTyping) return;

    // Add user message
    this.addMessage(message, 'user');
    if (input) {
      input.value = '';
      input.style.height = 'auto';
    }

    // Show typing indicator
    this.showTypingIndicator();

    try {
      // Get current page context
      const context = {
        currentSection: this.getCurrentSection(),
        timestamp: new Date().toISOString()
      };

      const response = await fetch(this.apiEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message,
          sessionId: this.sessionId,
          context
        })
      });

      const data = await response.json();
      
      // Remove typing indicator
      this.hideTypingIndicator();

      // Add bot response with typing effect
      await this.addMessageWithTyping(data.response, 'bot');

      // Handle actions
      if (data.actions && data.actions.length > 0) {
        this.handleActions(data.actions);
      }

      // Show suggestions
      if (data.suggestions && data.suggestions.length > 0) {
        this.showSuggestions(data.suggestions);
      }

      // Track intent for analytics
      if (data.intent) {
        this.trackIntent(data.intent);
      }

    } catch (error) {
      console.error('Chatbot error:', error);
      this.hideTypingIndicator();
      this.addMessage('I apologize, but I encountered an issue. Please try again.', 'bot');
    }
  }

  addMessage(content, type) {
    const messagesContainer = document.getElementById('chatbot-messages');
    if (!messagesContainer) return;

    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}-message`;
    
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    contentDiv.textContent = content;
    
    messageDiv.appendChild(contentDiv);
    messagesContainer.appendChild(messageDiv);
    
    // Smooth scroll to bottom
    messagesContainer.scrollTo({
      top: messagesContainer.scrollHeight,
      behavior: 'smooth'
    });

    return messageDiv;
  }

  async addMessageWithTyping(content, type) {
    const messageDiv = this.addMessage('', type);
    const contentDiv = messageDiv.querySelector('.message-content');
    
    // Typing effect
    for (let i = 0; i < content.length; i++) {
      contentDiv.textContent += content[i];
      await this.sleep(20); // Adjust speed here
      
      // Auto-scroll during typing
      const container = document.getElementById('chatbot-messages');
      if (container) {
        container.scrollTop = container.scrollHeight;
      }
    }
  }

  showTypingIndicator() {
    this.isTyping = true;
    const messagesContainer = document.getElementById('chatbot-messages');
    if (!messagesContainer) return;

    const typingDiv = document.createElement('div');
    typingDiv.className = 'message bot-message typing-indicator';
    typingDiv.id = 'typing-indicator';
    typingDiv.innerHTML = `
      <div class="message-content">
        <span class="dot"></span>
        <span class="dot"></span>
        <span class="dot"></span>
      </div>
    `;
    
    messagesContainer.appendChild(typingDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  hideTypingIndicator() {
    this.isTyping = false;
    const indicator = document.getElementById('typing-indicator');
    indicator?.remove();
  }

  showSuggestions(suggestions) {
    // Remove existing suggestions
    document.querySelectorAll('.suggestion-chip').forEach(el => el.remove());

    const messagesContainer = document.getElementById('chatbot-messages');
    if (!messagesContainer) return;

    const suggestionsDiv = document.createElement('div');
    suggestionsDiv.className = 'suggestions-container';
    
    suggestions.forEach(suggestion => {
      const chip = document.createElement('button');
      chip.className = 'suggestion-chip';
      chip.textContent = suggestion;
      chip.onclick = () => {
        this.sendMessage(suggestion);
        suggestionsDiv.remove();
      };
      suggestionsDiv.appendChild(chip);
    });

    messagesContainer.appendChild(suggestionsDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  handleActions(actions) {
    actions.forEach(action => {
      switch (action.type) {
        case 'schedule_meeting':
          this.scheduleMeeting();
          break;
        case 'download_resume':
          this.downloadResume();
          break;
        case 'show_projects':
          this.scrollToSection('projects');
          break;
        case 'show_experience':
          this.scrollToSection('experience');
          break;
        case 'show_skills':
          this.scrollToSection('skills');
          break;
      }
    });
  }

  scheduleMeeting() {
    const subject = encodeURIComponent('Discussion about your portfolio');
    const body = encodeURIComponent('Hi Rishabh,\n\nI would like to schedule a meeting to discuss your experience and potential opportunities.\n\nBest regards');
    window.open(`mailto:rishabhmadne16@outlook.com?subject=${subject}&body=${body}`);
  }

  downloadResume() {
    const link = document.createElement('a');
    link.href = '/resume.pdf';
    link.download = 'Rishabh_Madne_Resume.pdf';
    link.click();
  }

  scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
      section.scrollIntoView({ behavior: 'smooth', block: 'start' });
      
      // Visual feedback
      section.style.transition = 'all 0.3s ease';
      section.style.transform = 'scale(1.02)';
      setTimeout(() => {
        section.style.transform = 'scale(1)';
      }, 300);
    }
  }

  getCurrentSection() {
    const sections = ['experience', 'projects', 'skills', 'contact'];
    const scrollPosition = window.scrollY + window.innerHeight / 2;

    for (const sectionId of sections) {
      const section = document.getElementById(sectionId);
      if (section) {
        const rect = section.getBoundingClientRect();
        const sectionTop = rect.top + window.scrollY;
        const sectionBottom = sectionTop + rect.height;
        
        if (scrollPosition >= sectionTop && scrollPosition <= sectionBottom) {
          return sectionId;
        }
      }
    }
    
    return 'home';
  }

  toggleChat() {
    const messages = document.getElementById('chatbot-messages');
    const inputContainer = document.querySelector('.chatbot-input-container');
    const toggle = document.getElementById('chatbot-toggle');

    if (messages && inputContainer && toggle) {
      const isHidden = messages.style.display === 'none';
      messages.style.display = isHidden ? 'flex' : 'none';
      inputContainer.style.display = isHidden ? 'flex' : 'none';
      toggle.textContent = isHidden ? '−' : '+';
    }
  }

  trackIntent(intent) {
    // Analytics tracking (can be extended with Google Analytics, etc.)
    console.log('User intent:', intent);
    
    // Could send to analytics service
    if (window.gtag) {
      window.gtag('event', 'chatbot_intent', {
        'event_category': 'Chatbot',
        'event_label': intent
      });
    }
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Initialize chatbot when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const API_BASE = 'YOUR_API_GATEWAY_URL';
  const CHATBOT_ENDPOINT = `${API_BASE}/chatbot`;
  
  if (CHATBOT_ENDPOINT && !CHATBOT_ENDPOINT.includes('YOUR_API')) {
    window.chatbot = new EnhancedChatbot(CHATBOT_ENDPOINT);
  }
});

// Add enhanced styles for new features
const enhancedStyles = `
  .typing-indicator .message-content {
    display: flex;
    gap: 4px;
    padding: 12px 16px;
  }
  
  .typing-indicator .dot {
    width: 8px;
    height: 8px;
    background: var(--text-lighter);
    border-radius: 50%;
    animation: typingDot 1.4s infinite;
  }
  
  .typing-indicator .dot:nth-child(2) {
    animation-delay: 0.2s;
  }
  
  .typing-indicator .dot:nth-child(3) {
    animation-delay: 0.4s;
  }
  
  @keyframes typingDot {
    0%, 60%, 100% { transform: translateY(0); opacity: 0.7; }
    30% { transform: translateY(-10px); opacity: 1; }
  }
  
  .suggestions-container {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 12px 16px;
    animation: fadeIn 0.3s ease;
  }
  
  .suggestion-chip {
    background: linear-gradient(135deg, var(--primary-light), var(--primary));
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: var(--shadow);
  }
  
  .suggestion-chip:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-md);
  }
  
  .message-content {
    animation: messageSlide 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }
`;

// Inject enhanced styles
const styleSheet = document.createElement('style');
styleSheet.textContent = enhancedStyles;
document.head.appendChild(styleSheet);
