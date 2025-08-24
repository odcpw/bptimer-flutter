import 'package:flutter/material.dart';
import 'tokens.dart';

/// Provides responsive layout values like gutter and max content width.
class AppLayout {
  final double width;
  late final double gutter;
  late final double maxWidth;

  AppLayout._(this.width) {
    gutter = LayoutTokens.gutterForWidth(width);
    maxWidth = LayoutTokens.maxContentWidth;
  }

  static AppLayout of(BuildContext context) => AppLayout._(MediaQuery.of(context).size.width);
}

/// Centers content, constrains to max width, and applies horizontal gutters.
class AppScaffoldBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding; // additional padding (e.g., vertical)

  const AppScaffoldBody({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.gutter).add(padding ?? EdgeInsets.zero),
          child: child,
        ),
      ),
    );
  }
}

