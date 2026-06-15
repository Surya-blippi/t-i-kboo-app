import type { Config } from "tailwindcss";

// tikboo design tokens — mirror of the Flutter AppColors.
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#0B0B0F",
        inkSoft: "#15151C",
        inkCard: "#1C1C26",
        stroke: "#2A2A38",
        lime: "#CBFF4D",
        pink: "#FF4D9D",
        violet: "#8B5CFF",
        cyan: "#45E0FF",
        tangerine: "#FF8A3D",
        textHi: "#F5F5F7",
        textMid: "#AFAFC0",
        textLow: "#6C6C7E",
      },
      fontFamily: {
        display: ["var(--font-unbounded)", "sans-serif"],
        body: ["var(--font-jakarta)", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;
