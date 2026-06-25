import 'package:isar/isar.dart';

part 'chat_message.g.dart';

enum MessageRole {
  user,
  ai,
}

enum MessageType {
  text,
  image,
  textWithImage,
}

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  /// ID unik berbasis string (uuid) untuk grouping / referencing
  late String messageId;

  @enumerated
  late MessageRole role;

  @enumerated
  late MessageType type;

  /// Isi teks pesan (bisa kosong kalau cuma gambar)
  late String text;

  /// Path lokal file gambar (kalau ada), disimpan sebagai string path
  String? imagePath;

  /// ID percakapan, untuk mendukung multi-chat session di masa depan
  late String conversationId;

  late DateTime timestamp;

  /// Status pengiriman, dipakai untuk menampilkan loading/error di UI
  @enumerated
  MessageStatus status = MessageStatus.sent;

  ChatMessage();

  ChatMessage.create({
    required this.messageId,
    required this.role,
    required this.type,
    required this.text,
    this.imagePath,
    required this.conversationId,
    DateTime? time,
    this.status = MessageStatus.sent,
  }) {
    timestamp = time ?? DateTime.now();
  }

  // ── copyWith ─────────────────────────────────────────────────────────────
  // Dipakai oleh streaming: update teks partial tanpa replace seluruh object.
  ChatMessage copyWith({
    String? messageId,
    MessageRole? role,
    MessageType? type,
    String? text,
    String? imagePath,
    String? conversationId,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    final copy = ChatMessage.create(
      messageId: messageId ?? this.messageId,
      role: role ?? this.role,
      type: type ?? this.type,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      conversationId: conversationId ?? this.conversationId,
      time: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
    // Pertahankan Isar id asli supaya update ke DB tetap ke row yang sama
    copy.id = id;
    return copy;
  }
}

enum MessageStatus {
  sending,
  sent,
  error,
}
