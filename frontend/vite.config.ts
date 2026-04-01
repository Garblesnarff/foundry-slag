import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5175,
    strictPort: false,
    open: false,
    proxy: {
      '/slag': {
        target: 'http://localhost:3458',
        changeOrigin: true,
      },
      '/history': {
        target: 'http://localhost:3458',
        changeOrigin: true,
      },
      '/settings': {
        target: 'http://localhost:3458',
        changeOrigin: true,
      },
      '/export': {
        target: 'http://localhost:3458',
        changeOrigin: true,
      },
      '/health': {
        target: 'http://localhost:3458',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'esbuild',
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
