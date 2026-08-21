/// A food that cannot be resolved from a published row.
///
/// Thrown per food and caught by the manifest builder, which turns it into
/// blocked rows plus an `openGaps` entry and carries on. At pilot scale an
/// uncaught throw was tolerable; across 200 foods a single ambiguous TÜBER row
/// would otherwise abort the whole batch and produce no output at all.
class CatalogBuildException implements Exception {
  const CatalogBuildException(
    this.message, {
    this.searchedSources = const <String>[],
    this.resolutionPath =
        'Cite a published TÜBER row for this food, or leave it blocked so the '
        'app asks the user for the amount.',
  });

  final String message;
  final List<String> searchedSources;
  final String resolutionPath;

  @override
  String toString() => 'CatalogBuildException: $message';
}
