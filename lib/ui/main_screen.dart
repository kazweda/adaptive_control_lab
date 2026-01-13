import 'package:flutter/material.dart';
import '../simulation/simulator.dart';
import '../control/disturbance.dart';
import 'plot.dart';
import 'dart:async';

/// メイン画面UI
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Simulator simulator;
  Timer? simulationTimer;
  bool isRunning = false;
  int? _chartWindow = 200; // 200/500/1000/全履歴(null)

  @override
  void initState() {
    super.initState();
    simulator = Simulator();
  }

  int? _effectiveChartWindow() {
    // 実行中に All(null) が選ばれている場合は 200 に制限
    if (isRunning && _chartWindow == null) return 200;
    return _chartWindow;
  }

  Widget _buildChartWindowSelector() {
    const options = [200, 500, 1000, null];
    String labelOf(int? v) => v == null ? '全履歴' : v.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '表示ウィンドウ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        DropdownButton<int?>(
          value: _chartWindow,
          items: options
              .map(
                (v) =>
                    DropdownMenuItem<int?>(value: v, child: Text(labelOf(v))),
              )
              .toList(),
          onChanged: (v) {
            setState(() {
              _chartWindow = v;
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    simulationTimer?.cancel();
    super.dispose();
  }

  /// シミュレーションを開始
  void _startSimulation() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    // 50ms ごとにシミュレーションを進める
    simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        simulator.step();
      });
    });
  }

  /// シミュレーションを一時停止
  void _stopSimulation() {
    if (!isRunning) return;

    simulationTimer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  /// シミュレーションをリセット
  void _resetSimulation() {
    _stopSimulation();
    setState(() {
      simulator.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('制御系シミュレーション'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === チャート表示ウィンドウ切替 ===
              _buildChartWindowSelector(),
              const SizedBox(height: 8),
              // === 時系列グラフ ===
              TimeSeriesPlot(
                historyTarget: simulator.historyTarget,
                historyOutput: simulator.historyOutput,
                historyControl: simulator.historyControl,
                // 実行中は安全のため All 選択時でも 200 に制限
                maxDataPoints: _effectiveChartWindow(),
                isRunning: isRunning,
              ),
              const SizedBox(height: 24),

              // === ステータス表示 ===
              _buildStatusSection(),
              const SizedBox(height: 24),

              // === 制御ボタン ===
              _buildControlButtons(),
              const SizedBox(height: 24),

              // === 目標値調整 ===
              _buildTargetValueSection(),
              const SizedBox(height: 24),

              // === PIDゲイン調整 ===
              _buildPIDGainsSection(),
              const SizedBox(height: 24),

              // === プラントパラメータ調整 ===
              _buildPlantParamsSection(),
              const SizedBox(height: 24),
              // === 外乱設定 ===
              _buildDisturbanceSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// ステータス表示セクション
  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 実行状態
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '状態：',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isRunning ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRunning ? '実行中' : '停止中',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 各値の表示
            _buildValueRow('目標値', simulator.targetValue),
            const SizedBox(height: 8),
            _buildValueRow('出力', simulator.plantOutput),
            const SizedBox(height: 8),
            _buildValueRow('制御入力', simulator.controlInput),
            const SizedBox(height: 8),
            _buildValueRow(
              'ステップ',
              simulator.stepCount.toDouble(),
              isInteger: true,
            ),
          ],
        ),
      ),
    );
  }

  /// 外乱設定（最小UI: 種類のみ）
  Widget _buildDisturbanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '外乱設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '外乱タイプ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<DisturbanceType>(
                  value: simulator.disturbanceType,
                  items: const [
                    DropdownMenuItem(
                      value: DisturbanceType.none,
                      child: Text('なし'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.step,
                      child: Text('ステップ'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.impulse,
                      child: Text('インパルス'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.sinusoid,
                      child: Text('正弦波'),
                    ),
                    DropdownMenuItem(
                      value: DisturbanceType.noise,
                      child: Text('雑音'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      simulator.setDisturbanceType(v);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 値を1行で表示するヘルパー
  Widget _buildValueRow(String label, double value, {bool isInteger = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label：', style: const TextStyle(fontSize: 14)),
        Text(
          isInteger ? value.toInt().toString() : value.toStringAsFixed(3),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// 制御ボタンセクション
  Widget _buildControlButtons() {
    return Row(
      children: [
        // スタートボタン
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRunning ? null : _startSimulation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('スタート'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // ストップボタン
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRunning ? _stopSimulation : null,
            icon: const Icon(Icons.stop),
            label: const Text('ストップ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // リセットボタン
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetSimulation,
            icon: const Icon(Icons.refresh),
            label: const Text('リセット'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  /// 目標値調整セクション
  Widget _buildTargetValueSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '目標値',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: simulator.targetValue,
                    min: 0.0,
                    max: 2.0,
                    divisions: 40,
                    label: simulator.targetValue.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        simulator.targetValue = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  simulator.targetValue.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// PIDゲイン調整セクション
  Widget _buildPIDGainsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PID ゲイン調整',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Kp（比例ゲイン）
            _buildGainSlider(
              label: 'Kp（比例）',
              value: simulator.pidKp,
              onChanged: (value) {
                setState(() {
                  simulator.pidKp = value;
                });
              },
              description: '素早く反応する程度',
            ),
            const SizedBox(height: 16),

            // Ki（積分ゲイン）
            _buildGainSlider(
              label: 'Ki（積分）',
              value: simulator.pidKi,
              onChanged: (value) {
                setState(() {
                  simulator.pidKi = value;
                });
              },
              description: 'ズレを直す強さ',
            ),
            const SizedBox(height: 16),

            // Kd（微分ゲイン）
            _buildGainSlider(
              label: 'Kd（微分）',
              value: simulator.pidKd,
              onChanged: (value) {
                setState(() {
                  simulator.pidKd = value;
                });
              },
              description: '揺れを抑える程度',
            ),
          ],
        ),
      ),
    );
  }

  /// ゲインスライダーのヘルパーウィジェット
  Widget _buildGainSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toStringAsFixed(3),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// プラントパラメータ調整セクション
  Widget _buildPlantParamsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プラント設定（自動制御される対象）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // プラント次数切替
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プラント次数',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<bool>(
                  value: simulator.isSecondOrderPlant,
                  items: const [
                    DropdownMenuItem<bool>(value: false, child: Text('1次')),
                    DropdownMenuItem<bool>(value: true, child: Text('2次')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      simulator.setPlantOrder(useSecondOrder: v);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!simulator.isSecondOrderPlant) ...[
              // 1次系: a, b
              _buildPlantParamSlider(
                label: '慣性の強さ (a)',
                value: simulator.plantParamA,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamA = value;
                  });
                },
                description: '大きいほど前の値が強く影響',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '応答の敏感さ (b)',
                value: simulator.plantParamB,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamB = value;
                  });
                },
                description: '大きいほど入力に敏感に反応',
              ),
            ] else ...[
              // 2次系: a1, a2, b1, b2
              _buildPlantParamSlider(
                label: 'フィードバック係数 (a1)',
                value: simulator.plantParamA1,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamA1 = value;
                  });
                },
                description: 'y(k-1) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: 'フィードバック係数 (a2)',
                value: simulator.plantParamA2,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamA2 = value;
                  });
                },
                description: 'y(k-2) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '入力係数 (b1)',
                value: simulator.plantParamB1,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamB1 = value;
                  });
                },
                description: 'u(k-1) の係数',
              ),
              const SizedBox(height: 16),
              _buildPlantParamSlider(
                label: '入力係数 (b2)',
                value: simulator.plantParamB2,
                onChanged: (value) {
                  setState(() {
                    simulator.plantParamB2 = value;
                  });
                },
                description: 'u(k-2) の係数',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// プラントパラメータスライダーのヘルパーウィジェット
  Widget _buildPlantParamSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              value.toStringAsFixed(3),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
