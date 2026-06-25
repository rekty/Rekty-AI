import 'package:isar/isar.dart';

part 'image_history.g.dart';

enum ImageActionType {
  generate,
  edit,
}

@collection
class ImageHistory {
  Id id = Isar.autoIncrement;

  late String historyId;

  /// Prompt yang dipakai untuk generate/edit gambar
  late String prompt;

  /// Path lokal file hasil gambar
  late String imagePath;

  /// Path gambar asli (kalau ini hasil edit, bukan generate baru)
  String? sourceImagePath;

  @enumerated
  late ImageActionType type;

  late DateTime createdAt;

  /// Apakah gambar ini di-favorite-kan user
  bool isFavorite = false;

  ImageHistory();

  ImageHistory.create({
    required this.historyId,
    required this.prompt,
    required this.imagePath,
    this.sourceImagePath,
    required this.type,
    DateTime? time,
    this.isFavorite = false,
  }) {
    createdAt = time ?? DateTime.now();
  }
}
