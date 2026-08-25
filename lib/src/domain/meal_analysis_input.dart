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
    this.requestId,
  });

  final String text;
  final String locale;
  final MealPhotoAttachment? photo;

  /// Identifies the user's *intent*, not the network call.
  ///
  /// The server stores analysis runs under `(user_id, client_request_id)` and
  /// replays a completed one instead of re-running the pipeline. That only
  /// works if a retry of the same meal carries the same id — minting a fresh
  /// one per call, which is what happened before, made the replay path
  /// unreachable and charged a full set of provider calls for every retry.
  ///
  /// Null on the first attempt; the repository mints one and the view model
  /// holds it for as long as the user is retrying the same input.
  final String? requestId;

  MealAnalysisInput withRequestId(String id) => MealAnalysisInput(
    text: text,
    locale: locale,
    photo: photo,
    requestId: id,
  );

  MealInputKind get kind {
    if (photo != null && text.trim().isNotEmpty) return MealInputKind.mixed;
    if (photo != null) return MealInputKind.photo;
    return MealInputKind.text;
  }

  bool get isEmpty => text.trim().isEmpty && photo == null;
}
