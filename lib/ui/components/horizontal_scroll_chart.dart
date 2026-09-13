import 'package:flutter/material.dart';

/// チャートを横方向にネイティブスクロールできる形で表示する共通ウィジェット
///
/// 実行中は最新データに自動追従し、停止中はドラッグ/スクロールバーで
/// 任意のステップ範囲を閲覧できる。fl_chart側は常に全データ（[0, totalSteps-1]）
/// を描画し、このウィジェットが横幅とスクロール位置で見える範囲を制御する。
class HorizontalScrollChart extends StatefulWidget {
  // データ全体のステップ数
  final int totalSteps;
  // 一度に見える幅（ズーム量。現行のmaxDataPointsに相当）
  final int windowSteps;
  // シミュレーション実行中フラグ（実行中は自動追従、手動スクロール不可）
  final bool isRunning;
  // 外部から指定される先頭ステップ位置
  final double scrollStepPosition;
  // スクロール位置変更コールバック（先頭ステップ位置を返す）
  final ValueChanged<double>? onScrollStepChanged;
  final double height;
  // 現在の可視範囲（Y軸スケール計算用）を受け取ってチャート本体を構築する
  final Widget Function(int visibleStart, int visibleEnd) chartBuilder;

  const HorizontalScrollChart({
    super.key,
    required this.totalSteps,
    required this.windowSteps,
    required this.isRunning,
    required this.scrollStepPosition,
    this.onScrollStepChanged,
    required this.height,
    required this.chartBuilder,
  });

  @override
  State<HorizontalScrollChart> createState() => _HorizontalScrollChartState();
}

class _HorizontalScrollChartState extends State<HorizontalScrollChart> {
  final ScrollController _scrollController = ScrollController();
  double? _pixelsPerStep;
  int _visibleStart = 0;
  int _visibleEnd = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant HorizontalScrollChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollPosition());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.isRunning) return;
    final pixelsPerStep = _pixelsPerStep;
    if (pixelsPerStep == null || pixelsPerStep <= 0) return;

    final step = _scrollController.offset / pixelsPerStep;
    widget.onScrollStepChanged?.call(step);
    _updateVisibleRange();
  }

  void _updateVisibleRange() {
    final range = _computeVisibleRange();
    if (range.$1 != _visibleStart || range.$2 != _visibleEnd) {
      setState(() {
        _visibleStart = range.$1;
        _visibleEnd = range.$2;
      });
    }
  }

  (int, int) _computeVisibleRange() {
    final total = widget.totalSteps;
    if (total <= 1) return (0, (total - 1).clamp(0, total));
    final window = widget.windowSteps < 1 ? 1 : widget.windowSteps;

    if (widget.isRunning) {
      final win = window >= total ? total : window;
      final start = total - win;
      return (start, total - 1);
    }

    final pixelsPerStep = _pixelsPerStep;
    final maxStart = (total - window).clamp(0, total - 1);
    final start = pixelsPerStep == null || pixelsPerStep <= 0
        ? widget.scrollStepPosition.round().clamp(0, maxStart)
        : (_scrollController.hasClients
                  ? _scrollController.offset / pixelsPerStep
                  : widget.scrollStepPosition)
              .round()
              .clamp(0, maxStart);
    final end = (start + window - 1).clamp(0, total - 1);
    return (start, end);
  }

  void _syncScrollPosition() {
    if (!_scrollController.hasClients || _pixelsPerStep == null) return;
    final pixelsPerStep = _pixelsPerStep!;
    final maxExtent = _scrollController.position.maxScrollExtent;

    if (widget.isRunning) {
      if ((_scrollController.offset - maxExtent).abs() > 0.5) {
        _scrollController.jumpTo(maxExtent);
      }
    } else {
      final target = (widget.scrollStepPosition * pixelsPerStep).clamp(
        0.0,
        maxExtent,
      );
      if ((_scrollController.offset - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    }
    _updateVisibleRange();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final window = widget.windowSteps < 1 ? 1 : widget.windowSteps;
        final total = widget.totalSteps < 1 ? 1 : widget.totalSteps;
        _pixelsPerStep = viewportWidth / window;
        final totalWidth = (_pixelsPerStep! * total).clamp(
          viewportWidth,
          double.infinity,
        );

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncScrollPosition(),
        );

        final range = _computeVisibleRange();
        _visibleStart = range.$1;
        _visibleEnd = range.$2;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: widget.isRunning
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: widget.height,
              child: widget.chartBuilder(_visibleStart, _visibleEnd),
            ),
          ),
        );
      },
    );
  }
}
