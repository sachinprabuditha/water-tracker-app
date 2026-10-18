import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../theme/app_theme.dart';

/// Opens the feedback form as a bottom sheet over the current screen.
/// Sends to `POST /v1/feedback`; shows a thank-you snackbar on success.
Future<void> showFeedbackSheet(BuildContext context) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _FeedbackForm(),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.sky),
            SizedBox(width: 10),
            Expanded(child: Text('Thanks! Your feedback was sent.')),
          ],
        ),
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm();

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  static const _categories = {
    'idea': ('Idea', Icons.lightbulb_outline_rounded),
    'bug': ('Problem', Icons.bug_report_outlined),
    'other': ('Other', Icons.chat_bubble_outline_rounded),
  };
  static const _maxLength = 1000;

  final _message = TextEditingController();
  String _category = 'idea';
  bool _sending = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _failed = false;
    });
    final ok = await context
        .read<ApiClient>()
        .sendFeedback(category: _category, message: _message.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final canSend = _message.text.trim().length >= 3 && !_sending;

    return Padding(
      // Keep the form above the keyboard.
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send feedback', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
                'Ideas, problems, anything. Please don\'t include personal details.',
                style: text.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final e in _categories.entries)
                  ChoiceChip(
                    avatar: Icon(e.value.$2, size: 18),
                    label: Text(e.value.$1),
                    selected: _category == e.key,
                    showCheckmark: false,
                    onSelected: _sending
                        ? null
                        : (_) => setState(() => _category = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              enabled: !_sending,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What would make H2Go better?',
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Couldn\'t send. Check your connection and try again.',
                        style: text.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSend ? _send : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_sending ? 'Sending...' : 'Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
