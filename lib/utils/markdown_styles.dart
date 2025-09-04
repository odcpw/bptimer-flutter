/// MarkdownStyles - Custom styling for markdown content
/// 
/// Provides consistent markdown styling that matches the app's typography system.
/// Maps to gpt_markdown's TextStyle-based approach for rendering.

library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Create app-consistent text style for markdown content
/// Used with GptMarkdown widget for consistent styling
TextStyle createMarkdownTextStyle() {
  return const TextStyle(
    fontSize: TypographyConstants.fontSizeBase,      // 16px
    fontWeight: TypographyConstants.fontWeightRegular,// w400
    color: Color(0xFFe5e5e5),
    height: 1.4,  // Match existing line height
  );
}

/// Create text style for smaller markdown content (dialogs, info panels)
TextStyle createSmallMarkdownTextStyle() {
  return const TextStyle(
    fontSize: TypographyConstants.fontSizeSmall,     // 14px
    fontWeight: TypographyConstants.fontWeightRegular,// w400
    color: Color(0xFFe5e5e5),
    height: 1.4,
  );
}