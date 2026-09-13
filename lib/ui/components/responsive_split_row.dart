import 'package:flutter/material.dart';

/// 画面幅に応じて子ウィジェットを指定した比率で横並び（ワイド時）
/// または縦積み（ナロー時）に配置するウィジェット
///
/// [flex] は各 [children] に対応する比率（例: [2, 1] で 2:1 の幅配分）。
class ResponsiveSplitRow extends StatelessWidget {
  final List<Widget> children;
  final List<int> flex;
  final double spacing;
  final double breakpoint;

  const ResponsiveSplitRow({
    super.key,
    required this.children,
    required this.flex,
    this.spacing = 16.0,
    this.breakpoint = 600.0,
  }) : assert(children.length == flex.length);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(flex: flex[i], child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
