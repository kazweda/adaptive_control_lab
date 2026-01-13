import 'package:adaptive_control_lab/ui/plot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeSeriesPlot', () {
    testWidgets('停止時はスクロール位置0でmaxDataPoints点を描画', (tester) async {
      final data = List<double>.generate(10, (i) => i.toDouble());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSeriesPlot(
              historyTarget: data,
              historyOutput: data,
              historyControl: data,
              maxDataPoints: 3,
              isRunning: false,
            ),
          ),
        ),
      );

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final chartData = lineChart.data;

      expect(chartData.minX, 0); // startIndex=scrollPosition=0
      expect(chartData.maxX, 2); // endIndex=scrollPosition+maxDataPoints-1=2
      expect(chartData.lineBarsData[0].spots.length, 3);
      expect(chartData.lineBarsData[1].spots.length, 3);
      expect(chartData.lineBarsData[2].spots.length, 3);
    });

    testWidgets('実行中はウィンドウ制限（最新maxDataPointsのみ）', (tester) async {
      final data = List<double>.generate(10, (i) => i.toDouble());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSeriesPlot(
              historyTarget: data,
              historyOutput: data,
              historyControl: data,
              maxDataPoints: 3,
              isRunning: true,
            ),
          ),
        ),
      );

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final chartData = lineChart.data;

      expect(chartData.minX, 7); // startIndex=dataLength-windowLen
      expect(chartData.maxX, 9); // endIndex=dataLength-1
      expect(chartData.lineBarsData[0].spots.length, 3);
      expect(chartData.lineBarsData[1].spots.length, 3);
      expect(chartData.lineBarsData[2].spots.length, 3);
    });

    testWidgets('停止時はスクロールバーが表示される', (tester) async {
      final data = List<double>.generate(10, (i) => i.toDouble());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSeriesPlot(
              historyTarget: data,
              historyOutput: data,
              historyControl: data,
              maxDataPoints: 3,
              isRunning: false,
            ),
          ),
        ),
      );

      // Slider（スクロールバー）が表示されている
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('実行中はスクロールバーが非表示', (tester) async {
      final data = List<double>.generate(10, (i) => i.toDouble());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSeriesPlot(
              historyTarget: data,
              historyOutput: data,
              historyControl: data,
              maxDataPoints: 3,
              isRunning: true,
            ),
          ),
        ),
      );

      // Slider（スクロールバー）が非表示
      expect(find.byType(Slider), findsNothing);
    });
  });
}
