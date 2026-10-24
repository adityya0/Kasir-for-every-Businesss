import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleUserInfo {
  final String email;
  final String? displayName;
  final String? photoUrl;

  GoogleUserInfo({required this.email, this.displayName, this.photoUrl});

  factory GoogleUserInfo.fromGoogleSignInAccount(gsi.GoogleSignInAccount account) {
    return GoogleUserInfo(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}

class GoogleDriveService {
  static const List<String> _scopesList = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveAppdataScope,
    'email',
    'profile',
  ];

  // Standard GoogleSignIn instance
  static final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn.instance;
  
  dynamic get googleSignIn => _googleSignIn;

  static gsi.GoogleSignInAccount? _mobileAccount;
  static auth.AccessCredentials? _desktopCredentials;
  bool _initialized = false;
  static const String _credentialKey = 'gdrive_desktop_credentials';

  static String _d(List<int> b) => String.fromCharCodes(b.map((x) => x ^ 42));

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    // Mandatory initialization for v7.0.0+
    final webClientId = _d(const [27, 27, 18, 28, 27, 24, 27, 28, 18, 28, 26, 24, 7, 92, 68, 19, 65, 71, 65, 26, 30, 68, 76, 31, 75, 92, 88, 67, 77, 68, 25, 78, 94, 28, 30, 75, 76, 91, 68, 64, 67, 70, 90, 91, 70, 4, 75, 90, 90, 89, 4, 77, 69, 69, 77, 70, 79, 95, 89, 79, 88, 73, 69, 68, 94, 79, 68, 94, 4, 73, 69, 71]);
    await _googleSignIn.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: webClientId,
    );
    
    _initialized = true;
  }

  /// Performs sign-in and returns a GoogleUserInfo containing the user's email.
  /// If [silent] is true, it only attempts to restore existing sessions.
  Future<GoogleUserInfo?> signIn({bool silent = false, bool forceSelectAccount = false}) async {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
         final api = await getDriveApi(silent: silent, forceSelectAccount: forceSelectAccount);
         if (api == null) return null;
         
         // Get user info on Desktop
         final about = await api.about.get($fields: 'user');
         if (about.user != null && about.user!.emailAddress != null) {
           return GoogleUserInfo(
             email: about.user!.emailAddress!,
             displayName: about.user!.displayName,
             photoUrl: about.user!.photoLink,
           );
         }
         return null;
      }
      
      await _ensureInitialized();
      
      // 1. Always try silent sign-in first to avoid unnecessary popups
      _mobileAccount = await _googleSignIn.attemptLightweightAuthentication();
      
      // 2. If silent failed and we are NOT in silent mode, perform interactive and prompt for account
      if (_mobileAccount == null && !silent) {
        // We only call authenticate() if no account is currently signed in.
        // authenticate() automatically shows the account chooser if needed.
        _mobileAccount = await _googleSignIn.authenticate();
      }
      
      if (_mobileAccount != null) {
        return GoogleUserInfo.fromGoogleSignInAccount(_mobileAccount!);
      }
      return null;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> _saveDesktopCredentials(auth.AccessCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode({
      'accessToken': {
        'data': credentials.accessToken.data,
        'type': credentials.accessToken.type,
        'expiry': credentials.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
      'idToken': credentials.idToken,
    });
    await prefs.setString(_credentialKey, jsonStr);
    _desktopCredentials = credentials;
  }

  Future<auth.AccessCredentials?> _loadDesktopCredentials() async {
    if (_desktopCredentials != null) return _desktopCredentials;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_credentialKey);
    if (jsonStr == null) return null;
    
    try {
      final map = jsonDecode(jsonStr);
      final tokenMap = map['accessToken'];
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          tokenMap['type'],
          tokenMap['data'],
          DateTime.parse(tokenMap['expiry']),
        ),
        map['refreshToken'],
        List<String>.from(map['scopes']),
        idToken: map['idToken'],
      );
      _desktopCredentials = credentials;
      return credentials;
    } catch (e) {
      debugPrint("Error loading desktop credentials: $e");
      return null;
    }
  }

  Future<drive.DriveApi?> getDriveApi({bool silent = false, bool forceSelectAccount = false}) async {
    try {
      final desktopClientId = _d(const [27, 27, 18, 28, 27, 24, 27, 28, 18, 28, 26, 24, 7, 94, 28, 66, 66, 70, 64, 89, 91, 29, 71, 29, 75, 76, 94, 30, 68, 88, 31, 24, 94, 31, 70, 67, 30, 90, 95, 92, 64, 64, 67, 92, 88, 4, 75, 90, 90, 89, 4, 77, 69, 69, 77, 70, 79, 95, 89, 79, 88, 73, 69, 68, 94, 79, 68, 94, 4, 73, 69, 71]);
      final desktopClientSecret = _d(const [109, 101, 105, 121, 122, 114, 7, 80, 27, 102, 92, 29, 83, 126, 76, 92, 112, 95, 114, 28, 75, 19, 76, 25, 19, 26, 114, 111, 109, 112, 91, 24, 117, 114, 100]);
      final clientId = auth.ClientId(
        desktopClientId, 
        desktopClientSecret,
      );

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        auth.AccessCredentials? credentials;
        
        if (!forceSelectAccount) {
          credentials = await _loadDesktopCredentials();
        }
        
        if (credentials == null) {
          if (silent) return null;
          
          final authClient = await auth.clientViaUserConsent(clientId, _scopesList, (url) async {
            var finalUrl = url;
            if (forceSelectAccount) {
              final uri = Uri.parse(url);
              final queryParams = Map<String, String>.from(uri.queryParameters);
              queryParams['prompt'] = 'select_account';
              finalUrl = uri.replace(queryParameters: queryParams).toString();
            }

            if (!await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication)) {
               debugPrint("Could not launch $finalUrl");
            }
          });
          credentials = authClient.credentials;
          await _saveDesktopCredentials(credentials);
        }
        
        final client = auth.autoRefreshingClient(clientId, credentials, http.Client());
        // Listen for refreshes to save updated credentials
        client.credentialUpdates.listen((updated) async {
          await _saveDesktopCredentials(updated);
        });
        
        return drive.DriveApi(client);
      }
      
      // Android / iOS Flow
      await _ensureInitialized();
      
      if (_mobileAccount == null) {
        if (silent) {
          _mobileAccount = await _googleSignIn.attemptLightweightAuthentication();
        } else {
          _mobileAccount = await _googleSignIn.authenticate();
        }
      }
      
      if (_mobileAccount == null) return null;
      
      final authz = await _mobileAccount!.authorizationClient.authorizeScopes(_scopesList);
      final authClient = authz.authClient(scopes: _scopesList);
      
      return drive.DriveApi(authClient);
    } catch (e) {
      debugPrint("Google Drive Service Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_credentialKey);
      _desktopCredentials = null;
      return;
    }
    _mobileAccount = null;
    await _googleSignIn.signOut();
  }

  Future<String> _getOrCreateBackupFolder(drive.DriveApi api, String folderName) async {
    final query = "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
    final fileList = await api.files.list(q: query, spaces: 'drive');
    
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id!;
    }
    
    final newFolder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
      
    final created = await api.files.create(newFolder);
    return created.id!;
  }

  Future<String?> uploadBackup(String filePath, String fileName, {bool singleBackup = true, bool silent = false}) async {
    final api = await getDriveApi(silent: silent);
    if (api == null) throw "Google Sign-In Dibatalkan atau Gagal";

    final file = File(filePath);
    if (!await file.exists()) throw "File backup lokal tidak ditemukan";

    final folderId = await _getOrCreateBackupFolder(api, 'PosKasirBersama Backups');

    if (singleBackup) {
      // Cari file cadangan yang sudah ada di folder Drive
      final query = "'$folderId' in parents and trashed=false and name contains '.zip'";
      final fileList = await api.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, modifiedTime)',
        orderBy: 'modifiedTime desc, createdTime desc',
      );
      final existingFiles = fileList.files ?? [];
      final media = drive.Media(file.openRead(), file.lengthSync());

      if (existingFiles.isNotEmpty) {
        // Timpa file yang sudah ada agar hanya tersimpan 1 file cadangan
        final targetFile = existingFiles.first;
        final updateMeta = drive.File()..name = 'pos_backup_latest.zip';
        final updated = await api.files.update(
          updateMeta,
          targetFile.id!,
          uploadMedia: media,
        );

        // Bersihkan file-file cadangan lama lainnya agar benar-benar hanya tersisa 1 file
        for (int i = 1; i < existingFiles.length; i++) {
          final oldId = existingFiles[i].id;
          if (oldId != null) {
            try {
              await api.files.delete(oldId);
            } catch (e) {
              debugPrint("Gagal membersihkan cadangan lama ($oldId): $e");
            }
          }
        }
        return updated.id;
      } else {
        // Belum ada file, buat file baru
        final uploadFile = drive.File()
          ..name = 'pos_backup_latest.zip'
          ..parents = [folderId];

        final result = await api.files.create(uploadFile, uploadMedia: media);
        return result.id;
      }
    } else {
      final uploadFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      final result = await api.files.create(uploadFile, uploadMedia: media);
      return result.id;
    }
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await getDriveApi();
    if (api == null) throw "Google Sign-In Dibatalkan atau Gagal";
    await api.files.delete(fileId);
  }

  Future<List<drive.File>> listBackups() async {
    final api = await getDriveApi();
    if (api == null) throw "Google Sign-In Dibatalkan atau Gagal";
    
    final folderId = await _getOrCreateBackupFolder(api, 'PosKasirBersama Backups');
    
    final fileList = await api.files.list(
      q: "'$folderId' in parents and trashed=false and name contains '.zip'",
      orderBy: 'modifiedTime desc, createdTime desc',
      $fields: 'files(id, name, createdTime, modifiedTime, size)',
    );
    
    return fileList.files ?? [];
  }

  Future<String?> downloadBackup(String fileId, String fileName) async {
    final api = await getDriveApi();
    if (api == null) throw "Google Sign-In Dibatalkan atau Gagal";
    
    final tempDir = await getTemporaryDirectory();
    final savePath = p.join(tempDir.path, fileName);
    final file = File(savePath);
    
    final media = await api.files.get(
      fileId, 
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    
    final sink = file.openWrite();
    await media.stream.pipe(sink);
    await sink.close();
    
    return savePath;
  }
}
