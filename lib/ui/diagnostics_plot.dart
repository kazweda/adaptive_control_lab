import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'components/horizontal_scroll_chart.dart';

/// 残差を表示する簡易ラインチャート
class ResidualPlot extends StatelessWidget {
  final List<double> residual;
  final int maxDataPoints;
  final bool isRunning;
  final double scrollPosition;
  // スクロール位置変更コールバック
  final ValueChanged<double>? onScrollChanged;
  // 外側にCardを付けるか（タブ内などで既にCardに包まれている場合はfalse）
  final bool showCard;

  const ResidualPlot({
    super.key,
    required this.residual,
    required this.maxDataPoints,
    required this.isRunning,
    this.scrollPosition = 0.0,
    this.onScrollChanged,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    if (residual.isEmpty) {
      return _buildEmptyCard(
        title: '残差 e_rls(k)',
        message: 'STR/RLS有効時に残差が表示されます',
        showCard: showCard,
      );
    }

    final dataLength = residual.length;
    // x軸はステップ番号（1始まり）で表示するため、配列インデックス+1をxとする
    final spots = <FlSpot>[
      for (int i = 0; i < dataLength; i++)
        FlSpot((i + 1).toDouble(), residual[i]),
    ];

    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '残差 e_rls(k) = y(k) - ŷ(k)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          HorizontalScrollChart(
            totalSteps: dataLength,
            windowSteps: maxDataPoints,
            isRunning: isRunning,
            scrollStepPosition: scrollPosition,
            onScrollStepChanged: onScrollChanged,
            height: 160,
            chartBuilder: (visibleStart, visibleEnd) {
              final range = RangeValuesInt(visibleStart, visibleEnd);
              return LineChart(
                LineChartData(
                  minX: 1,
                  maxX: dataLength.toDouble(),
                  minY: _minY(residual, range) - 0.1,
                  maxY: _maxY(residual, range) + 0.1,
                  gridData: FlGridData(show: true, horizontalInterval: 0.2),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('誤差'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('ステップ'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 50,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Colors.deepPurple,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.grey[400],
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                ),
                duration: const Duration(milliseconds: 0),
              );
            },
          ),
        ],
      ),
    );
    return showCard ? Card(child: content) : content;
  }

  double _minY(List<double> data, RangeValuesInt range) {
    final values = data.sublist(range.start, range.end + 1);
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _maxY(List<double> data, RangeValuesInt range) {
    final values = data.sublist(range.start, range.end + 1);
    return values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildEmptyCard({
    required String title,
    required String message,
    bool showCard = true,
  }) {
    final content = Container(
      height: 160,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return showCard ? Card(child: content) : content;
  }
}

/// 推定パラメータのトレースを表示するチャート
class ParameterTracePlot extends StatelessWidget {
  final bool isSecondOrder;
  final int maxDataPoints;
  final bool isRunning;
  final double scrollPosition;

  // 推定値
  final List<double> estA;
  final List<double> estB;
  final List<double> estA1;
  final List<double> estA2;
  final List<double> estB1;
  final List<double> estB2;

  // 真値
  final List<double> actualA;
  final List<double> actualB;
  final List<double> actualA1;
  final List<double> actualA2;
  final List<double> actualB1;
  final List<double> actualB2;

  // スクロール位置変更コールバック
  final ValueChanged<double>? onScrollChanged;
  // 外側にCardを付けるか（タブ内などで既にCardに包まれている場合はfalse）
  final bool showCard;

  const ParameterTracePlot({
    super.key,
    required this.isSecondOrder,
    required this.maxDataPoints,
    required this.isRunning,
    this.scrollPosition = 0.0,
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
    this.onScrollChanged,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final dataLength = _effectiveLength();
    if (dataLength == 0) {
      return _buildEmptyCard(
        title: '推定パラメータトレース',
        message: 'STR/RLS有効時に推定パラメータが表示されます',
        showCard: showCard,
      );
    }

    // 凡例は表示範囲に関わらず固定（系列の色分け一覧のため、全データ長で1回だけ計算）
    final legendSeries = _buildSeries(
      dataLength,
      RangeValuesInt(0, dataLength - 1),
    );

    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '推定パラメータの時系列',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 6, children: legendSeries.legend),
          const SizedBox(height: 12),
          HorizontalScrollChart(
            totalSteps: dataLength,
            windowSteps: maxDataPoints,
            isRunning: isRunning,
            scrollStepPosition: scrollPosition,
            onScrollStepChanged: onScrollChanged,
            height: isSecondOrder ? 220 : 180,
            chartBuilder: (visibleStart, visibleEnd) {
              final series = _buildSeries(
                dataLength,
                RangeValuesInt(visibleStart, visibleEnd),
              );
              return LineChart(
                LineChartData(
                  minX: 1,
                  maxX: dataLength.toDouble(),
                  minY: series.minY - 0.1,
                  maxY: series.maxY + 0.1,
                  gridData: FlGridData(show: true, horizontalInterval: 0.2),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('係数'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('ステップ'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 50,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  lineBarsData: series.bars,
                ),
                duration: const Duration(milliseconds: 0),
              );
            },
          ),
        ],
      ),
    );
    return showCard ? Card(child: content) : content;
  }

  int _effectiveLength() {
    if (isSecondOrder) {
      return estA1.length;
    }
    return estA.length;
  }

  /// [fullLength]分の全スポットを構築しつつ、Y軸の最小/最大値は
  /// [visibleRange]（現在スクロールで見えている範囲）のみから計算する。
  ParameterSeries _buildSeries(int fullLength, RangeValuesInt visibleRange) {
    final bars = <LineChartBarData>[];
    final legend = <Widget>[];

    double minY = double.infinity;
    double maxY = -double.infinity;

    void addLine({
      required List<double> data,
      required Color color,
      required String label,
      List<int>? dashArray,
    }) {
      if (data.isEmpty) return;
      final spots = <FlSpot>[];
      // x軸はステップ番号（1始まり）で表示するため、配列インデックス+1をxとする
      for (int i = 0; i < fullLength && i < data.length; i++) {
        spots.add(FlSpot((i + 1).toDouble(), data[i]));
      }
      for (
        int i = visibleRange.start;
        i <= visibleRange.end && i < data.length;
        i++
      ) {
        final y = data[i];
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: color,
          barWidth: 2,
          dashArray: dashArray,
          dotData: const FlDotData(show: false),
        ),
      );
      legend.add(_legendItem(label: label, color: color, dashArray: dashArray));
    }

    if (isSecondOrder) {
      addLine(data: estA1, color: Colors.blue, label: 'â1');
      addLine(data: estA2, color: Colors.lightBlue, label: 'â2');
      addLine(data: estB1, color: Colors.green, label: 'b̂1');
      addLine(data: estB2, color: Colors.teal, label: 'b̂2');
      addLine(
        data: actualA1,
        color: Colors.grey,
        label: 'a1(true)',
        dashArray: [6, 4],
      );
      addLine(
        data: actualA2,
        color: Colors.grey.shade600,
        label: 'a2(true)',
        dashArray: [6, 4],
      );
      addLine(
        data: actualB1,
        color: Colors.brown,
        label: 'b1(true)',
        dashArray: [6, 4],
      );
      addLine(
        data: actualB2,
        color: Colors.brown.shade300,
        label: 'b2(true)',
        dashArray: [6, 4],
      );
    } else {
      addLine(data: estA, color: Colors.blue, label: 'â');
      addLine(data: estB, color: Colors.green, label: 'b̂');
      addLine(
        data: actualA,
        color: Colors.grey,
        label: 'a(true)',
        dashArray: [6, 4],
      );
      addLine(
        data: actualB,
        color: Colors.brown,
        label: 'b(true)',
        dashArray: [6, 4],
      );
    }

    if (minY == double.infinity) {
      minY = -1;
      maxY = 1;
    }

    return ParameterSeries(bars: bars, legend: legend, minY: minY, maxY: maxY);
  }

  Widget _legendItem({
    required String label,
    required Color color,
    List<int>? dashArray,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: dashArray == null ? color : Colors.transparent,
            border: dashArray == null
                ? null
                : Border.all(color: color, width: 2, style: BorderStyle.solid),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildEmptyCard({
    required String title,
    required String message,
    bool showCard = true,
  }) {
    final content = Container(
      height: 180,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return showCard ? Card(child: content) : content;
  }
}

class RangeValuesInt {
  final int start;
  final int end;
  RangeValuesInt(this.start, this.end);
}

class ParameterSeries {
  final List<LineChartBarData> bars;
  final List<Widget> legend;
  final double minY;
  final double maxY;

  ParameterSeries({
    required this.bars,
    required this.legend,
    required this.minY,
    required this.maxY,
  });
}
