import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message.dart';
import '../models/image_history.dart';

class IsarService {
  static IsarService? _instance;
  late Isar isar;

  IsarService._();

  /// Singleton accessor — pastikan panggil [init] sekali di awal app (main.dart)
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ChatMessageSchema, ImageHistorySchema],
      directory: dir.path,
    );
  }

  // ---------------------- CHAT MESSAGE ----------------------

  Future<void> saveMessage(ChatMessage message) async {
    await isar.writeTxn(() async {
      await isar.chatMessages.put(message);
    });
  }

  Future<List<ChatMessage>> getMessagesByConversation(
    String conversationId,
  ) async {
    return await isar.chatMessages
        .filter()
        .conversationIdEqualTo(conversationId)
        .sortByTimestamp()
        .findAll();
  }

  Future<List<ChatMessage>> getAllMessages() async {
    return await isar.chatMessages.where().sortByTimestamp().findAll();
  }

  Future<void> deleteMessage(Id id) async {
    await isar.writeTxn(() async {
      await isar.chatMessages.delete(id);
    });
  }

  Future<void> clearConversation(String conversationId) async {
    await isar.writeTxn(() async {
      await isar.chatMessages
          .filter()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
    });
  }

  Future<void> clearAllMessages() async {
    await isar.writeTxn(() async {
      await isar.chatMessages.clear();
    });
  }

  // ---------------------- IMAGE HISTORY ----------------------

  Future<void> saveImageHistory(ImageHistory history) async {
    await isar.writeTxn(() async {
      await isar.imageHistorys.put(history);
    });
  }

  Future<List<ImageHistory>> getAllImageHistory() async {
    return await isar.imageHistorys.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<ImageHistory>> getFavoriteImages() async {
    return await isar.imageHistorys
        .filter()
        .isFavoriteEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> toggleFavorite(Id id) async {
    await isar.writeTxn(() async {
      final item = await isar.imageHistorys.get(id);
      if (item != null) {
        item.isFavorite = !item.isFavorite;
        await isar.imageHistorys.put(item);
      }
    });
  }

  Future<void> deleteImageHistory(Id id) async {
    await isar.writeTxn(() async {
      await isar.imageHistorys.delete(id);
    });
  }

  Future<void> clearAllImageHistory() async {
    await isar.writeTxn(() async {
      await isar.imageHistorys.clear();
    });
  }
}
