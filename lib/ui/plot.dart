import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 時系列グラフウィジェット
///
/// 目標値・プラント出力・制御入力をリアルタイムで表示
/// 停止時は水平スクロールバーで全データを閲覧可能
class TimeSeriesPlot extends StatefulWidget {
  final List<double> historyTarget;
  final List<double> historyOutput;
  final List<double> historyControl;
  // 表示するデータ点数（X軸の幅）
  final int maxDataPoints;
  // シミュレーション実行中フラグ（停止時はスクロール可能に）
  final bool isRunning;

  const TimeSeriesPlot({
    super.key,
    required this.historyTarget,
    required this.historyOutput,
    required this.historyControl,
    this.maxDataPoints = 200,
    this.isRunning = false,
  });

  @override
  State<TimeSeriesPlot> createState() => _TimeSeriesPlotState();
}

class _TimeSeriesPlotState extends State<TimeSeriesPlot> {
  // 停止時のスクロール位置（0 = 最初のデータから開始）
  late double scrollPosition;

  @override
  void initState() {
    super.initState();
    scrollPosition = 0.0;
  }

  @override
  void didUpdateWidget(TimeSeriesPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // データが追加された場合、停止時は最新データが見えるようスクロール位置を更新
    if (!widget.isRunning &&
        widget.historyTarget.length > oldWidget.historyTarget.length) {
      final maxScrollPosition =
          (widget.historyTarget.length - widget.maxDataPoints).toDouble();
      if (maxScrollPosition > 0) {
        scrollPosition = maxScrollPosition;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // データが空または不整合な場合は説明を表示
    final bool hasEmptyData =
        widget.historyTarget.isEmpty ||
        widget.historyOutput.isEmpty ||
        widget.historyControl.isEmpty;
    final bool hasInconsistentLength =
        widget.historyTarget.length != widget.historyOutput.length ||
        widget.historyTarget.length != widget.historyControl.length;

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

    // スクロール位置を制限（停止時）
    final int dataLength = widget.historyTarget.length;
    final int maxScrollPosition = (dataLength - widget.maxDataPoints).clamp(
      0,
      999999,
    );
    if (scrollPosition > maxScrollPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          scrollPosition = maxScrollPosition.toDouble();
        });
      });
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
              child: LineChart(
                _buildLineChartData(),
                duration: const Duration(milliseconds: 0),
              ),
            ),

            // 停止時のみスクロールバーを表示
            if (!widget.isRunning && maxScrollPosition > 0) ...[
              const SizedBox(height: 16),
              _buildScrollBar(maxScrollPosition),
            ],
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

  /// スクロールバーを構築
  Widget _buildScrollBar(int maxScrollPosition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スクロール位置: ${scrollPosition.toInt()} / $maxScrollPosition',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          min: 0,
          max: maxScrollPosition.toDouble(),
          value: scrollPosition,
          onChanged: (value) {
            setState(() {
              scrollPosition = value;
            });
          },
          divisions: maxScrollPosition > 0 ? maxScrollPosition : null,
          label: scrollPosition.toInt().toString(),
        ),
      ],
    );
  }

  /// グラフデータを構築
  LineChartData _buildLineChartData() {
    final dataLength = widget.historyTarget.length;

    // 実行中：最新 maxDataPoints 点のみ表示
    // 停止中：スクロール位置から maxDataPoints 点を表示
    final int startIndex;
    final int endIndex;

    if (widget.isRunning) {
      // 実行中：最新 maxDataPoints 点のみ
      final windowLen = (widget.maxDataPoints >= dataLength)
          ? dataLength
          : widget.maxDataPoints;
      startIndex = (dataLength == 0) ? 0 : (dataLength - windowLen);
      endIndex = (dataLength == 0) ? 0 : (dataLength - 1);
    } else {
      // 停止中：スクロール位置から maxDataPoints 点を表示
      startIndex = scrollPosition.toInt();
      endIndex = (startIndex + widget.maxDataPoints - 1).clamp(
        0,
        dataLength - 1,
      );
    }
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
      minX: startIndex.toDouble(),
      maxX: dataLength > 0 ? endIndex.toDouble() : 0,
      minY: _calculateMinY(startIndex, endIndex),
      maxY: _calculateMaxY(startIndex, endIndex),
      lineBarsData: [
        _buildLineChartBarData(
          widget.historyTarget,
          Colors.blue,
          startIndex,
          endIndex,
        ),
        _buildLineChartBarData(
          widget.historyOutput,
          Colors.red,
          startIndex,
          endIndex,
        ),
        _buildLineChartBarData(
          widget.historyControl,
          Colors.green,
          startIndex,
          endIndex,
        ),
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
  LineChartBarData _buildLineChartBarData(
    List<double> data,
    Color color,
    int startIndex,
    int endIndex,
  ) {
    final spots = <FlSpot>[];
    for (int i = startIndex; i <= endIndex; i++) {
      final x = i.toDouble();
      final y = data[i];
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
  double _calculateMinY(int startIndex, int endIndex) {
    if (widget.historyTarget.isEmpty &&
        widget.historyOutput.isEmpty &&
        widget.historyControl.isEmpty) {
      return -1.0;
    }
    // 境界チェック: インデックスが範囲外の場合は全体を使用
    final safeStart = startIndex.clamp(0, widget.historyTarget.length);
    final safeEnd = (endIndex + 1).clamp(0, widget.historyTarget.length);
    if (safeStart >= safeEnd) {
      return -1.0;
    }
    final allValues = [
      ...widget.historyTarget.sublist(safeStart, safeEnd),
      ...widget.historyOutput.sublist(safeStart, safeEnd),
      ...widget.historyControl.sublist(safeStart, safeEnd),
    ];
    final minValue = allValues.reduce((a, b) => a < b ? a : b);

    // 少し余裕を持たせる
    return (minValue - 0.5).floorToDouble();
  }

  /// Y軸の最大値を計算
  double _calculateMaxY(int startIndex, int endIndex) {
    if (widget.historyTarget.isEmpty &&
        widget.historyOutput.isEmpty &&
        widget.historyControl.isEmpty) {
      return 2.0;
    }
    // 境界チェック: インデックスが範囲外の場合は全体を使用
    final safeStart = startIndex.clamp(0, widget.historyTarget.length);
    final safeEnd = (endIndex + 1).clamp(0, widget.historyTarget.length);
    if (safeStart >= safeEnd) {
      return 2.0;
    }
    final allValues = [
      ...widget.historyTarget.sublist(safeStart, safeEnd),
      ...widget.historyOutput.sublist(safeStart, safeEnd),
      ...widget.historyControl.sublist(safeStart, safeEnd),
    ];
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);

    // 少し余裕を持たせる
    return (maxValue + 0.5).ceilToDouble();
  }
}
