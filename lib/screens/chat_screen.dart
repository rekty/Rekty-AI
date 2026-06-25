import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/image_history.dart';
import '../services/gemini_service.dart';
import '../services/image_service.dart';
import '../services/isar_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/loading_widget.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../services/language_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiService _geminiService = GeminiService();
  final IsarService _isarService = IsarService.instance;
  final ImageService _imageService = ImageService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  final Uuid _uuid = const Uuid();

  late String _conversationId;
  List<ChatMessage> _messages = [];
  File? _attachedImage;
  bool _isLoading = false;
  bool _imageGenMode = false;
  String _lastPromptUsed = '';
  bool _lastWasEdit = false;
  String _selectedLanguage = 'Indonesia';

  // ── Streaming state ──────────────────────────────────────────────────────
  bool _isStreaming = false;
  StreamSubscription<String>? _streamSubscription;
  String _streamingText = '';
  String? _streamingMessageId;

  @override
  void initState() {
    super.initState();
    _conversationId = _uuid.v4();
    _loadLanguage();
    _loadHistory();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final distanceFromBottom =
          _scrollController.position.maxScrollExtent - _scrollController.offset;

      final show = distanceFromBottom > 300;

      if (show != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = show;
        });
      }
    });
  }

  Future<void> _loadLanguage() async {
    final language = await LanguageService.instance.getLanguage();
    if (!mounted) return;
    setState(() {
      _selectedLanguage = language ?? 'Indonesia';
    });
  }

  Future<void> _loadHistory() async {
    // kosong — history dimuat saat buka conversation
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String tr(String key) {
    if (_selectedLanguage == 'English') {
      switch (key) {
        case 'ai_image':
          return 'AI Image';
        case 'type_message':
          return 'Type a message...';
        case 'start_chat':
          return 'Start a conversation with Rekty AI.\nAsk anything!';
        case 'image_prompt':
          return 'Describe the image you want...';
        case 'history_chat':
          return 'Chat History';
        case 'image_history':
          return 'Image History';
        case 'settings':
          return 'Settings';
        case 'new_chat':
          return 'New Chat';
        case 'delete_message':
          return 'Delete Message';
        case 'delete_confirm':
          return 'Are you sure you want to delete this message?';
        case 'cancel':
          return 'Cancel';
        case 'delete':
          return 'Delete';
        case 'stop_generating':
          return 'Stop';
        default:
          return key;
      }
    }

    switch (key) {
      case 'ai_image':
        return 'Gambar AI';
      case 'type_message':
        return 'Tulis pesan...';
      case 'start_chat':
        return 'Mulai percakapan dengan Rekty AI.\nTanya apa saja!';
      case 'image_prompt':
        return 'Deskripsikan gambar yang kamu mau...';
      case 'history_chat':
        return 'History Chat';
      case 'image_history':
        return 'Riwayat Gambar';
      case 'settings':
        return 'Pengaturan';
      case 'new_chat':
        return 'Chat Baru';
      case 'delete_message':
        return 'Hapus Pesan';
      case 'delete_confirm':
        return 'Yakin ingin menghapus pesan ini?';
      case 'cancel':
        return 'Batal';
      case 'delete':
        return 'Hapus';
      case 'stop_generating':
        return 'Stop';
      default:
        return key;
    }
  }

  Future<void> _startNewChat() async {
    _stopStreaming(); // batalkan stream yang sedang berjalan
    _geminiService.clearHistory();
    setState(() {
      _conversationId = _uuid.v4();
      _messages = [];
      _attachedImage = null;
      _imageGenMode = false;
      _textController.clear();
    });
  }

  Future<void> _openConversation(String conversationId) async {
    _stopStreaming();
    _geminiService.clearHistory();
    final msgs = await _isarService.getMessagesByConversation(conversationId);
    if (!mounted) return;
    setState(() {
      _conversationId = conversationId;
      _messages = msgs;
      _attachedImage = null;
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  Future<void> _deleteConversation(String conversationId) async {
    await _isarService.clearConversation(conversationId);
    if (_conversationId == conversationId) {
      await _startNewChat();
    }
    if (!mounted) return;
    Navigator.pop(context);
    _showChatHistory();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final file = fromCamera
        ? await _imageService.pickFromCamera()
        : await _imageService.pickFromGallery();
    if (file != null) {
      setState(() => _attachedImage = file);
    }
  }

  // ── Stop Streaming ───────────────────────────────────────────────────────

  /// Hentikan stream yang sedang berjalan dan simpan teks yang sudah terkumpul.
  Future<void> _stopStreaming() async {
    if (!_isStreaming) return;

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    // Simpan teks partial ke Isar supaya tidak hilang
    if (_streamingMessageId != null && _streamingText.isNotEmpty) {
      final idx = _messages.indexWhere(
        (m) => m.messageId == _streamingMessageId,
      );
      if (idx != -1) {
        final partial = _messages[idx].copyWith(
          text: _streamingText.trim(),
        );
        _messages[idx] = partial;
        await _isarService.saveMessage(partial);
      }
    }

    if (!mounted) return;
    setState(() {
      _isStreaming = false;
      _isLoading = false;
      _streamingText = '';
      _streamingMessageId = null;
    });
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;

    final hasImage = _attachedImage != null;
    String? persistedImagePath;
    if (hasImage) {
      persistedImagePath =
          await _imageService.persistPickedImage(_attachedImage!);
    }

    final userMessage = ChatMessage.create(
      messageId: _uuid.v4(),
      role: MessageRole.user,
      type: hasImage
          ? (text.isEmpty ? MessageType.image : MessageType.textWithImage)
          : MessageType.text,
      text: text,
      imagePath: persistedImagePath,
      conversationId: _conversationId,
    );

    await _isarService.saveMessage(userMessage);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    final imageFileForRequest = _attachedImage;
    setState(() => _attachedImage = null);

    // Mode gambar tetap pakai non-streaming (tidak bisa di-stream)
    if (_imageGenMode) {
      _lastPromptUsed = text;
      GeminiResult result;
      if (imageFileForRequest != null) {
        // Ada gambar di-attach → edit/img2img via Pollinations (kontext/gptimage)
        _lastWasEdit = true;
        result = await _geminiService.editImage(imageFileForRequest, text);
      } else {
        _lastWasEdit = false;
        result = await _geminiService.generateImage(text);
      }
      await _handleAiResult(result);
      return;
    }

    // ── Mode chat: gunakan streaming ─────────────────────────────────────
    await _handleSendStream(text, imageFile: imageFileForRequest);
  }

  Future<void> _handleSendStream(String text, {File? imageFile}) async {
    // Buat placeholder pesan AI kosong dulu
    final aiMessageId = _uuid.v4();
    final placeholder = ChatMessage.create(
      messageId: aiMessageId,
      role: MessageRole.ai,
      type: MessageType.text,
      text: '',
      conversationId: _conversationId,
    );

    setState(() {
      _messages.add(placeholder);
      _isStreaming = true;
      _isLoading = false; // loading widget digantikan oleh streaming bubble
      _streamingText = '';
      _streamingMessageId = aiMessageId;
    });
    _scrollToBottom();

    // Ambil history sebelum pesan user saat ini (exclude pesan terakhir yg baru ditambahkan)
    final history = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final stream = _geminiService.sendChatMessageStream(
      text,
      imageFile: imageFile,
      historyMessages: history,
    );

    _streamSubscription = stream.listen(
      (chunk) {
        if (!mounted) return;
        _streamingText += chunk;

        // Update teks di message list secara langsung
        final idx = _messages.indexWhere((m) => m.messageId == aiMessageId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(text: _streamingText);
        }

        setState(() {});
        _scrollToBottom();
      },
      onDone: () async {
        // Stream selesai — simpan ke Isar
        final idx = _messages.indexWhere((m) => m.messageId == aiMessageId);
        if (idx != -1) {
          final finalMsg = _messages[idx].copyWith(
            text: _streamingText.trim(),
          );
          _messages[idx] = finalMsg;
          await _isarService.saveMessage(finalMsg);
        }

        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _streamingText = '';
          _streamingMessageId = null;
          _streamSubscription = null;
        });
        _scrollToBottom();
      },
      onError: (e) async {
        final idx = _messages.indexWhere((m) => m.messageId == aiMessageId);
        if (idx != -1) {
          final errMsg = _messages[idx].copyWith(
            text: _streamingText.isEmpty
                ? 'Terjadi kesalahan. Silakan coba lagi.'
                : _streamingText.trim(),
            status: MessageStatus.error,
          );
          _messages[idx] = errMsg;
          await _isarService.saveMessage(errMsg);
        }

        if (!mounted) return;
        setState(() {
          _isStreaming = false;
          _streamingText = '';
          _streamingMessageId = null;
          _streamSubscription = null;
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _handleAiResult(GeminiResult result) async {
    if (!result.success) {
      final errorMessage = ChatMessage.create(
        messageId: _uuid.v4(),
        role: MessageRole.ai,
        type: MessageType.text,
        text: result.errorMessage ?? 'Terjadi kesalahan tidak diketahui.',
        conversationId: _conversationId,
        status: MessageStatus.error,
      );
      await _isarService.saveMessage(errorMessage);
      if (!mounted) return;
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    String? savedImagePath;
    if (result.imageBytes != null) {
      savedImagePath = await _imageService.saveImageBytes(
        result.imageBytes!,
        prefix: _imageGenMode ? 'gen' : 'chat',
      );

      if (_imageGenMode) {
        final history = ImageHistory.create(
          historyId: _uuid.v4(),
          prompt: _lastPromptUsed,
          imagePath: savedImagePath,
          type: _lastWasEdit ? ImageActionType.edit : ImageActionType.generate,
        );
        await _isarService.saveImageHistory(history);
      }
    }

    final aiMessage = ChatMessage.create(
      messageId: _uuid.v4(),
      role: MessageRole.ai,
      type: savedImagePath != null
          ? (result.text != null && result.text!.isNotEmpty
              ? MessageType.textWithImage
              : MessageType.image)
          : MessageType.text,
      text: result.text ?? '',
      imagePath: savedImagePath,
      conversationId: _conversationId,
    );

    await _isarService.saveMessage(aiMessage);
    if (!mounted) return;
    setState(() {
      _messages.add(aiMessage);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF008CFF)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Rekty AI',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined,
                color: Color(0xFF00E5FF)),
            onPressed: (_isLoading || _isStreaming) ? null : _startNewChat,
            tooltip: tr('new_chat'),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: (_isLoading || _isStreaming) ? null : _showChatHistory,
            tooltip: tr('history_chat'),
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.white),
            onPressed: (_isLoading || _isStreaming)
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
            tooltip: tr('image_history'),
          ),
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: (_isLoading || _isStreaming)
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                    await _loadLanguage();
                  },
            tooltip: tr('settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildModeToggle(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return LoadingWidget(
                              label: _imageGenMode
                                  ? 'Sedang membuat gambar...'
                                  : 'Rekty AI sedang mengetik...',
                            );
                          }

                          final msg = _messages[index];
                          final isStreamingBubble =
                              msg.messageId == _streamingMessageId;

                          return ChatBubble(
                            message: msg,
                            isStreaming: isStreamingBubble,
                            onEdit: msg.role == MessageRole.user
                                ? () async {
                                    _textController.text = msg.text;
                                    await _isarService.deleteMessage(msg.id);
                                    if (!mounted) return;
                                    setState(() => _messages.removeAt(index));
                                    _inputFocusNode.requestFocus();
                                  }
                                : null,
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(tr('delete_message')),
                                  content: Text(tr('delete_confirm')),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(tr('cancel')),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(tr('delete')),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              await _isarService.deleteMessage(msg.id);
                              if (!mounted) return;
                              setState(() => _messages.removeAt(index));
                            },
                          );
                        },
                      ),
              ),
              if (_attachedImage != null) _buildAttachedPreview(),
              _buildInputBar(),
            ],
          ),

          // ── Scroll to bottom button ────────────────────────────────────
          if (_showScrollToBottom)
            Positioned(
              bottom: 80 + MediaQuery.of(context).padding.bottom,
              right: 16,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101417),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x8800E5FF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF00E5FF),
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF05090B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3300E5FF)),
      ),
      child: Row(
        children: [
          _modeButton('Chat', !_imageGenMode, () {
            if (_isLoading || _isStreaming) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tunggu proses selesai terlebih dahulu')),
              );
              return;
            }
            setState(() => _imageGenMode = false);
          }),
          _modeButton(tr('ai_image'), _imageGenMode, () {
            if (_isLoading || _isStreaming) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Tunggu proses selesai terlebih dahulu')),
              );
              return;
            }
            setState(() => _imageGenMode = true);
          }),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF008CFF)])
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 56),
            const SizedBox(height: 16),
            Text(
              _imageGenMode
                  ? 'Tulis prompt untuk membuat gambar,\natau lampirkan gambar untuk diedit AI.'
                  : tr('start_chat'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF101417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3300E5FF)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_attachedImage!,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Gambar terlampir',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => setState(() => _attachedImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bool isBusy = _isLoading || _isStreaming;

    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(top: BorderSide(color: Color(0x3300E5FF), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined,
                color: Color(0xFF00E5FF)),
            onPressed: isBusy ? null : _showAttachOptions,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF101417),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x3300E5FF)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 8,
                enabled: !isBusy,
                decoration: InputDecoration(
                  hintText: _imageGenMode
                      ? tr('image_prompt')
                      : tr('type_message'),
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Tombol Send / Stop ─────────────────────────────────────────
          GestureDetector(
            onTap: _isStreaming
                ? _stopStreaming       // saat streaming → Stop
                : (_isLoading ? null : _handleSend), // saat loading gambar → disabled
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF008CFF)]),
                color: _isLoading ? Colors.white12 : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.28),
                          blurRadius: 14,
                        )
                      ],
              ),
              child: Icon(
                _isStreaming
                    ? Icons.stop_rounded          // ikon Stop saat streaming
                    : (_imageGenMode
                        ? Icons.auto_awesome
                        : Icons.send),
                color: _isLoading ? Colors.white54 : Colors.black,
                size: _isStreaming ? 22 : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF00E5FF)),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF00E5FF)),
              title: const Text('Ambil Foto',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChatHistory() async {
    final messages = await _isarService.getAllMessages();
    if (!mounted) return;
    final threads = _buildThreads(messages);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF05090B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('history_chat'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment_outlined,
                          color: Color(0xFF00E5FF)),
                      onPressed: () {
                        Navigator.pop(context);
                        _startNewChat();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: threads.isEmpty
                    ? const Center(
                        child: Text('Belum ada history chat.',
                            style: TextStyle(color: Colors.white38)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: threads.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _historyTile(threads[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ChatThread> _buildThreads(List<ChatMessage> messages) {
    final grouped = <String, List<ChatMessage>>{};
    for (final message in messages) {
      grouped.putIfAbsent(message.conversationId, () => []).add(message);
    }

    final threads = grouped.entries.map((entry) {
      final items = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return _ChatThread(
        conversationId: entry.key,
        title: _threadTitle(items),
        lastMessage: items.last.text.isEmpty ? 'Gambar' : items.last.text,
        updatedAt: items.last.timestamp,
        count: items.length,
      );
    }).toList();
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  String _threadTitle(List<ChatMessage> messages) {
    ChatMessage? firstUser;
    for (final message in messages) {
      if (message.role == MessageRole.user) {
        firstUser = message;
        break;
      }
    }
    final title = firstUser?.text.trim();
    if (title == null || title.isEmpty) return 'Chat gambar';
    return title.length > 42 ? '${title.substring(0, 42)}...' : title;
  }

  Widget _historyTile(_ChatThread thread) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3300E5FF)),
      ),
      child: ListTile(
        onTap: () => _openConversation(thread.conversationId),
        leading:
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF00E5FF)),
        title: Text(
          thread.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${thread.count} pesan - ${DateFormat('dd MMM, HH:mm').format(thread.updatedAt)}\n${thread.lastMessage}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDeleteConversation(thread.conversationId),
        ),
      ),
    );
  }

  void _confirmDeleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title:
            const Text('Hapus chat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Percakapan ini akan dihapus permanen dari history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversationId);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ChatThread {
  final String conversationId;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;
  final int count;

  const _ChatThread({
    required this.conversationId,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    required this.count,
  });
}
