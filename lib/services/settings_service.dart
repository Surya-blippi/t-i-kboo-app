import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's OpenRouter API key + chosen free model locally.
class SettingsService {
  static const _kKey = 'openrouter_api_key';
  static const _kModel = 'openrouter_model';

  /// Curated list of solid free models on OpenRouter.
  /// (`:free` variants cost $0 — great default for this app.)
  static const List<FreeModel> freeModels = [
    FreeModel('openai/gpt-oss-120b:free', 'GPT-OSS 120B',
        'Smart + clean JSON. Best default.'),
    FreeModel('meta-llama/llama-3.3-70b-instruct:free', 'Llama 3.3 70B',
        'Punchy roasts. Can be busy.'),
    FreeModel('qwen/qwen3-next-80b-a3b-instruct:free', 'Qwen3 Next 80B',
        'Fast + sharp reasoning.'),
    FreeModel('google/gemma-4-31b-it:free', 'Gemma 4 31B',
        'Lightweight + speedy.'),
  ];

  static const defaultModel = 'openai/gpt-oss-120b:free';

  /// Bundled key so the app runs out of the box for dev/personal use.
  /// NOTE: a key shipped in app source can be extracted from the build —
  /// rotate it (openrouter.ai/keys) before any public distribution, and
  /// prefer the user-entered key in Settings, which always wins.
  static const _bundledKey =
      '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';

  Future<String?> getApiKey() async {
    final p = await SharedPreferences.getInstance();
    final k = p.getString(_kKey);
    if (k != null && k.trim().isNotEmpty) return k.trim();
    return _bundledKey.isEmpty ? null : _bundledKey;
  }

  Future<void> setApiKey(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kKey, key.trim());
  }

  Future<void> clearApiKey() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kKey);
  }

  Future<String> getModel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kModel) ?? defaultModel;
  }

  Future<void> setModel(String model) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kModel, model);
  }
}

class FreeModel {
  final String id;
  final String label;
  final String blurb;
  const FreeModel(this.id, this.label, this.blurb);
}
