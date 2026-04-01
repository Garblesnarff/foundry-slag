/**
 * useSSE Hook
 * 
 * Custom hook for handling Server-Sent Events.
 * Used for batch processing progress updates.
 */

import { useEffect, useState } from 'react'

interface SSEMessage {
  status: string
  progress?: number
  completed?: number
  total?: number
}

export function useSSE(url: string, enabled: boolean = false) {
  const [messages, setMessages] = useState<SSEMessage[]>([])
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    if (!enabled) return

    const eventSource = new EventSource(url)

    eventSource.addEventListener('message', (event) => {
      try {
        const data = JSON.parse(event.data) as SSEMessage
        setMessages(prev => [...prev, data])
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to parse SSE message'))
      }
    })

    eventSource.addEventListener('error', () => {
      eventSource.close()
      setError(new Error('SSE connection failed'))
    })

    return () => {
      eventSource.close()
    }
  }, [url, enabled])

  return { messages, error }
}
