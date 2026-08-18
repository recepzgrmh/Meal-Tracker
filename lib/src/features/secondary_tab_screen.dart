import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/liquid_glass_bottom_bar.dart';

class SecondaryTabScreen extends StatelessWidget {
  const SecondaryTabScreen({
    required this.selectedIndex,
    required this.title,
    required this.description,
    required this.icon,
    required this.onNavigationSelected,
    super.key,
  });

  final int selectedIndex;
  final String title;
  final String description;
  final IconData icon;
  final ValueChanged<int> onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 96),
          children: [
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.feature),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppColors.limeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.limeDark, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LiquidGlassBottomBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onNavigationSelected,
      ),
    );
  }
}
