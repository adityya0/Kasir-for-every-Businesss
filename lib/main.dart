import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'pages/user/user_profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/laporan_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/attendance/attendance_page.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/other/splash_page.dart';
import 'pages/admin/history/history_page.dart';
import 'pages/other/printer_settings_page.dart';
import 'controllers/theme_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/analytics_controller.dart';
import 'controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/bluetooth_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_database.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/backup/auto_backup_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Desktop configuration
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Warkop Alam POS',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize SQLite Database
  final db = AppDatabase();
  debugPrint("Drift Database created");

  // Inisialisasi Pencadangan Otomatis ke Google Drive
  try {
    await AutoBackupService.instance.init(db);
  } catch (e) {
    debugPrint("AutoBackupService init error: $e");
  }



  // Initialize Localization
  await initializeDateFormatting('id', null);

  runApp(
    Provider<AppDatabase>(
      create: (context) => db,
      dispose: (context, db) => db.close(),
      child: const RootApp(),
    ),
  );
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      final minSplashTime = Future.delayed(const Duration(seconds: 2));
      final localeInit = initializeDateFormatting('id', null);
      
      // Init printer in background without blocking splash removal
      BluetoothPrinterService().init().catchError((e) {
        debugPrint("Printer init non-fatal error: $e");
      });

      await Future.wait([minSplashTime, localeInit]).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint("Splash initialization timed out");
          return [];
        },
      );
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      try {
        FlutterNativeSplash.remove();
      } catch (e) {
        debugPrint("FlutterNativeSplash remove error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, currentMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: SettingsController.instance.locale,
          builder: (context, currentLocale, child) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (context) => AdminController(
                    Provider.of<AppDatabase>(context, listen: false),
                  ),
                ),
                ChangeNotifierProvider(
                  create: (context) => AnalyticsController(
                    Provider.of<AppDatabase>(context, listen: false),
                  ),
                ),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Warkop Alam POS',
                themeMode: currentMode,
                locale: currentLocale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('id'), Locale('en')],
                builder: (context, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: SettingsController.instance.textScale,
                    builder: (context, currentScale, _) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(currentScale)),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 360),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                },
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFEA5700),
                    primary: const Color(0xFFEA5700),
                    secondary: const Color(0xFFFF8E53),
                    brightness: Brightness.light,
                  ),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFFF8F9FD),
                  cardColor: Colors.white,
                  textTheme: GoogleFonts.openSansTextTheme().copyWith(
                    titleLarge: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                    titleMedium: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                    titleSmall: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                    labelLarge: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                    labelMedium: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                    labelSmall: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Color(0xFF2D3436)),
                    titleTextStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2D3436),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFEA5700),
                    primary: const Color(0xFFEA5700),
                    secondary: const Color(0xFFFF8E53),
                    brightness: Brightness.dark,
                  ),
                  useMaterial3: true,
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  cardColor: const Color(0xFF1E1E1E),
                  textTheme: GoogleFonts.openSansTextTheme(
                    ThemeData.dark().textTheme,
                  ).copyWith(
                    titleLarge: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    titleMedium: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    titleSmall: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    labelLarge: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    labelMedium: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    labelSmall: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    titleTextStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    },
                  ),
                ),
                home: FutureBuilder(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SplashPage();
                    }
                    return const LocalAuthGate();
                  },
                ),
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/onboarding':
                      page = const OnboardingPage();
                      break;
                    case '/register': // Redirect to login or onboarding
                      page = const LoginPage();
                      break;
                    case '/login':
                      page = const LoginPage();
                      break;
                    case '/super-admin':
                      page = const AdminPage();
                      break;
                    case '/admin':
                      page = const AdminPage();
                      break;
                    case '/kasir':
                      page = const AdminPage();
                      break;
                    case '/laporan':
                      final args = settings.arguments as Map<String, dynamic>?;
                      page = LaporanPage(storeId: args?['storeId'] ?? '');
                      break;
                    case '/attendance':
                      page = const AttendancePage();
                      break;
                    case '/profile':
                      page = const UserProfilePage();
                      break;
                    case '/order-history':
                      page = const HistoryPage(storeId: null);
                      break;
                    case '/printer-settings':
                      page = const PrinterSettingsPage();
                      break;
                    default:
                      return null;
                  }

                  if (settings.name != null &&
                      [
                        '/super-admin',
                        '/admin',
                        '/kasir',
                        '/order-history',
                        '/attendance',
                        '/printer-settings',
                      ].contains(settings.name)) {
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('last_route', settings.name!);
                    });
                  }

                  return CustomPageRoute(
                    builder: (_) => page,
                    settings: settings,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class CustomPageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  @override
  final RouteSettings settings;

  CustomPageRoute({required this.builder, required this.settings})
    : super(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}

// --- GERBANG OTOMATIS BERDASARKAN ROLE (LOKAL) ---
class LocalAuthGate extends StatelessWidget {
  const LocalAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final prefs = prefsSnapshot.data!;
        final currentUserId = prefs.getString('current_user_id');
        if (currentUserId == null) {
          return const LoginPage();
        }

        return StreamBuilder<List<Profile>>(
          stream: (db.select(db.profiles)..where((t) => t.id.equals(currentUserId))).watch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profiles = snapshot.data;
            if (profiles == null || profiles.isEmpty) {
              return const LoginPage();
            }

            final String? lastRoute = prefs.getString('last_route');

            Widget target = const AdminPage();
            if (lastRoute == '/order-history') {
              target = const HistoryPage(storeId: null);
            } else if (lastRoute == '/attendance') {
              target = const AttendancePage();
            } else if (lastRoute == '/printer-settings') {
              target = const PrinterSettingsPage();
            } else {
              target = const AdminPage();
            }

            return target;
          },
        );
      },
    );
  }
}
