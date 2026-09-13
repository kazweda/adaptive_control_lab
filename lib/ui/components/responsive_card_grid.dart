import 'package:flutter/material.dart';

/// 設定カード群を画面幅に応じて1〜3カラムに配置するレスポンシブグリッド
///
/// - 600px未満: 1カラム（モバイル、縦積み）
/// - 600〜1000px未満: 2カラム（タブレット）
/// - 1000px以上: 3カラム（デスクトップ）
class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
  });

  static int columnsForWidth(double width) {
    if (width < 600) return 1;
    if (width < 1000) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsForWidth(constraints.maxWidth);

        if (columns == 1) {
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

        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
