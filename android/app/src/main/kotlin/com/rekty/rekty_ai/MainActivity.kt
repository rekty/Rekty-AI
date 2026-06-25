package com.rekty.rekty_ai

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val channelName = "rekty_ai/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "saveImageToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val fileName = call.argument<String>("fileName") ?: "rekty_image.png"
            if (path.isNullOrBlank()) {
                result.error("INVALID_PATH", "Path gambar kosong", null)
                return@setMethodCallHandler
            }

            try {
                val savedPath = saveImageToDownloads(path, fileName)
                result.success(savedPath)
            } catch (e: Exception) {
                result.error("SAVE_FAILED", e.message, null)
            }
        }
    }

    private fun saveImageToDownloads(sourcePath: String, fileName: String): String {
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalArgumentException("File gambar tidak ditemukan")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "image/png")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Rekty AI")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Tidak bisa membuat file Download")

            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("Tidak bisa menulis file Download")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        }

        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val rektyDir = File(downloadsDir, "Rekty AI")
        if (!rektyDir.exists()) rektyDir.mkdirs()
        val target = File(rektyDir, fileName)
        source.copyTo(target, overwrite = true)
        return target.absolutePath
    }
}
