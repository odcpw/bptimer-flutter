/// AboutScreen - About section using markdown content system
/// 
/// Loads content from assets/content/about.md and renders with markdown
/// while maintaining the same visual styling as before.

library;

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../services/content_service.dart';
import '../utils/markdown_styles.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final ContentService _contentService = ContentService();
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final result = await _contentService.getAboutContent();
    if (mounted) {
      setState(() {
        _content = result.isSuccess ? result.data! : 'Failed to load content';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: AppScaffoldBody(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: GptMarkdown(
                  _content ?? '',
                  style: createMarkdownTextStyle(),
                ),
              ),
      ),
    );
  }
}
