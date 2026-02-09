// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },

  // Output static HTML (default)
  output: 'static',

  // Use relative paths so dist/index.html works when opened directly
  base: '',
  build: {
    assetsPrefix: '.',
  },
});
