import 'package:flutter/material.dart';
import '../ui/tokens.dart';

enum InfoState { loading, empty, error, info }

class InfoBlock extends StatelessWidget {
  final InfoState state;
  final IconData? icon;
  final String? title;
  final String? message;

  const InfoBlock({
    super.key,
    required this.state,
    this.icon,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<SemanticColors>()!;
    Widget body;

    switch (state) {
      case InfoState.loading:
        body = const Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.s12),
          child: Center(child: CircularProgressIndicator(color: Color(0xFF20b2aa), strokeWidth: 2)),
        );
        break;
      default:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: _iconColor(state, color),
                size: 28,
              ),
            if (title != null) ...[
              const SizedBox(height: Spacing.s8),
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
            ],
            if (message != null) ...[
              const SizedBox(height: Spacing.s8),
              Text(
                message!,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
    }

    return Center(child: body);
  }

  Color _iconColor(InfoState s, SemanticColors c) {
    switch (s) {
      case InfoState.error:
        return c.danger;
      case InfoState.info:
      case InfoState.empty:
        return c.accent;
      case InfoState.loading:
        return c.accent;
    }
  }
}

