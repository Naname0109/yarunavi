import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/sound_provider.dart';
import '../services/ai_service.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/responsive_wrapper.dart';
import 'home_screen.dart'
    show AllCompleteCelebration, ConfettiPainter, PulsingPrimaryButton;

/// 開発者モード専用: アニメーション/演出のプレビュー画面
///
/// 各演出を独立に再生して、本番フローを走らせずにマイクロインタラクションを
/// 調整できる。リリースビルドには出さない想定。
class DebugAnimationsScreen extends ConsumerStatefulWidget {
  const DebugAnimationsScreen({super.key});

  @override
  ConsumerState<DebugAnimationsScreen> createState() =>
      _DebugAnimationsScreenState();
}

class _DebugAnimationsScreenState extends ConsumerState<DebugAnimationsScreen> {
  int _taskCount = 7;
  AiErrorType _errorType = AiErrorType.network;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sound = ref.watch(soundServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('演出プレビュー')),
      body: ResponsiveWrapper(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _Section(
              title: 'AI整理プログレス + 完了演出',
              description:
                  'AIリクエスト→受信→DB保存→完了 を1往復シミュレート。タスク数に応じて awaiting フェーズが 5/8/12 秒に切り替わります。',
              children: [
                Row(
                  children: [
                    Text('タスク数: ',
                        style: theme.textTheme.bodyMedium),
                    Expanded(
                      child: Slider(
                        value: _taskCount.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '$_taskCount件',
                        onChanged: (v) => setState(() => _taskCount = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('$_taskCount件',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                Text(
                  _awaitingDescription(_taskCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showAiSortPreviewDialog(
                    context,
                    l10n: l10n,
                    taskCount: _taskCount,
                    sound: sound,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('成功シナリオを再生'),
                ),
              ],
            ),
            _Section(
              title: 'AI整理エラー演出',
              description:
                  '赤色フェードアウト + エラーダイアログ。レート制限/ネットワーク/APIエラーを切り替えて確認。',
              children: [
                SegmentedButton<AiErrorType>(
                  segments: const [
                    ButtonSegment(
                      value: AiErrorType.network,
                      label: Text('ネットワーク'),
                    ),
                    ButtonSegment(
                      value: AiErrorType.parse,
                      label: Text('API'),
                    ),
                    ButtonSegment(
                      value: AiErrorType.rateLimit,
                      label: Text('レート制限'),
                    ),
                  ],
                  selected: {_errorType},
                  onSelectionChanged: (set) =>
                      setState(() => _errorType = set.first),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showAiSortPreviewDialog(
                    context,
                    l10n: l10n,
                    taskCount: _taskCount,
                    simulateError: _errorType,
                    sound: sound,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('エラー演出を再生'),
                ),
              ],
            ),
            _Section(
              title: '全タスク完了画面',
              description:
                  '紙吹雪 + チェックマーク (光彩リング) + パルスボタン + 「AIで整理」ボタン。全画面で再生。',
              children: [
                FilledButton.icon(
                  onPressed: () => _openAllCompleteFullScreen(context, l10n),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('全完了画面を全画面で再生'),
                ),
              ],
            ),
            _Section(
              title: 'バースト単独 (中央発火)',
              description: '中央フラッシュ + 円14 / 4方向スパークル10 / 光の筋6 を再生。',
              children: [
                FilledButton.icon(
                  onPressed: () => _openBurstStandalone(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('バースト単独を再生'),
                ),
              ],
            ),
            _Section(
              title: '紙吹雪単独 (3秒)',
              description: '物理ベース軌跡 (重力+横ドリフト+sin揺れ)、3形状/5色。',
              children: [
                FilledButton.icon(
                  onPressed: () => _openConfettiStandalone(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('紙吹雪単独を再生'),
                ),
              ],
            ),
            _Section(
              title: 'パルスボタン (常時表示)',
              description: 'グロウシャドウ + scale の脈動を 2秒周期でループ再生。',
              children: [
                const _PulseButtonDemo(),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _awaitingDescription(int count) {
    if (count <= 5) return '→ awaiting フェーズ 5 秒';
    if (count <= 10) return '→ awaiting フェーズ 8 秒';
    return '→ awaiting フェーズ 12 秒';
  }

  Future<void> _openAllCompleteFullScreen(
      BuildContext context, AppLocalizations l10n) async {
    final theme = Theme.of(context);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('全完了プレビュー'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
        body: AllCompleteCelebration(l10n: l10n),
      ),
    ));
  }

  Future<void> _openBurstStandalone(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => const _BurstStandalonePage(),
    ));
  }

  Future<void> _openConfettiStandalone(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => const _ConfettiStandalonePage(),
    ));
  }
}

/// セクション枠
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// バーストを画面中央でループ再生するページ
class _BurstStandalonePage extends StatefulWidget {
  const _BurstStandalonePage();

  @override
  State<_BurstStandalonePage> createState() => _BurstStandalonePageState();
}

class _BurstStandalonePageState extends State<_BurstStandalonePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _replay();
  }

  void _replay() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? Colors.white
        : theme.colorScheme.tertiary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('バースト単独'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'リプレイ',
            icon: const Icon(Icons.replay),
            onPressed: _replay,
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTap: _replay,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(280, 280),
                  painter: AiSortBurstPainter(
                    progress: _controller.value,
                    primaryColor: theme.colorScheme.primary,
                    goldColor: kAiGoldColor,
                    accentColor: accent,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _replay,
        icon: const Icon(Icons.replay),
        label: const Text('もう一度'),
      ),
    );
  }
}

/// 紙吹雪を全画面で再生するページ
class _ConfettiStandalonePage extends StatefulWidget {
  const _ConfettiStandalonePage();

  @override
  State<_ConfettiStandalonePage> createState() =>
      _ConfettiStandalonePageState();
}

class _ConfettiStandalonePageState extends State<_ConfettiStandalonePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _replay();
  }

  void _replay() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('紙吹雪単独'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'リプレイ',
            icon: const Icon(Icons.replay),
            onPressed: _replay,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              '画面をタップ or 右上アイコンでリプレイ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _replay,
              child: IgnorePointer(
                ignoring: false,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: ConfettiPainter(
                          progress: _controller.value,
                          primaryColor: theme.colorScheme.primary,
                          secondaryColor: theme.colorScheme.secondary,
                          tertiaryColor: theme.colorScheme.tertiary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// パルスボタン単独デモ (常時ループ)
class _PulseButtonDemo extends StatefulWidget {
  const _PulseButtonDemo();

  @override
  State<_PulseButtonDemo> createState() => _PulseButtonDemoState();
}

class _PulseButtonDemoState extends State<_PulseButtonDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: PulsingPrimaryButton(
          pulseController: _pulseController,
          primaryColor: theme.colorScheme.primary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('パルスボタンタップ'),
                duration: Duration(milliseconds: 800),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          label: 'タスクを追加する',
        ),
      ),
    );
  }
}

