import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatting helpers.
///
/// Every screen used to carry its own hand-written weekday/month tables, which
/// meant a third locale could never be added and English fell back to Turkish
/// grouping separators. Everything now goes through `intl` so the format
/// follows whatever locale `Localizations` resolved.

String _localeTag(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// `Monday, 18 August` / `18 Ağustos Pazartesi` — the Today header.
String formatHeaderDate(BuildContext context, DateTime date) =>
    DateFormat.MMMMEEEEd(_localeTag(context)).format(date);

/// Same shape as [formatHeaderDate]; kept separate so History can diverge
/// without touching Today.
String formatFullDate(BuildContext context, DateTime date) =>
    DateFormat.MMMMEEEEd(_localeTag(context)).format(date);

/// `Mon` / `Pzt` — the History day rail.
String formatShortWeekday(BuildContext context, DateTime date) =>
    DateFormat.E(_localeTag(context)).format(date);

/// `14:05` — meal times.
String formatTimeOfDay(BuildContext context, DateTime date) =>
    DateFormat.Hm(_localeTag(context)).format(date);

/// Grouped integer: `2.100` in tr, `2,100` in en.
String formatNumber(BuildContext context, num value) =>
    NumberFormat.decimalPattern(_localeTag(context)).format(value);
