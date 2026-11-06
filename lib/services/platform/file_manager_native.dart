import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';

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

  String _getUniqueFilename(String dirPath, String originalFilename) {
    var file = File(p.join(dirPath, originalFilename));
    if (!file.existsSync()) return originalFilename;

    final nameWithoutExt = p.basenameWithoutExtension(originalFilename);
    final ext = p.extension(originalFilename);
    int count = 1;
    while (file.existsSync()) {
      final candidate = '$nameWithoutExt($count)$ext';
      file = File(p.join(dirPath, candidate));
      count++;
    }
    return p.basename(file.path);
  }

  MimeType _getMimeType(String? mimeType, String filename) {
    if (mimeType == 'application/pdf' || filename.toLowerCase().endsWith('.pdf')) {
      return MimeType.pdf;
    }
    if ((mimeType != null && mimeType.contains('sheet')) ||
        filename.toLowerCase().endsWith('.xlsx')) {
      return MimeType.microsoftExcel;
    }
    if (filename.toLowerCase().endsWith('.csv')) {
      return MimeType.csv;
    }
    return MimeType.other;
  }

  /// Saves bytes directly to the device's public Downloads folder.
  /// Works reliably on Android, Windows, macOS, and Linux.
  /// Returns the absolute path of the saved file.
  Future<String?> saveBytes(
    String filename,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    try {
      // 1. Android public Download directory
      if (Platform.isAndroid) {
        // Priority 1: Native Android MediaStore download injection
        // Uses Android MediaStore.Downloads API which is the official, guaranteed way on
        // Android 10, 11, 12, 13, 14, 15 to write directly into public Download folder
        // and register with MediaScanner so files are instantly visible in the Downloads app!
        try {
          const channel = MethodChannel('com.kakilima.pos/downloads');
          final String? nativePath = await channel.invokeMethod<String>(
            'saveToPublicDownloads',
            {
              'fileName': filename,
              'bytes': bytes,
              'mimeType': mimeType ?? 'application/octet-stream',
            },
          );
          if (nativePath != null && nativePath.isNotEmpty) {
            debugPrint("FileManager: Successfully saved via MediaStore to public Download: $nativePath");
            return nativePath;
          }
        } catch (e) {
          debugPrint("FileManager: Native MediaStore method channel error: $e");
        }

        final candidates = [
          Directory('/storage/emulated/0/Download'),
          Directory('/sdcard/Download'),
        ];

        for (final dir in candidates) {
          try {
            if (await dir.exists()) {
              final uniqueName = _getUniqueFilename(dir.path, filename);
              final target = p.join(dir.path, uniqueName);
              final f = File(target);
              await f.writeAsBytes(bytes, flush: true);
              debugPrint("FileManager: Saved directly to Android public Download: $target");
              return target;
            }
          } catch (e) {
            debugPrint("FileManager: Failed writing to ${dir.path}: $e");
          }
        }

        // Try app external downloads directory
        try {
          final extDirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (extDirs != null && extDirs.isNotEmpty) {
            final uniqueName = _getUniqueFilename(extDirs.first.path, filename);
            final target = p.join(extDirs.first.path, uniqueName);
            final f = File(target);
            await f.writeAsBytes(bytes, flush: true);
            debugPrint("FileManager: Saved to Android app external download: $target");
            return target;
          }
        } catch (e) {
          debugPrint("FileManager: Failed writing to external downloads dir: $e");
        }

        // Fallback to FileSaver plugin for Android
        try {
          final ext = p.extension(filename).replaceFirst('.', '');
          final nameWithoutExt = p.basenameWithoutExtension(filename);
          final res = await FileSaver.instance.saveFile(
            name: nameWithoutExt,
            bytes: bytes,
            fileExtension: ext,
            mimeType: _getMimeType(mimeType, filename),
          );
          debugPrint("FileManager: Saved via FileSaver: $res");
          return res;
        } catch (e) {
          debugPrint("FileManager: FileSaver saveFile error: $e");
        }
      }

      // 2. Desktop OS (Windows / Linux / macOS) Downloads directory
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (home != null) {
          final downloads = Directory('$home/Downloads');
          if (await downloads.exists()) {
            final uniqueName = _getUniqueFilename(downloads.path, filename);
            final target = p.join(downloads.path, uniqueName);
            final f = File(target);
            await f.writeAsBytes(bytes, flush: true);
            debugPrint("FileManager: Saved to Desktop Downloads: $target");
            return target;
          }
        }
      }

      // 3. Fallback: Application Documents Directory
      final docDir = await getApplicationDocumentsDirectory();
      final uniqueName = _getUniqueFilename(docDir.path, filename);
      final savePath = p.join(docDir.path, uniqueName);
      await File(savePath).writeAsBytes(bytes, flush: true);
      debugPrint("FileManager: Saved to Documents fallback: $savePath");
      return savePath;
    } catch (e) {
      debugPrint('FileManager: Error saving file: $e');
      return null;
    }
  }

  /// Saves bytes to Downloads folder AND triggers the system Share dialog.
  /// Returns the path to the saved file in Downloads.
  Future<String?> saveAndShareBytes(
    String filename,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    try {
      // 1. Always save to public Downloads folder first
      final savedPath = await saveBytes(filename, bytes, mimeType: mimeType);

      // 2. Prepare temporary file for Share dialog
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(bytes, flush: true);

      // 3. Trigger system share
      try {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: mimeType)],
          subject: 'Laporan Kakilima Pos',
        );
      } catch (e) {
        debugPrint("FileManager: Share error (non-fatal): $e");
      }

      return savedPath ?? tempFile.path;
    } catch (e) {
      debugPrint("FileManager: Error in saveAndShareBytes: $e");
      return null;
    }
  }

  /// Opens a file with default system handler (e.g. PDF viewer, Excel)
  Future<OpenResult> openFile(String path) async {
    return await OpenFilex.open(path);
  }
}
