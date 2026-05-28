import type { Metadata } from "next";
import "./globals.css";
import Script from "next/script";
import { Outfit } from "next/font/google";

const outfit = Outfit({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
  variable: "--font-outfit",
});

export const metadata: Metadata = {
  title: "Two Dots",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={outfit.variable}>
      <head>
        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&icon_names=water_drop" />
      </head>
      <body>
        <Script src="/lib/jquery-3.5.1.min.js" strategy="beforeInteractive" />
        <Script src="/lib/pengines.js" strategy="beforeInteractive" />
        {children}
      </body>
    </html>
  );
}
