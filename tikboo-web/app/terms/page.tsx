import type { Metadata } from "next";
import { LegalDoc } from "@/components/LegalDoc";
import { TERMS_OF_SERVICE } from "@/lib/legal";

export const metadata: Metadata = { title: "Terms of Service — tikboo" };

export default function TermsPage() {
  return <LegalDoc title="Terms of Service" body={TERMS_OF_SERVICE} />;
}
