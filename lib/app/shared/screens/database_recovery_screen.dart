import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../generated/locale_keys.g.dart';

/// Shown instead of the app when the database file exists but cannot be
/// unlocked with this device's key. Nothing is moved or deleted unless the
/// user explicitly confirms starting over.
class DatabaseRecoveryScreen extends StatefulWidget {
  static const Key retryButtonKey = Key('db_recovery_retry');
  static const Key startFreshButtonKey = Key('db_recovery_start_fresh');
  static const Key confirmStartFreshKey = Key('db_recovery_confirm_start_fresh');
  static const Key cancelStartFreshKey = Key('db_recovery_cancel_start_fresh');

  final String databasePath;
  final Future<void> Function() onRetry;
  final Future<void> Function() onStartFresh;
  final VoidCallback onExit;

  const DatabaseRecoveryScreen({
    super.key,
    required this.databasePath,
    required this.onRetry,
    required this.onStartFresh,
    required this.onExit,
  });

  @override
  State<DatabaseRecoveryScreen> createState() => _DatabaseRecoveryScreenState();
}

class _DatabaseRecoveryScreenState extends State<DatabaseRecoveryScreen> {
  bool _isBusy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmStartFresh() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.db_start_fresh_confirm_title.tr()),
        content: Text(LocaleKeys.db_start_fresh_confirm_message.tr()),
        actions: [
          TextButton(
            key: DatabaseRecoveryScreen.cancelStartFreshKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          FilledButton(
            key: DatabaseRecoveryScreen.confirmStartFreshKey,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.db_start_fresh_confirm.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(widget.onStartFresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 56, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  LocaleKeys.db_unlock_title.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.db_unlock_message.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.db_unlock_hint.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.db_unlock_file_label.tr(),
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.databasePath,
                        textDirection: ui.TextDirection.ltr,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isBusy)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  FilledButton.icon(
                    key: DatabaseRecoveryScreen.retryButtonKey,
                    onPressed: () => _run(widget.onRetry),
                    icon: const Icon(Icons.refresh),
                    label: Text(LocaleKeys.retry.tr()),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: DatabaseRecoveryScreen.startFreshButtonKey,
                    onPressed: _confirmStartFresh,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(LocaleKeys.db_start_fresh.tr()),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onExit,
                    child: Text(LocaleKeys.close_app.tr()),
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
