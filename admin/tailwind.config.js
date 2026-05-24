/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        coral: {
          50: '#FAECE7',
          100: '#F5C4B3',
          400: '#D85A30',
          600: '#993C1D',
          900: '#4A1B0C',
        },
        teal: {
          50: '#E1F5EE',
          100: '#9FE1CB',
          400: '#1D9E75',
          600: '#0F6E56',
          900: '#04342C',
        },
        carbon: '#2C2C2A',
        gris: {
          100: '#F1EFE8',
          200: '#D3D1C7',
          400: '#888780',
          600: '#5F5E5A',
          800: '#444441',
        },
      },
      fontFamily: {
        sans: ['Poppins', 'sans-serif'],
      },
    },
  },
  plugins: [],
}