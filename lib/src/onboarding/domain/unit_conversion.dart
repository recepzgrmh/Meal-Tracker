/// Imperial input is a display concern only: everything downstream — the
/// calculator, the draft, the `profiles` row — stores centimetres and
/// kilograms, so the conversion lives here and nowhere else.
library;

const _cmPerInch = 2.54;
const _inchesPerFoot = 12;
const _kgPerPound = 0.45359237;

/// Height in feet and whole inches, e.g. 5 ft 11 in.
class ImperialHeight {
  const ImperialHeight({required this.feet, required this.inches});

  final int feet;
  final int inches;

  double get centimetres => (feet * _inchesPerFoot + inches) * _cmPerInch;

  /// Rounds to the nearest whole inch, then carries 12 in up to a foot so
  /// `5 ft 12 in` can never be shown.
  factory ImperialHeight.fromCentimetres(double value) {
    final totalInches = (value / _cmPerInch).round();
    return ImperialHeight(
      feet: totalInches ~/ _inchesPerFoot,
      inches: totalInches % _inchesPerFoot,
    );
  }
}

double poundsToKilograms(double pounds) => pounds * _kgPerPound;

double kilogramsToPounds(double kilograms) => kilograms / _kgPerPound;
