/// PracticeInfoButton - Reusable info button for practice details
/// 
/// Shows practice information in a modal dialog when tapped.
/// Designed to be used throughout the app wherever practice names are displayed.
/// Follows PWA pattern of providing easy access to practice descriptions.

library;

import 'package:flutter/material.dart';
import '../models/practice_config.dart';
import '../utils/constants.dart';
import '../widgets/app_dialog.dart';

class PracticeInfoButton extends StatelessWidget {
  final String practiceName;
  final double size;
  final Color? color;

  const PracticeInfoButton({
    super.key,
    required this.practiceName,
    this.size = 18.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Only show button if practice has info available
    final info = PracticeConfig.getPracticeInfo(practiceName);
    if (info == null || info.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        Icons.info_outline,
        size: size,
        color: color ?? Colors.grey[400],
      ),
      constraints: BoxConstraints(
        minWidth: size + 8,
        minHeight: size + 8,
      ),
      padding: EdgeInsets.all(size * 0.2),
      onPressed: () => _showPracticeInfo(context, practiceName, info),
    );
  }

  /// Show practice information dialog
  void _showPracticeInfo(BuildContext context, String practiceName, String info) {
    AppDialog.show(
      context: context,
      title: practiceName,
      showClose: true,
      content: Text(
        info,
        style: const TextStyle(
          fontSize: TypographyConstants.fontSizeBase,
          height: 1.4,
          color: Color(0xFFe5e5e5),
        ),
      ),
      actions: const [],
    );
  }
}

/// Inline practice text with info button
/// Shows practice name with an inline info button
class PracticeTextWithInfo extends StatelessWidget {
  final String practiceName;
  final TextStyle? textStyle;
  final double infoButtonSize;
  final Color? infoButtonColor;
  final MainAxisAlignment alignment;

  const PracticeTextWithInfo({
    super.key,
    required this.practiceName,
    this.textStyle,
    this.infoButtonSize = 16.0,
    this.infoButtonColor,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            practiceName,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        PracticeInfoButton(
          practiceName: practiceName,
          size: infoButtonSize,
          color: infoButtonColor,
        ),
      ],
    );
  }
}

/// Practice list item with info button
/// Standard list tile format with trailing info button
class PracticeListTile extends StatelessWidget {
  final String practiceName;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? leading;
  final Color? textColor;

  const PracticeListTile({
    super.key,
    required this.practiceName,
    this.subtitle,
    this.onTap,
    this.leading,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        practiceName,
        style: TextStyle(
          fontSize: TypographyConstants.fontSizeBase,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: PracticeInfoButton(
        practiceName: practiceName,
        size: 18.0,
      ),
      onTap: onTap,
    );
  }
}
