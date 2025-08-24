import 'package:flutter/material.dart';
import '../ui/tokens.dart';

enum AppButtonVariant { primary, secondary, outline, danger, quiet }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
  });

  factory AppButton.primary(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = false, AppButtonSize size = AppButtonSize.md}) =>
      AppButton(label, onPressed: onPressed, icon: icon, variant: AppButtonVariant.primary, fullWidth: fullWidth, size: size);
  factory AppButton.outline(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = false, AppButtonSize size = AppButtonSize.md}) =>
      AppButton(label, onPressed: onPressed, icon: icon, variant: AppButtonVariant.outline, fullWidth: fullWidth, size: size);
  factory AppButton.danger(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = false, AppButtonSize size = AppButtonSize.md}) =>
      AppButton(label, onPressed: onPressed, icon: icon, variant: AppButtonVariant.danger, fullWidth: fullWidth, size: size);
  factory AppButton.quiet(String label, {VoidCallback? onPressed, IconData? icon, bool fullWidth = false, AppButtonSize size = AppButtonSize.md}) =>
      AppButton(label, onPressed: onPressed, icon: icon, variant: AppButtonVariant.quiet, fullWidth: fullWidth, size: size);

  @override
  Widget build(BuildContext context) {
    final semantics = Theme.of(context).extension<SemanticColors>()!;
    final height = switch (size) { AppButtonSize.sm => 40.0, AppButtonSize.md => 48.0, AppButtonSize.lg => 56.0 };
    final textStyle = TextStyle(fontSize: switch (size) { AppButtonSize.sm => 12.0, AppButtonSize.md => 14.0, AppButtonSize.lg => 16.0 }, fontWeight: FontWeight.w500);
    final iconSize = switch (size) { AppButtonSize.sm => 18.0, AppButtonSize.md => 20.0, AppButtonSize.lg => 22.0 };

    ButtonStyle style;
    Widget child = Text(label, style: textStyle);
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: iconSize), const SizedBox(width: Spacing.s8), Text(label, style: textStyle)],
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        style = ElevatedButton.styleFrom(minimumSize: Size(fullWidth ? double.infinity : 120, height));
        return ElevatedButton(onPressed: onPressed, style: style, child: child);
      case AppButtonVariant.secondary:
        style = ElevatedButton.styleFrom(minimumSize: Size(fullWidth ? double.infinity : 120, height), backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Colors.black);
        return ElevatedButton(onPressed: onPressed, style: style, child: child);
      case AppButtonVariant.outline:
        style = OutlinedButton.styleFrom(minimumSize: Size(fullWidth ? double.infinity : 120, height));
        return OutlinedButton(onPressed: onPressed, style: style, child: child);
      case AppButtonVariant.danger:
        style = OutlinedButton.styleFrom(minimumSize: Size(fullWidth ? double.infinity : 120, height), foregroundColor: semantics.danger, side: BorderSide(color: semantics.danger));
        return OutlinedButton(onPressed: onPressed, style: style, child: child);
      case AppButtonVariant.quiet:
        style = TextButton.styleFrom(minimumSize: Size(fullWidth ? double.infinity : 120, height));
        return TextButton(onPressed: onPressed, style: style, child: child);
    }
  }
}

class ButtonRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final bool wrapOnNarrow;

  const ButtonRow({super.key, required this.children, this.gap = Spacing.s16, this.wrapOnNarrow = true});

  @override
  Widget build(BuildContext context) {
    if (wrapOnNarrow) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: Spacing.s12),
                ]
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Flexible(fit: FlexFit.loose, child: children[i]),
                if (i != children.length - 1) SizedBox(width: gap),
              ],
            ],
          );
        },
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

