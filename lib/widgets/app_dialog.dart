import 'package:flutter/material.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';
import '../utils/constants.dart';

class AppDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool dense;
  final bool showClose;

  const AppDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.dense = false,
    this.showClose = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool dense = false,
    bool showClose = false,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        title: title,
        content: content,
        actions: actions,
        dense: dense,
        showClose: showClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final padding = dense ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    final screenWidth = MediaQuery.of(context).size.width;
    // Wider on phones for legibility; clamp on larger screens
    final double maxWidth = (screenWidth * 0.96).clamp(0.0, 720.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02, // ~2% side margins
        vertical: layout.gutter + Spacing.s8,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * UIConstants.modalMaxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogTheme.backgroundColor,
            borderRadius: RadiusTokens.r16,
            border: Border.all(color: Theme.of(context).extension<SemanticColors>()!.border),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showClose)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                if (title != null) ...[
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Spacing.s12),
                ],
                Flexible(
                  child: SingleChildScrollView(child: content),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: Spacing.s16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: Spacing.s8,
                      runSpacing: Spacing.s8,
                      children: actions!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
