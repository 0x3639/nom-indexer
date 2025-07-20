<template>
  <div class="chat-container">
    <!-- Header -->
    <div class="chat-header">
      <div class="flex items-center space-x-3">
        <div class="assistant-avatar">
          <span class="material-icons text-lg">analytics</span>
        </div>
        <div>
          <h1 class="text-xl font-bold">NoM Blockchain Query Interface</h1>
          <p class="text-sm" style="color: var(--zenon-text-secondary)">Ask questions about the blockchain data in natural language</p>
        </div>
      </div>
    </div>
    
    <!-- Messages Area -->
    <div class="chat-messages" ref="messagesContainer">
      <!-- Welcome Screen -->
      <div v-if="messages.length === 0" class="welcome-screen">
        <div class="flex items-center space-x-3 mb-4">
          <div class="assistant-avatar">
            <span class="material-icons text-lg">analytics</span>
          </div>
          <h2 class="welcome-title">Welcome to NoM Query</h2>
        </div>
        <p class="welcome-subtitle">Ask questions about the Zenon blockchain data in natural language</p>
        
        <!-- Example Questions -->
        <div v-if="examples.length > 0" class="example-queries">
          <button
            v-for="example in examples.slice(0, 6)"
            :key="example"
            @click="sendQuery(example)"
            class="example-query"
          >
            <span class="material-icons text-sm mr-2 opacity-70">lightbulb</span>
            {{ example }}
          </button>
        </div>
      </div>
      
      <!-- Messages -->
      <div v-for="message in messages" :key="message.id" class="message">
        <!-- User Message -->
        <div v-if="message.type === 'user'" class="message-user">
          <div class="message-content">
            {{ message.content }}
          </div>
          <div class="user-avatar">
            <span class="material-icons text-sm">person</span>
          </div>
        </div>
        
        <!-- Assistant Message -->
        <div v-else class="message-assistant">
          <div class="assistant-avatar">
            <span class="material-icons text-sm">analytics</span>
          </div>
          <div class="message-content">
            <div class="mb-3">{{ message.content }}</div>
            
            <!-- SQL Query Display -->
            <div v-if="message.sqlQuery" class="sql-section">
              <div class="sql-header">
                <span class="sql-title">Generated SQL Query:</span>
                <button @click="copyToClipboard(message.sqlQuery)" class="copy-button">
                  <span class="material-icons text-xs mr-1">content_copy</span>
                  Copy
                </button>
              </div>
              <pre class="sql-code">{{ message.sqlQuery }}</pre>
            </div>
            
            <!-- Results Display -->
            <div v-if="message.results && message.results.length > 0" class="results-section">
              <div class="results-header">
                <span class="material-icons text-sm mr-1">table_view</span>
                Results ({{ message.rowCount }} {{ message.rowCount === 1 ? 'row' : 'rows' }})
              </div>
              <div class="overflow-x-auto">
                <table class="result-table">
                  <thead>
                    <tr>
                      <th v-for="key in Object.keys(message.results[0])" :key="key">
                        {{ key }}
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, idx) in message.results.slice(0, 100)" :key="idx">
                      <td v-for="key in Object.keys(row)" :key="key">
                        {{ formatValue(row[key]) }}
                      </td>
                    </tr>
                  </tbody>
                </table>
                <div v-if="message.results.length > 100" class="text-sm mt-3" style="color: var(--zenon-text-secondary)">
                  <span class="material-icons text-sm mr-1">info</span>
                  Showing first 100 rows of {{ message.rowCount }} total
                </div>
              </div>
            </div>
            
            <!-- Error Display -->
            <div v-if="message.error" class="error-message">
              <div class="flex items-start space-x-2">
                <span class="material-icons text-sm mt-0.5">error</span>
                <span>{{ message.error }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Loading Indicator -->
      <div v-if="isLoading" class="message">
        <div class="message-assistant">
          <div class="assistant-avatar">
            <span class="material-icons text-sm">analytics</span>
          </div>
          <div class="message-content">
            <div class="loading-spinner">
              <svg class="spinner-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>Processing your query...</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Input Area -->
    <div class="chat-input-area">
      <form @submit.prevent="handleSubmit" class="chat-input-form">
        <input
          v-model="currentQuery"
          type="text"
          placeholder="Ask a question about the blockchain data..."
          class="chat-input"
          :disabled="isLoading"
        />
        <button
          type="submit"
          :disabled="!currentQuery.trim() || isLoading"
          class="send-button"
        >
          <span class="material-icons text-lg">send</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted } from 'vue'
import { useQueryStore } from '~/stores/query'

const queryStore = useQueryStore()
const currentQuery = ref('')
const messagesContainer = ref(null)

const messages = computed(() => queryStore.messages)
const isLoading = computed(() => queryStore.isLoading)
const examples = computed(() => queryStore.examples)

onMounted(() => {
  queryStore.loadExamples()
})

const handleSubmit = async () => {
  if (!currentQuery.value.trim() || isLoading.value) return
  
  await sendQuery(currentQuery.value)
  currentQuery.value = ''
}

const sendQuery = async (query) => {
  await queryStore.sendQuery(query)
  await nextTick()
  scrollToBottom()
}

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

const formatValue = (value) => {
  if (value === null) return 'null'
  if (value === undefined) return ''
  if (typeof value === 'object') return JSON.stringify(value)
  return value.toString()
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    alert('SQL copied to clipboard!')
  } catch (err) {
    console.error('Failed to copy:', err)
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&display=swap');
@import url('https://fonts.googleapis.com/icon?family=Material+Icons');

.chat-container {
  font-family: 'Montserrat', sans-serif;
  background-color: #151515;
  color: #ffffff;
  height: 100vh;
  display: flex;
  flex-direction: column;
  max-width: 960px;
  margin: 0 auto;
  width: 100%;
}

.chat-header {
  background-color: #1a1a1a;
  border-bottom: 1px solid #333333;
  padding: 1rem 1.5rem;
  width: 100%;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem 2rem;
  background-color: #151515;
  width: 100%;
}

.message {
  margin-bottom: 1.5rem;
}

.message-user {
  display: flex;
  justify-content: flex-end;
}

.message-user .message-content {
  background-color: #6FF34D;
  color: #151515;
  padding: 1rem;
  border-radius: 1rem;
  max-width: 32rem;
  font-weight: 500;
}

.message-assistant {
  display: flex;
  justify-content: flex-start;
}

.message-assistant .message-content {
  color: #ffffff;
  max-width: 64rem;
}

.assistant-avatar, .user-avatar {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0.25rem 0.75rem;
}

.assistant-avatar {
  background-color: #6FF34D;
  color: #151515;
}

.user-avatar {
  background-color: #202020;
  color: #ffffff;
}

.sql-section {
  margin-top: 1rem;
  padding: 1rem;
  background-color: #1a1a1a;
  border: 1px solid #333333;
  border-radius: 0.5rem;
}

.sql-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.sql-title {
  color: #cccccc;
  font-size: 0.875rem;
  font-weight: 500;
}

.copy-button {
  background-color: #202020;
  color: #cccccc;
  border: 1px solid #333333;
  padding: 0.25rem 0.75rem;
  font-size: 0.75rem;
  border-radius: 0.25rem;
  cursor: pointer;
  transition: all 0.2s;
}

.copy-button:hover {
  background-color: #6FF34D;
  color: #151515;
  border-color: #6FF34D;
}

.sql-code {
  background-color: #151515;
  color: #ffffff;
  border: 1px solid #333333;
  padding: 0.75rem;
  border-radius: 0.375rem;
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  overflow-x: auto;
}

.results-section {
  margin-top: 1rem;
}

.results-header {
  color: #cccccc;
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 0.75rem;
}

.result-table {
  width: 100%;
  border-collapse: collapse;
  background-color: #1a1a1a;
  border: 1px solid #333333;
  border-radius: 0.5rem;
  overflow: hidden;
}

.result-table th {
  background-color: #202020;
  color: #ffffff;
  padding: 0.75rem 1rem;
  text-align: left;
  font-size: 0.875rem;
  font-weight: 500;
  border-bottom: 1px solid #333333;
}

.result-table td {
  color: #ffffff;
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  border-bottom: 1px solid #333333;
}

.result-table tr:last-child td {
  border-bottom: none;
}

.result-table tr:hover {
  background-color: #151515;
}

.error-message {
  margin-top: 0.75rem;
  padding: 0.75rem;
  background-color: rgba(249, 22, 144, 0.1);
  color: #F91690;
  border: 1px solid rgba(249, 22, 144, 0.2);
  border-radius: 0.5rem;
  font-size: 0.875rem;
}

.chat-input-area {
  background-color: #1a1a1a;
  border-top: 1px solid #333333;
  padding: 1rem 2rem;
  width: 100%;
}

.chat-input-form {
  display: flex;
  gap: 1rem;
  width: 100%;
}

.chat-input {
  flex: 1;
  background-color: #151515;
  color: #ffffff;
  border: 1px solid #333333;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  font-size: 0.95rem;
  transition: all 0.2s;
}

.chat-input:focus {
  outline: none;
  border-color: #6FF34D;
  box-shadow: 0 0 0 2px rgba(111, 243, 77, 0.2);
}

.chat-input::placeholder {
  color: #808080;
}

.send-button {
  background-color: #6FF34D;
  color: #151515;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.send-button:hover:not(:disabled) {
  background-color: #5bd93a;
  transform: translateY(-1px);
}

.send-button:disabled {
  background-color: #202020;
  color: #888888;
  cursor: not-allowed;
}

.loading-spinner {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: #cccccc;
}

.spinner-icon {
  width: 1.25rem;
  height: 1.25rem;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Responsive Design */
@media (max-width: 768px) {
  .chat-container {
    max-width: 100%;
  }
  
  .chat-messages {
    padding: 1rem 1rem;
  }
  
  .chat-input-area {
    padding: 1rem 1rem;
  }
  
  .welcome-screen {
    padding: 2rem 1rem;
  }
}

@media (min-width: 769px) and (max-width: 1024px) {
  .chat-container {
    max-width: 90%;
  }
}

@media (min-width: 1025px) {
  .chat-container {
    max-width: 960px;
  }
}

.welcome-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 3rem 1rem;
  max-width: 750px;
  margin: 0 auto;
}

.welcome-title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #ffffff;
  margin-bottom: 0.5rem;
}

.welcome-subtitle {
  font-size: 1rem;
  color: #cccccc;
  margin-bottom: 2rem;
}

.example-queries {
  display: grid;
  gap: 0.75rem;
  width: 100%;
  max-width: 625px;
}

.example-query {
  background-color: #1a1a1a;
  color: #ffffff;
  border: 1px solid #333333;
  padding: 1rem;
  border-radius: 0.5rem;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
}

.example-query:hover {
  background-color: #202020;
  border-color: #6FF34D;
  transform: translateY(-1px);
}
</style>