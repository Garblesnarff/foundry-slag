import { Component, ReactNode } from 'react'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-forge-black flex items-center justify-center p-8">
          <div className="max-w-md text-center space-y-4">
            <h1 className="text-2xl font-display text-slag-amber">The forge hit a snag</h1>
            <p className="text-forge-light text-sm">
              {this.state.error?.message || 'Something went wrong'}
            </p>
            <button
              onClick={() => {
                this.setState({ hasError: false, error: null })
                window.location.reload()
              }}
              className="px-6 py-2 bg-slag-amber text-forge-black font-semibold rounded-lg hover:brightness-110 transition"
            >
              Restart the forge
            </button>
          </div>
        </div>
      )
    }
    return this.props.children
  }
}
