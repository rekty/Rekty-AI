import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../services/image_service.dart';
import 'package:markdown_widget/markdown_widget.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;   // ← BARU: true saat teks masih dikirim token per token
  final VoidCallback? onImageTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onImageTap,
    this.onRetry,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  final ImageService _imageService = ImageService();
  int _feedback = 0;
  bool _downloading = false;

  // Animasi kursor berkedip saat streaming
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  bool get isUser => widget.message.role == MessageRole.user;
  ChatMessage get message => widget.message;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _cursorOpacity = Tween<double>(begin: 0, end: 1).animate(_cursorController);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: message.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teks berhasil disalin.')),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode berhasil disalin')),
    );
  }

  Future<void> _downloadImage() async {
    if (message.imagePath == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      await _imageService.saveImageToDownloads(message.imagePath!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar tersimpan di folder Download.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal download gambar: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF008CFF)],
                      )
                    : null,
                color: isUser ? null : const Color(0xFF101417),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? const Color(0x8800E5FF) : Colors.white12,
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null) _buildImage(),
                  if (message.imagePath != null && message.text.isNotEmpty)
                    const SizedBox(height: 8),
                  if (message.text.isNotEmpty) _buildText(),
                  if (message.text.isNotEmpty) _buildCodeCopyButton(),
                  if (message.status == MessageStatus.error) _buildErrorRetry(),
                  // Action row hanya muncul setelah streaming selesai
                  if (!widget.isStreaming &&
                      (message.text.isNotEmpty || message.imagePath != null))
                    _buildActionRow(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    if (isUser) {
      return Text(
        message.text,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      );
    }

    // Saat streaming: tampilkan teks biasa + kursor berkedip
    // (MarkdownBlock bisa lag/jump saat update sangat cepat)
    if (widget.isStreaming) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          // Kursor berkedip
          FadeTransition(
            opacity: _cursorOpacity,
            child: Container(
              width: 2,
              height: 18,
              margin: const EdgeInsets.only(left: 2, bottom: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      );
    }

    // Setelah selesai: render Markdown penuh
    return MarkdownBlock(
      data: message.text,
      selectable: true,
    );
  }

  Widget _buildCodeCopyButton() {
    // Jangan tampilkan saat masih streaming
    if (widget.isStreaming) return const SizedBox.shrink();

    final regex = RegExp(r'```[\s\S]*?```', multiLine: true);
    if (!regex.hasMatch(message.text)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            final match = regex.firstMatch(message.text);
            if (match == null) return;
            var code = match.group(0)!;
            code = code
                .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
                .replaceFirst('```', '');
            _copyCode(code.trim());
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF101417),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5FF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.content_copy,
                    size: 16, color: Color(0xFF00E5FF)),
                SizedBox(width: 6),
                Text('Salin Code',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.black),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Image.file(File(message.imagePath!)),
                ),
              ),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(message.imagePath!),
          fit: BoxFit.cover,
          width: 240,
          errorBuilder: (context, error, stack) => Container(
            width: 240,
            height: 160,
            color: Colors.white10,
            child: const Icon(Icons.broken_image, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (message.text.isNotEmpty)
            _actionButton(Icons.copy, 'Salin', _copyText),
          if (isUser && widget.onEdit != null)
            _actionButton(Icons.edit_outlined, 'Edit', widget.onEdit!),
          if (widget.onDelete != null)
            _actionButton(Icons.delete_outline, 'Hapus', widget.onDelete!),
          _actionButton(
            Icons.thumb_up_alt_outlined,
            'Like',
            () => setState(() => _feedback = _feedback == 1 ? 0 : 1),
            active: _feedback == 1,
          ),
          _actionButton(
            Icons.thumb_down_alt_outlined,
            'Dislike',
            () => setState(() => _feedback = _feedback == -1 ? 0 : -1),
            active: _feedback == -1,
          ),
          if (message.imagePath != null)
            _actionButton(
              _downloading ? Icons.hourglass_empty : Icons.download,
              'Download',
              _downloadImage,
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0x2200E5FF)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 15),
            const SizedBox(width: 5),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRetry() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 6),
          const Text('Gagal mengirim',
              style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          if (widget.onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRetry,
              child: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
