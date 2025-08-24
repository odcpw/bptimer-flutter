import 'package:flutter/material.dart';
import '../ui/tokens.dart';

/// Minimal section primitive that renders an optional header and a padded surface.
class Section extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final bool dense;
  final EdgeInsetsGeometry? padding;

  const Section({
    super.key,
    this.title,
    required this.child,
    this.trailing,
    this.dense = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? EdgeInsets.all(dense ? Spacing.s12 : Spacing.s16);
    final border = Theme.of(context).extension<SemanticColors>()!.border;
    final bg = Theme.of(context).extension<SemanticColors>()!.surfaceElevated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(top: Spacing.s24, bottom: Spacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: RadiusTokens.r12,
            border: Border.all(color: border),
          ),
          child: Padding(padding: pad, child: child),
        ),
      ],
    );
  }
}
