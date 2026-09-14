import 'package:flutter/material.dart';
import '../simulation/simulator.dart';
import 'controllers/pid_controller_screen.dart';
import 'controllers/str_controller_screen.dart';
import 'plot.dart';
import 'diagnostics_plot.dart';
import 'components/chart_window_selector.dart';
import 'components/simulation_status_panel.dart';
import 'components/simulation_control_panel.dart';
import 'components/disturbance_panel.dart';
import 'components/plant_params_panel.dart';
import 'components/responsive_card_grid.dart';
import 'components/responsive_split_row.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = '1.0.0+1'; // アプリケーションバージョン
  double _scrollPosition = 0.0; // 共通スクロール位置（3つのプロット同期用）

  @override
  void initState() {
    super.initState();
    simulator = Simulator();
    _loadPackageInfo();
  }

  /// パッケージ情報からバージョンを読み込む
  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      // フォールバック: pubspec.yaml から読み込まれたデフォルト値を使用
      debugPrint('Failed to load package info: $e');
    }
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
      if (!mounted) {
        simulationTimer?.cancel();
        return;
      }
      simulator.step();
      if (simulator.isHalted) {
        simulationTimer?.cancel();
        final dataLength = simulator.historyTarget.length;
        final maxScrollIndex = (dataLength - _effectiveChartWindow()).clamp(
          0,
          dataLength,
        );
        setState(() {
          isRunning = false;
          _scrollPosition = maxScrollIndex.toDouble();
        });
      } else {
        setState(() {});
      }
    });
  }

  /// シミュレーションを一時停止
  void _stopSimulation() {
    if (!isRunning) return;

    simulationTimer?.cancel();
    setState(() {
      isRunning = false;
      // 停止時に最新データが見える位置に初期化
      final dataLength = simulator.historyTarget.length;
      final maxScrollIndex = (dataLength - _effectiveChartWindow()).clamp(
        0,
        dataLength,
      );
      _scrollPosition = maxScrollIndex.toDouble();
    });
  }

  /// シミュレーションをリセット
  void _resetSimulation() {
    _stopSimulation();
    setState(() {
      simulator.reset();
    });
  }

  /// コントローラー設定画面（PID/STR両方を常時表示し、非選択側をグレーアウト）
  Widget _buildControllerScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildControllerCard(
          isActive: _selectedControllerIndex == 0,
          child: PIDControllerScreen(
            simulator: simulator,
            onUpdate: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        _buildControllerCard(
          isActive: _selectedControllerIndex == 1,
          child: STRControllerScreen(
            simulator: simulator,
            onUpdate: () => setState(() {}),
          ),
        ),
      ],
    );
  }

  /// 選択されていないコントローラーカードをグレーアウトし操作不可にする
  Widget _buildControllerCard({required bool isActive, required Widget child}) {
    if (isActive) return child;
    return Opacity(opacity: 0.4, child: IgnorePointer(child: child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('制御系シミュレーション'),
        centerTitle: true,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'v$_appVersion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
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

              // === 時系列チャート（2/3幅）＋ 制御ボタン（1/3幅） ===
              ResponsiveSplitRow(
                flex: const [2, 1],
                children: [
                  TimeSeriesPlot(
                    historyTarget: simulator.historyTarget,
                    historyOutput: simulator.historyOutput,
                    historyControl: simulator.historyControl,
                    // 実行中は安全のため All 選択時でも 200 に制限
                    maxDataPoints: _effectiveChartWindow(),
                    isRunning: isRunning,
                    scrollPosition: _scrollPosition,
                    onScrollChanged: (value) {
                      setState(() {
                        _scrollPosition = value;
                      });
                    },
                  ),
                  SimulationControlPanel(
                    isRunning: isRunning,
                    onStart: _startSimulation,
                    onStop: _stopSimulation,
                    onReset: _resetSimulation,
                    selectedControllerIndex: _selectedControllerIndex,
                    onControllerChanged: (index) {
                      setState(() {
                        _selectedControllerIndex = index;
                        simulator.setStrEnabled(index == 1);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // === 残差チャート（1/3幅）＋ 推定パラメータチャート（1/3幅）＋ 状態（1/3幅） ===
              ResponsiveSplitRow(
                flex: const [1, 1, 1],
                children: [
                  ResidualPlot(
                    residual: simulator.historyResidual,
                    maxDataPoints: _effectiveChartWindow(),
                    isRunning: isRunning,
                    scrollPosition: _scrollPosition,
                    onScrollChanged: (value) {
                      setState(() {
                        _scrollPosition = value;
                      });
                    },
                  ),
                  ParameterTracePlot(
                    isSecondOrder: simulator.isSecondOrderPlant,
                    maxDataPoints: _effectiveChartWindow(),
                    isRunning: isRunning,
                    scrollPosition: _scrollPosition,
                    onScrollChanged: (value) {
                      setState(() {
                        _scrollPosition = value;
                      });
                    },
                    estA: simulator.historyEstimatedA,
                    estB: simulator.historyEstimatedB,
                    estA1: simulator.historyEstimatedA1,
                    estA2: simulator.historyEstimatedA2,
                    estB1: simulator.historyEstimatedB1,
                    estB2: simulator.historyEstimatedB2,
                    actualA: simulator.historyActualA,
                    actualB: simulator.historyActualB,
                    actualA1: simulator.historyActualA1,
                    actualA2: simulator.historyActualA2,
                    actualB1: simulator.historyActualB1,
                    actualB2: simulator.historyActualB2,
                  ),
                  SimulationStatusPanel(
                    simulator: simulator,
                    isRunning: isRunning,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // === 設定カード群（画面幅に応じて1〜3カラムのレスポンシブ配置） ===
              ResponsiveCardGrid(
                children: [
                  // コントローラー設定画面（PID/STR）
                  _buildControllerScreen(),

                  // プラントパラメータ調整
                  PlantParamsPanel(
                    simulator: simulator,
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
                  ),

                  // 外乱設定
                  DisturbancePanel(
                    simulator: simulator,
                    onPresetApplied: (presetName) {
                      setState(() {
                        simulator.applyDisturbancePreset(presetName);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
