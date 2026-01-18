import 'package:flutter/material.dart';
import '../simulation/simulator.dart';
import 'plot.dart';
import 'controllers/pid_controller_screen.dart';
import 'controllers/str_controller_screen.dart';
import 'components/chart_window_selector.dart';
import 'components/simulation_status_panel.dart';
import 'components/simulation_control_panel.dart';
import 'components/target_value_panel.dart';
import 'components/controller_selector_panel.dart';
import 'components/disturbance_panel.dart';
import 'components/plant_params_panel.dart';
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
  int _selectedControllerIndex = 0; // 0: PID, 1: STR

  @override
  void initState() {
    super.initState();
    simulator = Simulator();
  }

  int _effectiveChartWindow() {
    // 停止中は _chartWindow の値を使用（デフォルト 200）
    // 実行中に All(null) が選ばれている場合は 200 に制限
    if (isRunning && _chartWindow == null) return 200;
    return _chartWindow ?? 200;
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

  /// コントローラー設定画面（PIDまたはSTR）
  Widget _buildControllerScreen() {
    if (_selectedControllerIndex == 0) {
      return PIDControllerScreen(
        simulator: simulator,
        onUpdate: () => setState(() {}),
      );
    } else {
      return STRControllerScreen(
        simulator: simulator,
        onUpdate: () => setState(() {}),
      );
    }
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
              ChartWindowSelector(
                chartWindow: _chartWindow,
                onChanged: (v) {
                  setState(() {
                    _chartWindow = v;
                  });
                },
              ),
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
              SimulationStatusPanel(simulator: simulator, isRunning: isRunning),
              const SizedBox(height: 24),

              // === 制御ボタン ===
              SimulationControlPanel(
                isRunning: isRunning,
                onStart: _startSimulation,
                onStop: _stopSimulation,
                onReset: _resetSimulation,
              ),
              const SizedBox(height: 24),

              // === 目標値調整 ===
              TargetValuePanel(
                simulator: simulator,
                onChanged: (value) {
                  setState(() {
                    simulator.targetValue = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // === コントローラー選択タブ ===
              ControllerSelectorPanel(
                selectedControllerIndex: _selectedControllerIndex,
                onChanged: (index) {
                  setState(() {
                    _selectedControllerIndex = index;
                  });
                },
              ),
              const SizedBox(height: 16),

              // === コントローラー設定画面 ===
              _buildControllerScreen(),
              const SizedBox(height: 24),

              // === プラントパラメータ調整 ===
              PlantParamsPanel(
                simulator: simulator,
                onPlantOrderChanged: (useSecondOrder) {
                  setState(() {
                    simulator.setPlantOrder(useSecondOrder: useSecondOrder);
                  });
                },
                onParamAChanged: (value) {
                  setState(() {
                    simulator.plantParamA = value;
                  });
                },
                onParamBChanged: (value) {
                  setState(() {
                    simulator.plantParamB = value;
                  });
                },
                onParamA1Changed: (value) {
                  setState(() {
                    simulator.plantParamA1 = value;
                  });
                },
                onParamA2Changed: (value) {
                  setState(() {
                    simulator.plantParamA2 = value;
                  });
                },
                onParamB1Changed: (value) {
                  setState(() {
                    simulator.plantParamB1 = value;
                  });
                },
                onParamB2Changed: (value) {
                  setState(() {
                    simulator.plantParamB2 = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              // === 外乱設定 ===
              DisturbancePanel(
                simulator: simulator,
                onTypeChanged: (type) {
                  setState(() {
                    simulator.setDisturbanceType(type);
                  });
                },
                onPresetApplied: (presetName) {
                  setState(() {
                    simulator.applyDisturbancePreset(presetName);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
