import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../util/formatters.dart';
import '../domain/nutrition_goals.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../../l10n/l10n.dart';

/// Language options offered by the picker. `system` is the absence of an
/// override, which is why the screen models it explicitly instead of using a
/// nullable [Locale] in the list.
enum _LanguageOption { system, turkish, english }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.goals,
    required this.onNavigationSelected,
    this.locale,
    this.onLocaleChanged,
    this.onSignOut,
    this.onDeleteAccount,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final NutritionGoals goals;
  final ValueChanged<int> onNavigationSelected;

  /// `null` means the app follows the device language.
  final Locale? locale;

  /// Receives `null` when the user picks "follow system". When this is `null`
  /// the language row degrades to a read-only fact instead of a dead control.
  final ValueChanged<Locale?>? onLocaleChanged;

  final Future<void> Function()? onSignOut;

  /// Returns `true` when the account was actually deleted.
  final Future<bool> Function()? onDeleteAccount;

  final bool showBottomNavigationBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    final canChangeLanguage = widget.onLocaleChanged != null;
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.pageBottom(context),
          ),
          children: [
            Text(
              context.ota('profileTitle', tr: 'Profil', en: 'Profile'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            HeroCardSurface(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.ota(
                      'dailyGoalLabel',
                      tr: 'Günlük hedef',
                      en: 'Daily goal',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.ota(
                      'dailyGoalCalories',
                      tr: '{calories} kcal',
                      en: '{calories} kcal',
                      replacements: {
                        'calories': formatNumber(
                          context,
                          goals.calories.round(),
                        ),
                      },
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.limeDark,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.ota(
                      'goalMacroSummaryValues',
                      tr: '{protein} g protein · {carbs} g karbonhidrat · {fat} g yağ',
                      en: '{protein} g protein · {carbs} g carbs · {fat} g fat',
                      replacements: {
                        'protein': formatNumber(context, goals.protein.round()),
                        'carbs': formatNumber(context, goals.carbs.round()),
                        'fat': formatNumber(context, goals.fat.round()),
                      },
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    goals.isDefault
                        ? context.ota(
                            'dailyGoalSourceDefault',
                            tr: 'Uygulamanın varsayılan hedefi. Başlangıç sorularını yeniden yanıtlayarak değiştirebilirsin.',
                            en: 'The app default. Answer the setup questions again to change it.',
                          )
                        : context.ota(
                            'dailyGoalSourceOnboarding',
                            tr: 'Başlangıçta seçtiğin hedefe göre hesaplandı.',
                            en: 'Calculated from the target you chose during setup.',
                          ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x28),
            _SettingsSection(
              title: context.ota(
                'profilePreferences',
                tr: 'Tercihler',
                en: 'Preferences',
              ),
              rows: [
                _SettingRowData(
                  label: context.ota('language', tr: 'Dil', en: 'Language'),
                  value: _languageLabel(context, _selectedOption(context)),
                  onTap: canChangeLanguage ? _pickLanguage : null,
                ),
              ],
            ),
            if (widget.onSignOut != null || widget.onDeleteAccount != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              _SettingsSection(
                title: context.ota(
                  'profileAccount',
                  tr: 'Hesap',
                  en: 'Account',
                ),
                rows: [
                  if (widget.onSignOut != null)
                    _SettingRowData(
                      label: context.ota(
                        'signOutAction',
                        tr: 'Oturumu kapat',
                        en: 'Sign out',
                      ),
                      onTap: _isBusy ? null : _confirmSignOut,
                      rowKey: const Key('profile-sign-out'),
                    ),
                  if (widget.onDeleteAccount != null)
                    _SettingRowData(
                      label: context.ota(
                        'deleteAccountAction',
                        tr: 'Hesabı sil',
                        en: 'Delete account',
                      ),
                      onTap: _isBusy ? null : _confirmDeleteAccount,
                      destructive: true,
                      rowKey: const Key('profile-delete-account'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? LiquidGlassBottomBar(
              selectedIndex: 4,
              onDestinationSelected: widget.onNavigationSelected,
            )
          : null,
    );
  }

  _LanguageOption _selectedOption(BuildContext context) {
    return switch (widget.locale?.languageCode) {
      'tr' => _LanguageOption.turkish,
      'en' => _LanguageOption.english,
      _ => _LanguageOption.system,
    };
  }

  String _languageLabel(BuildContext context, _LanguageOption option) {
    return switch (option) {
      _LanguageOption.turkish => context.ota(
        'languageTurkish',
        tr: 'Türkçe',
        en: 'Turkish',
      ),
      _LanguageOption.english => context.ota(
        'languageEnglish',
        tr: 'İngilizce',
        en: 'English',
      ),
      _LanguageOption.system => context.ota(
        'languageSystem',
        tr: 'Cihaz dili',
        en: 'System language',
      ),
    };
  }

  Future<void> _pickLanguage() async {
    final current = _selectedOption(context);
    final picked = await showModalBottomSheet<_LanguageOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.x28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.ota(
                  'languagePickerTitle',
                  tr: 'Uygulama dili',
                  en: 'App language',
                ),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final option in _LanguageOption.values)
                ListTile(
                  key: Key('language-option-${option.name}'),
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppTouchTarget.minimum,
                  selected: option == current,
                  title: Text(_languageLabel(sheetContext, option)),
                  trailing: option == current
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current) return;
    widget.onLocaleChanged?.call(switch (picked) {
      _LanguageOption.system => null,
      _LanguageOption.turkish => const Locale('tr'),
      _LanguageOption.english => const Locale('en'),
    });
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await _showConfirmationSheet(
      icon: Icons.logout_rounded,
      iconColor: AppColors.ink,
      title: context.ota(
        'signOutConfirmTitle',
        tr: 'Oturum kapatılsın mı?',
        en: 'Sign out?',
      ),
      body: context.ota(
        'signOutConfirmBody',
        tr: 'Hesabın ve kayıtlı öğünlerin silinmez. Tekrar giriş yaptığında her şey yerinde olur.',
        en: 'Your account and logged meals are kept. Everything will be here when you sign in again.',
      ),
      confirmLabel: context.ota(
        'signOutAction',
        tr: 'Oturumu kapat',
        en: 'Sign out',
      ),
      confirmKey: const Key('sign-out-confirm'),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await widget.onSignOut!();
    } catch (_) {
      if (!mounted) return;
      _showError(
        context.ota(
          'signOutError',
          tr: 'Oturum kapatılamadı. Bağlantını kontrol edip tekrar dene.',
          en: 'Could not sign out. Check your connection and try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Step one states plainly what disappears; step two makes the user
    // acknowledge irreversibility on an explicitly unchecked control.
    final wantsToContinue = await _showConfirmationSheet(
      icon: Icons.delete_forever_outlined,
      iconColor: AppColors.destructive,
      title: context.ota(
        'deleteAccountConfirmTitle',
        tr: 'Hesabın kalıcı olarak silinsin mi?',
        en: 'Permanently delete your account?',
      ),
      body: context.ota(
        'deleteAccountConfirmBody',
        tr: 'Hesabın, kayıtlı tüm öğünlerin, öğün fotoğrafların ve başlangıç tercihlerin sunucudan kalıcı olarak silinir. Bu işlem geri alınamaz ve verilerin kurtarılamaz.',
        en: 'Your account, every logged meal, your meal photos and your setup preferences are permanently removed from the server. This cannot be undone and the data cannot be recovered.',
      ),
      confirmLabel: context.ota(
        'commonContinue',
        tr: 'Devam et',
        en: 'Continue',
      ),
      confirmKey: const Key('delete-account-continue'),
      destructive: true,
    );
    if (wantsToContinue != true || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _DeleteAccountFinalDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    var succeeded = false;
    try {
      succeeded = await widget.onDeleteAccount!();
    } catch (_) {
      succeeded = false;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
    if (succeeded || !mounted) return;
    _showError(
      context.ota(
        'deleteAccountError',
        tr: 'Hesap silinemedi. Bağlantını kontrol edip tekrar dene.',
        en: 'Could not delete your account. Check your connection and try again.',
      ),
    );
  }

  Future<bool?> _showConfirmationSheet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    required Key confirmKey,
    bool destructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxs,
            AppSpacing.xl,
            AppSpacing.x28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: AppSpacing.xxl),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                key: confirmKey,
                onPressed: () => Navigator.pop(sheetContext, true),
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: AppColors.destructive,
                        foregroundColor: AppColors.onDark,
                      )
                    : null,
                child: Text(confirmLabel),
              ),
              const SizedBox(height: AppSpacing.tiny),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(
                  context.ota('commonCancel', tr: 'Vazgeç', en: 'Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        content: Text(message),
      ),
    );
  }
}

class _DeleteAccountFinalDialog extends StatefulWidget {
  const _DeleteAccountFinalDialog();

  @override
  State<_DeleteAccountFinalDialog> createState() =>
      _DeleteAccountFinalDialogState();
}

class _DeleteAccountFinalDialogState extends State<_DeleteAccountFinalDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.ota(
          'deleteAccountFinalTitle',
          tr: 'Son onay',
          en: 'Final confirmation',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.ota(
              'deleteAccountFinalBody',
              tr: 'Hesabını sildiğimizde verilerini geri getiremeyiz.',
              en: 'Once your account is deleted we cannot restore your data.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          CheckboxListTile(
            key: const Key('delete-account-acknowledge'),
            value: _acknowledged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) =>
                setState(() => _acknowledged = value ?? false),
            title: Text(
              context.ota(
                'deleteAccountAcknowledge',
                tr: 'Bu işlemin geri alınamayacağını anlıyorum.',
                en: 'I understand this cannot be undone.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.ota('commonCancel', tr: 'Vazgeç', en: 'Cancel')),
        ),
        FilledButton(
          key: const Key('delete-account-confirm'),
          onPressed: _acknowledged ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: AppColors.onDark,
          ),
          child: Text(
            context.ota(
              'deleteAccountFinalAction',
              tr: 'Hesabı kalıcı olarak sil',
              en: 'Delete permanently',
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});

  final String title;
  final List<_SettingRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        StandardCardSurface(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _SettingRow(data: rows[index]),
                if (index < rows.length - 1)
                  const Divider(height: 1, color: AppColors.separator),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.data});

  final _SettingRowData data;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
    final labelColor = data.destructive ? AppColors.destructive : null;
    final label = Text(
      data.label,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: labelColor),
    );
    final value = data.value == null
        ? null
        : Text(data.value!, style: Theme.of(context).textTheme.bodyMedium);
    final chevron = data.onTap == null
        ? null
        : Icon(
            Icons.chevron_right_rounded,
            size: AppSpacing.lg,
            color: data.destructive ? AppColors.destructive : AppColors.muted,
          );

    final Widget content = largeText
        ? Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    if (value != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      value,
                    ],
                  ],
                ),
              ),
              ?chevron,
            ],
          )
        : Row(
            children: [
              Expanded(child: label),
              ?value,
              if (chevron != null) ...[
                const SizedBox(width: AppSpacing.xs),
                chevron,
              ],
            ],
          );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.minimum),
        child: Align(alignment: Alignment.centerLeft, child: content),
      ),
    );

    if (data.onTap == null) {
      // Read-only fact: no chevron, no gesture, and no button semantics so it
      // is never announced as something the user can activate.
      return padded;
    }
    return Semantics(
      button: true,
      label: data.label,
      value: data.value,
      child: InkWell(key: data.rowKey, onTap: data.onTap, child: padded),
    );
  }
}

class _SettingRowData {
  const _SettingRowData({
    required this.label,
    this.value,
    this.onTap,
    this.destructive = false,
    this.rowKey,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  final Key? rowKey;
}
