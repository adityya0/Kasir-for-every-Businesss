import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';

class FileManager {
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  Future<String> saveFile(XFile file, String filename) async {
    // On web, we cannot persist files to filesystem easily.
    // For now, return the blob URL.
    return file.path;
  }

  ImageProvider getImageProvider(String path) {
    // On web, path is likely a URL (blob or http)
    return NetworkImage(path);
  }

  Future<Uint8List?> readBytes(String path) async {
    try {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint("Error reading bytes web: $e");
    }
    return null;
  }

  Future<String?> saveAndShareBytes(
    String filename,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      mimeType: MimeType.other, // file_saver handles extension usually
    );
    return "Downloaded $filename";
  }

  Future<String?> saveBytes(String filename, Uint8List bytes) async {
    return await saveAndShareBytes(filename, bytes);
  }
}
