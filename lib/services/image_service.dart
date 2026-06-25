import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static const MethodChannel _downloadChannel =
      MethodChannel('rekty_ai/downloads');

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Ambil gambar dari galeri
  Future<File?> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Ambil gambar dari kamera
  Future<File?> pickFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Simpan bytes gambar (hasil generate Gemini) ke storage lokal permanen.
  /// Mengembalikan path lengkap file yang tersimpan.
  Future<String> saveImageBytes(Uint8List bytes, {String? prefix}) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/rekty_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${prefix ?? "img"}_${_uuid.v4()}.png';
    final filePath = '${imagesDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  Future<String> saveImageToDownloads(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('File gambar tidak ditemukan.');
    }

    final fileName = 'rekty_${_uuid.v4()}.png';
    if (Platform.isAndroid) {
      final savedPath = await _downloadChannel.invokeMethod<String>(
        'saveImageToDownloads',
        {
          'path': sourcePath,
          'fileName': fileName,
        },
      );
      if (savedPath == null || savedPath.isEmpty) {
        throw Exception('Gagal menyimpan ke folder Download.');
      }
      return savedPath;
    }

    final downloadsDir = await getDownloadsDirectory();
    final targetDir = downloadsDir ?? await getApplicationDocumentsDirectory();
    final targetPath = '${targetDir.path}/$fileName';
    await source.copy(targetPath);
    return targetPath;
  }

  /// Copy file gambar yang dipilih user ke folder app (supaya tidak hilang
  /// kalau file aslinya dihapus dari galeri)
  Future<String> persistPickedImage(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/rekty_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = source.path.split('.').last;
    final fileName = 'picked_${_uuid.v4()}.$ext';
    final newPath = '${imagesDir.path}/$fileName';

    final newFile = await source.copy(newPath);
    return newFile.path;
  }

  /// Hapus file gambar dari storage (dipakai saat user delete history)
  Future<void> deleteImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Abaikan error kalau file sudah tidak ada
    }
  }

  String generateId() => _uuid.v4();
}

