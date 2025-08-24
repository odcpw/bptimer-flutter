/// AboutScreen - About section exactly matching PWA content
/// 
/// Reproduces the exact About content from the PWA including:
/// - Balanced Practice explanation
/// - How to Use BPtimer instructions
/// - Gratitude section to teachers

library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: AppScaffoldBody(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balanced Practice section
            _buildSection(
              'Balanced Practice', 
              [
                'Balanced Practice Timer encourages a balanced approach to meditation and mental development, incorporating mindfulness, reflective contemplative meditation, and daily mindfulness activities to support a balanced practice. Regular practice with better understanding of the balance between the methods can help lead to more balanced mental development.'
              ],
              isBold: true,
            ),
            
            const SizedBox(height: 24),
            
            // How to Use BPtimer section
            _buildSection('How to Use BPtimer', []),
            const SizedBox(height: 16),
            
            _buildSubSection('Getting Started', [
              'Set Duration: Use the +5/-5 buttons to adjust your timer (5-120 minutes)',
              'Start Timer: Click Start to begin your session',
              'Timer Controls: Pause/resume or stop your session as needed',
            ]),
            
            const SizedBox(height: 16),
            
            _buildSubSection('Session Planning (Optional)', [
              'Plan Structure: Expand "Plan Session" to organize your practice',
              'Choose Posture: Select sitting, standing, or walking',
              'Add Practices: Select specific meditation techniques in order',
              'Save Favorites: Save common sessions for quick access',
            ]),
            
            const SizedBox(height: 16),
            
            _buildSubSection('Session Recording', [
              'Track Practice: After each session, record what you actually practiced',
              'View Statistics: Monitor your practice patterns and consistency',
              'Export Data: Backup your meditation history',
            ]),
            
            const SizedBox(height: 16),
            
            _buildSubSection('Special Mindfulness Activities (SMAs)', [
              'SMAs are informal practices you do throughout your day - like opening doors mindfully or awareness of using water taps. Set reminders to help build these habits of awareness in daily life.'
            ], isBold: true),
            
            const SizedBox(height: 24),
            
            // Gratitude section
            _buildSection('Gratitude', [
              'This app is created with gratitude to Rosemary and Steve Weissmann, whose dedicated teaching has brought Buddha\'s profound teachings to practitioners in a balanced and practical way.',
              '',
              'Their skillful guidance helps students develop a comprehensive and balanced meditation practice.',
              '',
              'May this simple timer support your practice and contribute to the growth of compassionate understanding.'
            ]),
            
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> content, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeMedium,
            fontWeight: isBold ? TypographyConstants.fontWeightBold : TypographyConstants.fontWeightSemiBold,
            color: const Color(0xFFe5e5e5),
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...content.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              item,
              style: const TextStyle(
                color: Color(0xFFe5e5e5),
                fontSize: TypographyConstants.fontSizeBase,
                height: 1.4,
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSubSection(String title, List<String> items, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: TypographyConstants.fontSizeBase,
            fontWeight: isBold ? TypographyConstants.fontWeightBold : TypographyConstants.fontWeightMedium,
            color: const Color(0xFFe5e5e5),
          ),
        ),
        const SizedBox(height: 8),
        if (items.length == 1 && !items.first.contains(':'))
          // Single paragraph format for SMAs
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              items.first,
              style: const TextStyle(
                color: Color(0xFFe5e5e5),
                fontSize: TypographyConstants.fontSizeBase,
                height: 1.4,
              ),
            ),
          )
        else
          // Bullet list format
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Color(0xFFe5e5e5),
                    fontSize: TypographyConstants.fontSizeBase,
                    fontWeight: TypographyConstants.fontWeightBold,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFFe5e5e5),
                        fontSize: TypographyConstants.fontSizeBase,
                        height: 1.4,
                      ),
                      children: _parseFormattedText(item),
                    ),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  List<TextSpan> _parseFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      
      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}
