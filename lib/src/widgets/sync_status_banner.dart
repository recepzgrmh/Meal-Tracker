import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../sync/sync_status.dart';
import '../theme/app_theme.dart';

/// One line telling the user whether what they logged has left the device.
///
/// Deliberately not a snackbar and not a dialog: sync state is a *condition*,
/// not an event. A banner that stays for as long as the condition does can be
/// ignored by someone who does not care and read by someone who does, whereas a
/// toast per queued meal would fire once per save and say nothing at the moment
/// the user actually wonders.
///
/// The copy never mentions the queue, the retry ladder, or an error code. Only
/// [SyncState.failed] asks for anything, because it is the only state where the
/// app has genuinely stopped trying on its own.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    required this.status,
    required this.onRetry,
    super.key,
  });

  final SyncStatus status;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (status.state == SyncState.settled) return const SizedBox.shrink();

    final failed = status.state == SyncState.failed;
    final message = switch (status.state) {
      SyncState.failed => context.ota(
        'syncFailedMessage',
        tr: 'Bazı öğünler gönderilemedi.',
        en: 'Some meals could not be uploaded.',
      ),
      SyncState.syncing => context.ota(
        'syncingMessage',
        tr: 'Öğünlerin gönderiliyor…',
        en: 'Uploading your meals…',
      ),
      _ => context.ota(
        'syncWaitingMessage',
        tr: '{count} öğün gönderilmeyi bekliyor.',
        en: '{count} meals waiting to upload.',
        replacements: {'count': status.pending},
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('sync-status-banner'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: failed ? AppColors.reviewSurface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Row(
          children: [
            _Leading(state: status.state),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: failed ? AppColors.reviewInk : AppColors.muted,
                ),
              ),
            ),
            if (failed)
              TextButton(
                key: const Key('sync-retry-button'),
                onPressed: () => onRetry(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.reviewInk,
                  minimumSize: const Size(0, AppTouchTarget.minimum),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: Text(
                  context.ota(
                    'commonRetry',
                    tr: 'Tekrar dene',
                    en: 'Try again',
                  ),
                ),
              )
            else
              const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final failed = state == SyncState.failed;
    // Deliberately a static icon, including while syncing.
    //
    // A spinner here would be an indeterminate animation living in a banner
    // that can stay on screen for as long as the condition lasts, so the app
    // would render a frame every 16 ms for the whole time — for a state that is
    // usually over in well under a second. The wording carries the difference
    // between "waiting" and "uploading"; the icon does not have to, and keeping
    // it fixed also means the row cannot change height as the state moves.
    return Icon(
      failed ? Icons.error_outline_rounded : Icons.cloud_upload_outlined,
      size: 18,
      color: failed ? AppColors.reviewInk : AppColors.muted,
    );
  }
}
