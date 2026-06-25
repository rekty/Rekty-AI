import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/image_history.dart';
import '../services/isar_service.dart';
import '../services/image_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final IsarService _isarService = IsarService.instance;
  final ImageService _imageService = ImageService();

  List<ImageHistory> _history = [];
  bool _isLoading = true;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = _favoritesOnly
        ? await _isarService.getFavoriteImages()
        : await _isarService.getAllImageHistory();
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(ImageHistory item) async {
    await _isarService.toggleFavorite(item.id);
    _loadHistory();
  }

  Future<void> _deleteItem(ImageHistory item) async {
    await _isarService.deleteImageHistory(item.id);
    await _imageService.deleteImageFile(item.imagePath);
    _loadHistory();
  }

  void _showFullImage(ImageHistory item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(item.imagePath)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.prompt,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title:
            const Text('Riwayat Gambar', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _favoritesOnly ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              setState(() => _favoritesOnly = !_favoritesOnly);
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : _history.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildGridItem(item);
                  },
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
            const Icon(Icons.image_outlined, color: Colors.white24, size: 56),
            const SizedBox(height: 16),
            Text(
              _favoritesOnly
                  ? 'Belum ada gambar favorit.'
                  : 'Belum ada riwayat gambar.\nCoba generate gambar di tab Chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(ImageHistory item) {
    return GestureDetector(
      onTap: () => _showFullImage(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(item.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white38),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _toggleFavorite(item),
                        child: Icon(
                          item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              item.isFavorite ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmDelete(item),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    item.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ImageHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title:
            const Text('Hapus gambar?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Gambar ini akan dihapus permanen dari riwayat.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            child:
                const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

