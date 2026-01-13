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

    testWidgets('停止時：スライダー操作でデータ範囲が変更される', (tester) async {
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

      // 初期状態：startIndex=0
      var lineChart = tester.widget<LineChart>(find.byType(LineChart));
      var chartData = lineChart.data;
      expect(chartData.minX, 0);

      // スライダーを最後に移動
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();

      // スライダー移動後：startIndex が変更される
      lineChart = tester.widget<LineChart>(find.byType(LineChart));
      chartData = lineChart.data;
      expect(chartData.minX, greaterThan(0));
    });

    testWidgets('エッジケース：データ長 < maxDataPoints の場合', (tester) async {
      final data = List<double>.generate(5, (i) => i.toDouble());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSeriesPlot(
              historyTarget: data,
              historyOutput: data,
              historyControl: data,
              maxDataPoints: 10,
              isRunning: false,
            ),
          ),
        ),
      );

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final chartData = lineChart.data;

      // データ長（5） < maxDataPoints（10）の場合、全データを表示
      expect(chartData.minX, 0);
      expect(chartData.maxX, 4);
      expect(chartData.lineBarsData[0].spots.length, 5);
    });

    testWidgets('エッジケース：データ長 == maxDataPoints の場合', (tester) async {
      final data = List<double>.generate(3, (i) => i.toDouble());

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

      // データ長 == maxDataPoints の場合、全データを表示
      expect(chartData.minX, 0);
      expect(chartData.maxX, 2);
      expect(chartData.lineBarsData[0].spots.length, 3);
    });

    testWidgets('実行中 → 停止時：最新データが見える位置に初期化', (tester) async {
      var data = List<double>.generate(5, (i) => i.toDouble());

      final widget = MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TimeSeriesPlot(
                  historyTarget: data,
                  historyOutput: data,
                  historyControl: data,
                  maxDataPoints: 2,
                  isRunning: true,
                ),
                ElevatedButton(
                  onPressed: () {
                    data = List<double>.generate(10, (i) => i.toDouble());
                    setState(() {});
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // 実行中：最新2点のみ表示
      var lineChart = tester.widget<LineChart>(find.byType(LineChart));
      var chartData = lineChart.data;
      expect(chartData.minX, 3); // 最新2点：[3, 4]

      // 停止ボタンを押す
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 停止時：最新データが見える位置に初期化
      lineChart = tester.widget<LineChart>(find.byType(LineChart));
      chartData = lineChart.data;
      expect(chartData.minX, 8); // 最新2点：[8, 9]
    });
  });
}
