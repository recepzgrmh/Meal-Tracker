import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/liquid_glass_bottom_bar.dart';
import '../../l10n/l10n.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.onNavigationSelected,
    this.showBottomNavigationBar = true,
    super.key,
  });

  final ValueChanged<int> onNavigationSelected;
  final bool showBottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 104),
          children: [
            Text(
              context.ota('profileTitle', tr: 'Profil', en: 'Profile'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 20),
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
                  const SizedBox(height: 8),
                  Text(
                    '2.100 kcal',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.limeDark,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.ota(
                      'goalMacroSummary',
                      tr: '160 g protein · 240 g karbonhidrat · 70 g yağ',
                      en: '160 g protein · 240 g carbs · 70 g fat',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SettingsSection(
              title: context.ota(
                'profilePreferences',
                tr: 'Tercihler',
                en: 'Preferences',
              ),
              rows: [
                _SettingRowData(
                  context.ota(
                    'measurementUnits',
                    tr: 'Ölçü birimleri',
                    en: 'Measurement units',
                  ),
                  context.ota('metricUnits', tr: 'Metrik', en: 'Metric'),
                ),
                _SettingRowData(
                  context.ota(
                    'dietPreferences',
                    tr: 'Beslenme tercihleri',
                    en: 'Diet preferences',
                  ),
                  context.ota(
                    'notSpecified',
                    tr: 'Belirtilmedi',
                    en: 'Not specified',
                  ),
                ),
                _SettingRowData(
                  context.ota('language', tr: 'Dil', en: 'Language'),
                  context.l10n.localeName.startsWith('tr')
                      ? context.ota(
                          'languageTurkish',
                          tr: 'Türkçe',
                          en: 'Turkish',
                        )
                      : context.ota(
                          'languageEnglish',
                          tr: 'İngilizce',
                          en: 'English',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _SettingsSection(
              title: context.ota('profileAccount', tr: 'Hesap', en: 'Account'),
              rows: [
                _SettingRowData(
                  context.ota(
                    'dataStorage',
                    tr: 'Veri saklama',
                    en: 'Data storage',
                  ),
                  context.ota(
                    'secureSync',
                    tr: 'Güvenli eşitleme',
                    en: 'Secure sync',
                  ),
                ),
                _SettingRowData(
                  context.ota(
                    'accountStatus',
                    tr: 'Hesap durumu',
                    en: 'Account status',
                  ),
                  context.ota('activeStatus', tr: 'Etkin', en: 'Active'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNavigationBar
          ? LiquidGlassBottomBar(
              selectedIndex: 4,
              onDestinationSelected: onNavigationSelected,
            )
          : null,
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
        const SizedBox(height: 12),
        StandardCardSurface(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _SettingRow(data: rows[index]),
                if (index < rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 0,
                    endIndent: 0,
                    color: AppColors.separator,
                  ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: largeText
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(data.value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
    );
  }
}

class _SettingRowData {
  const _SettingRowData(this.label, this.value);

  final String label;
  final String value;
}
