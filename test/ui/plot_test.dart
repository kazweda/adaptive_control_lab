import 'package:adaptive_control_lab/ui/plot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeSeriesPlot', () {
    testWidgets('常に全データ(0〜dataLength-1)が描画される（停止時）', (tester) async {
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

      // チャート自体は常に全データを描画し、横スクロールで表示範囲を移動する
      expect(chartData.minX, 0);
      expect(chartData.maxX, 9);
      expect(chartData.lineBarsData[0].spots.length, 10);
      expect(chartData.lineBarsData[1].spots.length, 10);
      expect(chartData.lineBarsData[2].spots.length, 10);
    });

    testWidgets('実行中は最新maxDataPoints分にY軸が追従する', (tester) async {
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

      // X軸は常に全範囲、Y軸は最新3点[7,8,9]に基づいて自動スケールする
      expect(chartData.minX, 0);
      expect(chartData.maxX, 9);
      expect(chartData.minY, 6); // floor(7 - 0.5)
      expect(chartData.maxY, 10); // ceil(9 + 0.5)
      expect(chartData.lineBarsData[0].spots.length, 10);
    });

    testWidgets('停止時は横スクロール可能、実行中はスクロール不可', (tester) async {
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

      expect(find.byType(Scrollbar), findsOneWidget);
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
      expect(scrollView.scrollDirection, Axis.horizontal);
    });

    testWidgets('実行中は横スクロールが無効化される', (tester) async {
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

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('停止時：チャートをドラッグするとonScrollChangedで位置が進む', (tester) async {
      final data = List<double>.generate(10, (i) => i.toDouble());
      double scrollPos = 0.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: TimeSeriesPlot(
                historyTarget: data,
                historyOutput: data,
                historyControl: data,
                maxDataPoints: 3,
                isRunning: false,
                scrollPosition: scrollPos,
                onScrollChanged: (newPos) {
                  setState(() {
                    scrollPos = newPos;
                  });
                },
              ),
            ),
          ),
        ),
      );

      expect(scrollPos, 0.0);

      // チャートを左方向にドラッグして先頭以外を表示する
      await tester.drag(find.byType(SingleChildScrollView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(scrollPos, greaterThan(0.0));
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

    testWidgets('実行中：データが増えると常に最新ウィンドウにY軸が追従する', (tester) async {
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
                  child: const Text('Grow'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // 実行中：最新2点[3,4]にY軸が追従
      var lineChart = tester.widget<LineChart>(find.byType(LineChart));
      var chartData = lineChart.data;
      expect(chartData.minY, 2); // floor(3 - 0.5)
      expect(chartData.minX, 0);
      expect(chartData.maxX, 4);

      // データが10点に増える
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 引き続き実行中：最新2点[8,9]にY軸が追従
      lineChart = tester.widget<LineChart>(find.byType(LineChart));
      chartData = lineChart.data;
      expect(chartData.minY, 7); // floor(8 - 0.5)
      expect(chartData.minX, 0);
      expect(chartData.maxX, 9);
    });
  });
}
