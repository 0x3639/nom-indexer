import { defineStore } from 'pinia'

interface Message {
  id: string
  type: 'user' | 'assistant'
  content: string
  timestamp: Date
  sqlQuery?: string
  results?: any[]
  error?: string
  rowCount?: number
}

export const useQueryStore = defineStore('query', {
  state: () => ({
    messages: [] as Message[],
    isLoading: false,
    examples: [] as string[]
  }),
  
  actions: {
    async sendQuery(question: string) {
      // Add user message
      const userMessage: Message = {
        id: Date.now().toString(),
        type: 'user',
        content: question,
        timestamp: new Date()
      }
      this.messages.push(userMessage)
      
      // Set loading state
      this.isLoading = true
      
      try {
        const config = useRuntimeConfig()
        const response = await $fetch(`${config.public.apiUrl}/api/v1/query`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            question,
            include_sql: true
          }
        })
        
        // Add assistant response
        const assistantMessage: Message = {
          id: (Date.now() + 1).toString(),
          type: 'assistant',
          content: response.explanation,
          timestamp: new Date(),
          sqlQuery: response.sql_query,
          results: response.results,
          error: response.error,
          rowCount: response.row_count
        }
        this.messages.push(assistantMessage)
      } catch (error) {
        // Add error message
        const errorMessage: Message = {
          id: (Date.now() + 1).toString(),
          type: 'assistant',
          content: 'Sorry, I encountered an error processing your query.',
          timestamp: new Date(),
          error: error.message || 'Unknown error occurred'
        }
        this.messages.push(errorMessage)
      } finally {
        this.isLoading = false
      }
    },
    
    async loadExamples() {
      try {
        const config = useRuntimeConfig()
        const response = await $fetch(`${config.public.apiUrl}/api/v1/examples`)
        this.examples = response.examples
      } catch (error) {
        console.error('Failed to load examples:', error)
      }
    },
    
    clearMessages() {
      this.messages = []
    }
  }
})