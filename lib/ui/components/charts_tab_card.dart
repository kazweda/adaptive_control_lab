import 'package:flutter/material.dart';
import '../plot.dart';
import '../diagnostics_plot.dart';

/// 時系列・残差・推定パラメータの3チャートを1枚のカードでタブ切替表示する
///
/// 従来は3枚のチャートを縦に並べていたため画面が間延びしていたが（Issue #65）、
/// タブ切替にまとめることでスクロール量を大幅に削減する。
class ChartsTabCard extends StatefulWidget {
  final List<double> historyTarget;
  final List<double> historyOutput;
  final List<double> historyControl;
  final List<double> historyResidual;
  final int maxDataPoints;
  final bool isRunning;
  final double scrollPosition;
  final ValueChanged<double>? onScrollChanged;

  final bool isSecondOrderPlant;
  final List<double> estA;
  final List<double> estB;
  final List<double> estA1;
  final List<double> estA2;
  final List<double> estB1;
  final List<double> estB2;
  final List<double> actualA;
  final List<double> actualB;
  final List<double> actualA1;
  final List<double> actualA2;
  final List<double> actualB1;
  final List<double> actualB2;

  const ChartsTabCard({
    super.key,
    required this.historyTarget,
    required this.historyOutput,
    required this.historyControl,
    required this.historyResidual,
    required this.maxDataPoints,
    required this.isRunning,
    required this.scrollPosition,
    this.onScrollChanged,
    required this.isSecondOrderPlant,
    required this.estA,
    required this.estB,
    required this.estA1,
    required this.estA2,
    required this.estB1,
    required this.estB2,
    required this.actualA,
    required this.actualB,
    required this.actualA1,
    required this.actualA2,
    required this.actualB1,
    required this.actualB2,
  });

  @override
  State<ChartsTabCard> createState() => _ChartsTabCardState();
}

class _ChartsTabCardState extends State<ChartsTabCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '時系列'),
              Tab(text: '残差'),
              Tab(text: '推定パラメータ'),
            ],
          ),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: TimeSeriesPlot(
                    historyTarget: widget.historyTarget,
                    historyOutput: widget.historyOutput,
                    historyControl: widget.historyControl,
                    maxDataPoints: widget.maxDataPoints,
                    isRunning: widget.isRunning,
                    scrollPosition: widget.scrollPosition,
                    onScrollChanged: widget.onScrollChanged,
                    showCard: false,
                  ),
                ),
                SingleChildScrollView(
                  child: ResidualPlot(
                    residual: widget.historyResidual,
                    maxDataPoints: widget.maxDataPoints,
                    isRunning: widget.isRunning,
                    scrollPosition: widget.scrollPosition,
                    showCard: false,
                  ),
                ),
                SingleChildScrollView(
                  child: ParameterTracePlot(
                    isSecondOrder: widget.isSecondOrderPlant,
                    maxDataPoints: widget.maxDataPoints,
                    isRunning: widget.isRunning,
                    scrollPosition: widget.scrollPosition,
                    estA: widget.estA,
                    estB: widget.estB,
                    estA1: widget.estA1,
                    estA2: widget.estA2,
                    estB1: widget.estB1,
                    estB2: widget.estB2,
                    actualA: widget.actualA,
                    actualB: widget.actualB,
                    actualA1: widget.actualA1,
                    actualA2: widget.actualA2,
                    actualB1: widget.actualB1,
                    actualB2: widget.actualB2,
                    showCard: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
