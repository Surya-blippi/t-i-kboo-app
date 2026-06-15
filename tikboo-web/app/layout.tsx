import type { Metadata, Viewport } from "next";
import { Unbounded, Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const unbounded = Unbounded({
  subsets: ["latin"],
  weight: ["400", "600", "700", "800", "900"],
  variable: "--font-unbounded",
});
const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-jakarta",
});

export const metadata: Metadata = {
  title: "tikboo — your chat, decoded",
  description:
    "Drop a WhatsApp chat export and get a Wrapped-style breakdown plus an AI vibe check. 🍵",
  openGraph: {
    title: "tikboo — your chat, decoded 🍵",
    description:
      "Who texts first, green & red flags with receipts, attachment style, and a loving roast.",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#0B0B0F",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${unbounded.variable} ${jakarta.variable}`}>
      <body className="font-body bg-ink text-textHi">{children}</body>
    </html>
  );
}
