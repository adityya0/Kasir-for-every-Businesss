import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class FileManager {
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  Future<String> saveFile(XFile file, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = p.join(appDir.path, filename);
    await file.saveTo(localPath);
    return localPath;
  }

  ImageProvider getImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    // If it's a web URL, use NetworkImage
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    // Otherwise it's a local file - verify existence safely
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return const AssetImage('assets/logo/logo.png');
  }

  Future<Uint8List?> readBytes(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<String?> saveAndShareBytes(
    String filename,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export File',
      );
      return file.path;
    } catch (e) {
      debugPrint("Error sharing file: $e");
      return null;
    }
  }

  /// Saves bytes directly to Downloads (or Documents) folder — no share dialog.
  /// Returns the saved file path, or null on failure.
  Future<String?> saveBytes(
    String filename,
    Uint8List bytes,
  ) async {
    try {
      Directory? saveDir;

      // Try Downloads folder first (Windows / Linux / macOS)
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['USERPROFILE'] // Windows
            ?? Platform.environment['HOME'];              // macOS / Linux
        if (home != null) {
          final downloads = Directory('$home/Downloads');
          if (await downloads.exists()) saveDir = downloads;
        }
      }

      // Fallback: app documents directory
      saveDir ??= await getApplicationDocumentsDirectory();

      final savePath = p.join(saveDir.path, filename);
      await File(savePath).writeAsBytes(bytes);
      return savePath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }
}
