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
import 'package:url_launcher/url_launcher.dart';

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
  int _chartWindow = ChartWindowSelector.standardWindow;
  int _selectedControllerIndex = 0; // 0: PID, 1: STR
  String _appVersion = '1.0.0+1'; // アプリケーションバージョン
  double _scrollPosition = 0.0; // 共通スクロール位置（3つのプロット同期用）

  // Wiki（Help）ページへのリンク
  static const String _wikiUrl =
      'https://github.com/kazweda/adaptive_control_lab/wiki';

  /// Wikiページをブラウザで開く
  Future<void> _openWiki() async {
    final uri = Uri.parse(_wikiUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Failed to launch $_wikiUrl');
    }
  }

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
        final maxScrollIndex = (dataLength - _chartWindow).clamp(0, dataLength);
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
      final maxScrollIndex = (dataLength - _chartWindow).clamp(0, dataLength);
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'ヘルプ（Wiki）',
            onPressed: _openWiki,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
              // === 時系列チャート（2/3幅）＋ 制御ボタン（1/3幅） ===
              ResponsiveSplitRow(
                flex: const [2, 1],
                children: [
                  TimeSeriesPlot(
                    historyTarget: simulator.historyTarget,
                    historyOutput: simulator.historyOutput,
                    historyControl: simulator.historyControl,
                    maxDataPoints: _chartWindow,
                    isRunning: isRunning,
                    scrollPosition: _scrollPosition,
                    onScrollChanged: (value) {
                      setState(() {
                        _scrollPosition = value;
                      });
                    },
                    chartWindow: _chartWindow,
                    onChartWindowChanged: (v) {
                      setState(() {
                        _chartWindow = v;
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
                    maxDataPoints: _chartWindow,
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
                    maxDataPoints: _chartWindow,
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
              // PID/STR/プラントを独立したグループとして渡し、
              // デスクトップ幅（3カラム）で列の高さがバランスするようにする
              ResponsiveCardGrid(
                children: [
                  // PID設定（プリセット＋詳細設定）
                  _buildControllerCard(
                    isActive: _selectedControllerIndex == 0,
                    child: PIDControllerScreen(
                      simulator: simulator,
                      onUpdate: () => setState(() {}),
                    ),
                  ),

                  // STR設定（プリセット＋詳細設定）
                  _buildControllerCard(
                    isActive: _selectedControllerIndex == 1,
                    child: STRControllerScreen(
                      simulator: simulator,
                      onUpdate: () => setState(() {}),
                    ),
                  ),

                  // プラント設定（制御対象・外乱設定を同じグループにまとめる）
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
