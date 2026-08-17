import 'dart:typed_data';

enum MealInputKind { text, photo, mixed }

class MealPhotoAttachment {
  const MealPhotoAttachment({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get byteLength => bytes.lengthInBytes;
}

class MealAnalysisInput {
  const MealAnalysisInput({
    required this.text,
    required this.locale,
    this.photo,
  });

  final String text;
  final String locale;
  final MealPhotoAttachment? photo;

  MealInputKind get kind {
    if (photo != null && text.trim().isNotEmpty) return MealInputKind.mixed;
    if (photo != null) return MealInputKind.photo;
    return MealInputKind.text;
  }

  bool get isEmpty => text.trim().isEmpty && photo == null;
}
