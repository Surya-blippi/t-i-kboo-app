import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dev/screenshot_demo.dart';
import '../services/chat_parser.dart';
import '../services/ios_share_channel.dart';
import '../services/stats_engine.dart';
import 'results_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import '../widgets/chunky_button.dart';
import 'context_screen.dart';
import 'history_screen.dart';
import 'how_to_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  @override
  void initState() {
    super.initState();
    _initShareListening();
    if (ScreenshotDemo.enabled) {
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultsScreen(
            stats: ScreenshotDemo.stats(),
            analysis: ScreenshotDemo.analysis,
            otherName: ScreenshotDemo.otherName,
            forcePro: true,
            autoAdvance: true,
          ),
        ));
      });
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  /// Listen for chats shared INTO tikboo from WhatsApp's "Export Chat" sheet.
  void _initShareListening() {
    // iOS: chats arrive via the native document-open channel.
    if (Platform.isIOS) {
      IosShareChannel.init(_handleSharedPath);
    }
    // Android: receive_sharing_intent (intent-filter SEND/VIEW).
    if (Platform.isAndroid) {
      _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handleShared,
        onError: (_) {},
      );
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handleShared(files);
        ReceiveSharingIntent.instance.reset();
      });
    }
  }

  Future<void> _handleShared(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    await _handleSharedPath(files.first.path);
  }

  Future<void> _handleSharedPath(String path) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      String raw;
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        raw = ChatParser.extractText(bytes, path);
      } else {
        // Small chats are shared as plain text rather than a file.
        raw = path;
      }
      await _runStats(raw, fileName: path);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _pickAndAnalyze() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw const FormatException('Could not read that file.');

      final raw = ChatParser.extractText(bytes, file.name);
      await _runStats(raw, fileName: file.name);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _runStats(String raw, {String? fileName}) async {
    final messages = ChatParser.parse(raw);
    final stats = StatsEngine.compute(messages);
    final otherName = ChatParser.resolveOtherPerson(
        stats.people.map((p) => p.name).toList(), fileName);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ContextScreen(stats: stats, otherName: otherName)),
    );
  }

  Future<void> _openWhatsApp() async {
    // Opens WhatsApp so the user can Export Chat → share back into tikboo.
    final uri = Uri.parse('whatsapp://app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: App Store / web.
      await launchUrl(Uri.parse('https://wa.me'),
          mode: LaunchMode.externalApplication);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.inkCard,
        content: Text(msg, style: AppTheme.body(14, color: AppColors.textHi)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Logo(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen()),
                          ),
                          icon: const Icon(Icons.history_rounded,
                              color: AppColors.textMid),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                          icon: const Icon(Icons.settings_rounded,
                              color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text('YOUR CHAT,', style: AppTheme.display(46, height: 1.02))
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                Text('DECODED.',
                        style: AppTheme.display(46,
                            color: AppColors.lime, height: 1.02))
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 18),
                Text(
                  'Open WhatsApp, hit Export Chat, and send it to tikboo. Get a Wrapped-style breakdown plus an AI vibe check. The receipts are receipt-ing.',
                  style: AppTheme.body(16, height: 1.5),
                ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
                const SizedBox(height: 28),
                const _StepRow(),
                const Spacer(),
                ChunkyButton(
                  label: _busy ? 'READING…' : 'OPEN WHATSAPP',
                  icon: _busy ? null : Icons.ios_share_rounded,
                  loading: _busy,
                  onTap: _busy ? null : _openWhatsApp,
                ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 12),
                ChunkyButton(
                  label: 'IMPORT A FILE INSTEAD',
                  icon: Icons.folder_open_rounded,
                  color: AppColors.inkCard,
                  onTap: _busy ? null : _pickAndAnalyze,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => showHowToSheet(context),
                    child: Text('how do I export a chat?',
                        style: AppTheme.body(14,
                            color: AppColors.textMid,
                            weight: FontWeight.w700)),
                  ),
                ),
                Center(
                  child: Text('🔒 analyzed securely · never stored or sold',
                      style: AppTheme.body(12, color: AppColors.textLow)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/brand/logo.png', width: 38, height: 38),
        const SizedBox(width: 8),
        Text('tikboo', style: AppTheme.display(22, weight: FontWeight.w800)),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', 'Export', AppColors.pink),
      ('2', 'Import', AppColors.violet),
      ('3', 'Get read', AppColors.cyan),
    ];
    return Row(
      children: [
        for (final s in steps) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.inkCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                children: [
                  Text(s.$1,
                      style: AppTheme.display(22, color: s.$3)),
                  const SizedBox(height: 4),
                  Text(s.$2,
                      style: AppTheme.body(12,
                          color: AppColors.textMid, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          if (s.$1 != '3') const SizedBox(width: 10),
        ],
      ],
    );
  }
}
