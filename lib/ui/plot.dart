import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 時系列グラフウィジェット
///
/// 目標値・プラント出力・制御入力をリアルタイムで表示
class TimeSeriesPlot extends StatelessWidget {
  final List<double> historyTarget;
  final List<double> historyOutput;
  final List<double> historyControl;
  // null の場合は全履歴表示
  final int? maxDataPoints;

  const TimeSeriesPlot({
    super.key,
    required this.historyTarget,
    required this.historyOutput,
    required this.historyControl,
    this.maxDataPoints = 200,
  });

  @override
  Widget build(BuildContext context) {
    // データが空または不整合な場合は説明を表示
    final bool hasEmptyData =
        historyTarget.isEmpty ||
        historyOutput.isEmpty ||
        historyControl.isEmpty;
    final bool hasInconsistentLength =
        historyTarget.length != historyOutput.length ||
        historyTarget.length != historyControl.length;

    if (hasEmptyData || hasInconsistentLength) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'スタートボタンを押すと\nグラフが表示されます',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // グラフタイトルと凡例
            _buildLegend(),
            const SizedBox(height: 16),

            // グラフ本体
            SizedBox(
              height: 300,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                panEnabled: true,
                scaleEnabled: true,
                child: LineChart(
                  _buildLineChartData(),
                  duration: const Duration(milliseconds: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 凡例を構築
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('目標値', Colors.blue),
        _buildLegendItem('出力', Colors.red),
        _buildLegendItem('制御入力', Colors.green),
      ],
    );
  }

  /// 凡例アイテムを構築
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  /// グラフデータを構築
  LineChartData _buildLineChartData() {
    final windowSize = maxDataPoints ?? historyTarget.length;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 0.5,
        verticalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'ステップ数',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            '値',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.5,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[400]!),
      ),
      minX: 0,
      maxX: (windowSize <= 0 ? 0 : windowSize).toDouble(),
      minY: _calculateMinY(),
      maxY: _calculateMaxY(),
      lineBarsData: [
        _buildLineChartBarData(historyTarget, Colors.blue),
        _buildLineChartBarData(historyOutput, Colors.red),
        _buildLineChartBarData(historyControl, Colors.green),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String label = '';
              Color color = spot.bar.color ?? Colors.black;

              if (spot.barIndex == 0) {
                label = '目標値';
              } else if (spot.barIndex == 1) {
                label = '出力';
              } else if (spot.barIndex == 2) {
                label = '制御入力';
              }

              return LineTooltipItem(
                '$label\n${spot.y.toStringAsFixed(3)}',
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// 線グラフのバーデータを構築
  LineChartBarData _buildLineChartBarData(List<double> data, Color color) {
    final spots = <FlSpot>[];

    final windowSize = maxDataPoints ?? data.length;
    // データポイントの開始位置を計算（最新データを右端に表示）
    final startIndex = data.length > windowSize ? data.length - windowSize : 0;

    final points = windowSize.clamp(0, data.length);
    for (int i = 0; i < points; i++) {
      final dataIndex = startIndex + i;
      if (dataIndex >= data.length) break;
      final x = i.toDouble();
      final y = data[dataIndex];
      spots.add(FlSpot(x, y));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: false, // 折れ線（シンプルで分かりやすい）
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false), // ドットは非表示（見やすさ優先）
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Y軸の最小値を計算
  double _calculateMinY() {
    if (historyTarget.isEmpty &&
        historyOutput.isEmpty &&
        historyControl.isEmpty) {
      return -1.0;
    }

    final allValues = [...historyTarget, ...historyOutput, ...historyControl];
    final minValue = allValues.reduce((a, b) => a < b ? a : b);

    // 少し余裕を持たせる
    return (minValue - 0.5).floorToDouble();
  }

  /// Y軸の最大値を計算
  double _calculateMaxY() {
    if (historyTarget.isEmpty &&
        historyOutput.isEmpty &&
        historyControl.isEmpty) {
      return 2.0;
    }

    final allValues = [...historyTarget, ...historyOutput, ...historyControl];
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);

    // 少し余裕を持たせる
    return (maxValue + 0.5).ceilToDouble();
  }
}
