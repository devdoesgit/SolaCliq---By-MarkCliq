/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

// In development, /api/v1 goes to the Prism mock (`make mock`), which serves
// the spec's paths without the prefix. Set BACKEND_URL (for example
// http://localhost:8080) to use a local backend instead; it gets the full
// /api/v1/... path, as in production.
const backend = process.env.BACKEND_URL;

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api/v1': backend
        ? { target: backend, changeOrigin: true }
        : {
            target: 'http://localhost:4010',
            changeOrigin: true,
            rewrite: (path) => path.replace(/^\/api\/v1/, ''),
          },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
  },
});
