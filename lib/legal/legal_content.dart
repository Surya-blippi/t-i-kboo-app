/// In-app legal content, rendered by LegalScreen with tikboo's styling.
/// Lightweight markup the renderer understands:
///   "## "  -> section heading
///   "- "   -> bullet
///   blank  -> spacing
///   else   -> paragraph
///
/// Public copies (for App Store Connect submission fields):
///   Privacy Policy: https://docs.google.com/document/d/12Qlw2GmBxqCSCbZWH71X182lVXmnjsKRzRl16fIFBOo/edit?usp=sharing
///   Terms of Service: https://docs.google.com/document/d/1t5W0B_vZDCrd9rPleMNrVTr-jZg7PB0qyHswvzT_T9k/edit?usp=sharing
class LegalContent {
  LegalContent._();

  static const String privacyUrl =
      'https://docs.google.com/document/d/12Qlw2GmBxqCSCbZWH71X182lVXmnjsKRzRl16fIFBOo/edit?usp=sharing';
  static const String termsUrl =
      'https://docs.google.com/document/d/1t5W0B_vZDCrd9rPleMNrVTr-jZg7PB0qyHswvzT_T9k/edit?usp=sharing';

  static const String effectiveDate = '15 June 2026';

  static const String privacyPolicy = '''
Effective date: $effectiveDate

tikboo analyzes a WhatsApp chat export you choose to import and returns a playful, Wrapped-style summary plus an AI vibe check. This policy explains what we handle and how. By using tikboo, you agree to this policy.

## 1. What we process
- Chat content you import: messages, participant names, timestamps, emoji and media markers from the export you bring in.
- Context you provide: the gender and relationship type you select for an analysis.
- Purchase status: whether you hold an active subscription (handled by Apple and RevenueCat). We do not receive your full payment details.

We do not collect your contacts, location, photos, or device identifiers for advertising. tikboo has no account or login.

## 2. How your chat is used
- On your device: parsing and the statistical breakdown (counts, timing, emoji, streaks) happen locally on your phone.
- Sent to our AI provider: to generate the AI part of your report, a sample of messages and aggregate statistics are sent to OpenRouter, which routes the request to a third-party language model, solely to produce your report. We do not train models on your messages and we do not sell them.
- We do not operate servers that store your chats. The sample is processed transiently and is not retained by us.

## 3. What is stored, and where
- Locally on your device: your completed reports (history), your selected AI model, and (if entered) your OpenRouter API key. You can delete any report by swiping it in History, and remove all local data by uninstalling the app.
- We keep no copy of your chats or reports on our own infrastructure.

## 4. Third-party services
- OpenRouter — AI processing of your message sample — openrouter.ai/privacy
- Apple — subscription billing and app distribution — apple.com/legal/privacy
- RevenueCat — subscription management — revenuecat.com/privacy

## 5. Sharing
We do not sell, rent, or share your personal data for third-party marketing. Data is shared only with the processors above, only to operate the app. When you tap Share to Story, you share the generated image through your device's share sheet to a destination you choose.

## 6. Data retention and your choices
- Reports stay on your device until you delete them or uninstall the app.
- We store nothing server-side, so there is no account for us to delete; uninstalling removes local data.
- Only import chats you have the right to analyze.

## 7. Security
We use reputable providers and encrypted (HTTPS) connections for data in transit. No method is 100% secure, but we take reasonable measures to protect your information.

## 8. Children
tikboo is not directed to children under 13 (or the minimum age of digital consent in your country). If you are under that age, please do not use the app.

## 9. Changes
We may update this policy. Material changes will be reflected by updating the effective date above and, where appropriate, an in-app notice.

## 10. Contact
Questions about privacy? Contact us at abhay.k.gupta01@gmail.com.
''';

  static const String termsOfService = '''
Effective date: $effectiveDate

These Terms govern your use of the tikboo app. By downloading or using tikboo, you agree to these Terms. If you do not agree, do not use the app.

## 1. Eligibility
You must be at least 13 years old (or the minimum age of digital consent in your country) to use tikboo. If you are under the age of majority where you live, use tikboo only with the involvement of a parent or guardian.

## 2. What tikboo is
tikboo analyzes a WhatsApp chat export you provide and produces a playful, Wrapped-style summary and an AI-generated vibe check (stats, flags, and a light roast). tikboo is for entertainment only. The AI output is automatically generated, may be inaccurate or wrong, and is not advice of any kind — relationship, psychological, legal, financial, or otherwise. Do not make decisions based on it.

## 3. Your responsibilities
- Only import chats you have the right to. A conversation involves other people; you are responsible for ensuring you may analyze that content and for respecting others' privacy.
- Do not use tikboo to harass, defame, or harm anyone.
- Do not misuse, reverse engineer, or attempt to disrupt the app or its providers.

## 4. AI processing
To generate the AI portion of your report, a sample of your chat messages and statistics is sent to our AI provider (OpenRouter) and an underlying language model. See our Privacy Policy for details. AI outputs are probabilistic and provided as is.

## 5. Subscriptions, billing and cancellation
- tikboo offers auto-renewable subscriptions (tikboo Pro) that unlock the full report.
- Payment is charged to your Apple ID at confirmation of purchase.
- Subscriptions renew automatically for the same period and price unless cancelled at least 24 hours before the end of the current period.
- Any free trial converts to a paid subscription unless cancelled at least 24 hours before the trial ends. Unused trial time is forfeited when you buy a subscription.
- Manage or cancel anytime in your Apple ID account settings (App Store, your account, Subscriptions).
- Purchases and refunds are handled by Apple and subject to Apple's Media Services Terms and standard EULA. Except where required by law, payments are non-refundable.
- Subscription management and entitlements are facilitated by RevenueCat.

## 6. Intellectual property
tikboo, its design, branding, and software are owned by us and protected by law. Reports you generate are for personal use; the "Made with tikboo" mark remains on shared cards.

## 7. Disclaimers
tikboo is provided "as is" and "as available", without warranties of any kind, express or implied, including fitness for a particular purpose, accuracy, or non-infringement. We do not warrant that the app or its AI output will be accurate, reliable, or uninterrupted.

## 8. Limitation of liability
To the maximum extent permitted by law, we are not liable for any indirect, incidental, special, consequential, or punitive damages, or for any loss arising from your use of the app or reliance on its output. Our total liability for any claim is limited to the amount you paid us in the 12 months before the claim (or, if you paid nothing, INR 0).

## 9. Termination
We may suspend or discontinue the app, or your access, at any time. You may stop using tikboo at any time; uninstalling removes its local data from your device.

## 10. Governing law
These Terms are governed by the laws of India, without regard to conflict-of-laws rules. Disputes will be subject to the courts of Kanpur, Uttar Pradesh.

## 11. Changes
We may update these Terms. Continued use after changes means you accept the updated Terms.

## 12. Contact
Questions about these Terms? Contact us at abhay.k.gupta01@gmail.com.
''';
}
