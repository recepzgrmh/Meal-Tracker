import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Renders whatever a meal has for a picture, and never lets that decision
/// break the screen around it.
///
/// `LoggedMeal.imageAsset` is one nullable string carrying three different
/// kinds of value, which is why this exists:
///
///  * `null` — most meals. There is no photo and there never was one.
///  * a bundled asset path — the seeded demo meals.
///  * a server-side Storage object path — [MealRemoteDto.imagePath] is copied
///    straight into this field by the persistence mapper, so any meal synced
///    down from the server arrives holding one.
///
/// The list tile and the detail screen both used to call `Image.asset` on it
/// unconditionally. For the third case that throws during build and takes the
/// row — or the whole detail screen — down with it. Classifying the source and
/// falling back to the neutral placeholder turns a crash into a missing photo,
/// which is what a missing photo should look like.
///
/// Storage paths still render as the placeholder: reaching a private object
/// needs a signed URL, and inventing one here would be guessing at the bucket
/// layout. The placeholder is the honest answer until that path is wired.
class MealPhoto extends StatelessWidget {
  const MealPhoto({
    required this.source,
    required this.placeholderIconSize,
    this.cacheWidth,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? source;
  final double placeholderIconSize;

  /// Decode budget. The tile asks for a thumbnail-sized decode so an 88 px
  /// square never holds a full-resolution bitmap in the image cache.
  final int? cacheWidth;

  final BoxFit fit;

  static bool _isAsset(String value) => value.startsWith('assets/');

  static bool _isNetwork(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final value = source;
    if (value == null || value.isEmpty) return _placeholder;

    if (_isNetwork(value)) {
      return Image.network(
        value,
        fit: fit,
        cacheWidth: cacheWidth,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder,
        errorBuilder: (_, _, _) => _placeholder,
      );
    }

    if (!_isAsset(value)) return _placeholder;

    return Image.asset(
      value,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => _placeholder,
    );
  }

  Widget get _placeholder => ColoredBox(
    color: AppColors.surfaceMuted,
    child: Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: placeholderIconSize,
        color: AppColors.muted,
      ),
    ),
  );
}
