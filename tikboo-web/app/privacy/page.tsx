import type { Metadata } from "next";
import { LegalDoc } from "@/components/LegalDoc";
import { PRIVACY_POLICY } from "@/lib/legal";

export const metadata: Metadata = { title: "Privacy Policy — tikboo" };

export default function PrivacyPage() {
  return <LegalDoc title="Privacy Policy" body={PRIVACY_POLICY} />;
}
