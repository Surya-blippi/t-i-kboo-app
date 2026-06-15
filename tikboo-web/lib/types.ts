export interface ChatMessage {
  timestamp: Date;
  sender: string;
  text: string;
  isMedia: boolean;
  isSystem: boolean;
  wordCount: number;
}

export interface PersonStats {
  name: string;
  messages: number;
  words: number;
  emojis: number;
  media: number;
  questions: number;
  laughs: number;
  conversationsStarted: number;
  topEmojis: [string, number][];
  topWords: string[];
  avgReplyMinutes: number | null;
}

export interface ChatStats {
  isGroup: boolean;
  people: PersonStats[];
  totalMessages: number;
  spanDays: number;
  activeDays: number;
  longestStreakDays: number;
  peakHour: number;
  topEmojiOverall: string;
  totalEmojis: number;
  totalMedia: number;
  busiestDayLabel: string;
  firstSender: string;
  firstText: string;
  firstDateTime: string;
  longestSender: string;
  longestText: string;
  longestWords: number;
  sampleLines: string[];
}

export type Subject = "girl" | "guy" | "group";

export interface ChatContext {
  subject: Subject;
  relationship: string;
  otherName: string;
}

export interface FlagItem {
  flag: string;
  quote: string;
  sender: string;
}

export interface AiSuperlative {
  emoji: string;
  title: string;
  person: string;
  reason: string;
}

export interface AiAnalysis {
  vibeTitle: string;
  vibeEmoji: string;
  summary: string;
  roast: string;
  energyMatch: string;
  whoTextsFirst: string;
  attachmentStyle: string;
  firstTextRead: string;
  greenFlags: FlagItem[];
  redFlags: FlagItem[];
  superlatives: AiSuperlative[];
  vibeScore: number;
}
