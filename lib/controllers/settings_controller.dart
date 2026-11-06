import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController {
  // Singleton instance
  static final SettingsController instance = SettingsController._internal();

  factory SettingsController() {
    return instance;
  }

  SettingsController._internal() {
    _loadSettings();
  }

  // Language Setting
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('id'));
  static const String _localeKey = 'app_locale';

  // Text Scale Setting (Limit to 1.3 for safety)
  final ValueNotifier<double> textScale = ValueNotifier(0.85);
  static const String _textScaleKey = 'text_scale';
  static const double maxTextScale = 1.3;

  // Layout preference
  final ValueNotifier<bool> isGridView = ValueNotifier(true);
  static const String _isGridViewKey = 'is_grid_view';

  // Tax Settings
  final ValueNotifier<bool> pajakEnabled = ValueNotifier(false);
  final ValueNotifier<String> pajakName = ValueNotifier("PPN");
  final ValueNotifier<double> pajakRate = ValueNotifier(10.0);
  static const String _pajakEnabledKey = 'pajak_enabled';
  static const String _pajakNameKey = 'pajak_name';
  static const String _pajakRateKey = 'pajak_rate';

  // Sidebar expansion state
  final ValueNotifier<bool> isSidebarExpanded = ValueNotifier(false);
  static const String _isSidebarExpandedKey = 'is_sidebar_expanded';

  // Toggle for Popular/Recent filters on KasirPage
  final ValueNotifier<bool> showFilterTabs = ValueNotifier(true);
  static const String _showFilterTabsKey = 'show_filter_tabs';

  // Keyboard/Numpad display option
  final ValueNotifier<bool> showNumpad = ValueNotifier(false);
  static const String _showNumpadKey = 'show_numpad';

  // Auto focus / auto open keyboard on kasir search bar
  final ValueNotifier<bool> autoFocusKasirSearch = ValueNotifier(false);
  static const String _autoFocusKasirSearchKey = 'auto_focus_kasir_search';

  // Feature Flags
  final ValueNotifier<bool> featureGrosirEnabled = ValueNotifier(false);
  final ValueNotifier<bool> featureMejaEnabled = ValueNotifier(false);
  final ValueNotifier<bool> featureStokEnabled = ValueNotifier(true);
  final ValueNotifier<bool> featureLoyaltyEnabled = ValueNotifier(true);
  final ValueNotifier<bool> featureHutangEnabled = ValueNotifier(false);
  final ValueNotifier<bool> featurePelangganEnabled = ValueNotifier(true);
  final ValueNotifier<bool> featurePisahBillEnabled = ValueNotifier(true);
  final ValueNotifier<bool> featureSplitPayEnabled = ValueNotifier(true);
  final ValueNotifier<bool> featureKaryawanEnabled = ValueNotifier(false);
  final ValueNotifier<bool> featureAntreanPesananEnabled = ValueNotifier(true);

  static const String _featureGrosirKey = 'feature_grosir_enabled';
  static const String _featureMejaKey = 'feature_meja_enabled';
  static const String _featureStokKey = 'feature_stok_enabled';
  static const String _featureLoyaltyKey = 'feature_loyalty_enabled';
  static const String _featureHutangKey = 'feature_hutang_enabled';
  static const String _featurePelangganKey = 'feature_pelanggan_enabled';
  static const String _featurePisahBillKey = 'feature_pisah_bill_enabled';
  static const String _featureSplitPayKey = 'feature_split_pay_enabled';
  static const String _featureKaryawanKey = 'feature_karyawan_enabled';
  static const String _featureAntreanPesananKey = 'feature_antrean_pesanan_enabled';

  // Receipt Settings
  final ValueNotifier<bool> receiptShowLogo = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowStoreName = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowAddress = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowEmail = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowDate = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowDetails = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowThankYou = ValueNotifier(true);
  final ValueNotifier<bool> receiptShowTable = ValueNotifier(true);
  final ValueNotifier<String> receiptThankYouMessage = ValueNotifier("Terima kasih atas kunjungan Anda!");
  
  static const String _receiptShowLogoKey = 'receipt_show_logo';
  static const String _receiptShowStoreNameKey = 'receipt_show_store_name';
  static const String _receiptShowAddressKey = 'receipt_show_address';
  static const String _receiptShowEmailKey = 'receipt_show_email';
  static const String _receiptShowDateKey = 'receipt_show_date';
  static const String _receiptShowDetailsKey = 'receipt_show_details';
  static const String _receiptShowThankYouKey = 'receipt_show_thank_you';
  static const String _receiptShowTableKey = 'receipt_show_table';
  static const String _receiptThankYouMessageKey = 'receipt_thank_you_message';

  // Simple Localization Map
  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'app_settings': 'PENGATURAN APLIKASI',
      'language': 'Bahasa',
      'text_size': 'Ukuran Teks',
      'dark_mode': 'Mode Gelap',
      'save': 'Simpan',
      'cancel': 'Batal',
      'logout': 'Keluar Sesi',
      'confirm_logout': 'Konfirmasi Keluar',
      'logout_message': 'Apakah Anda yakin ingin keluar?',
      'edit_name': 'Ubah Nama',
      'edit_store_name': 'Ubah Nama Toko',
      'admin_account': 'AKUN ADMIN',
      'branding': 'BRANDING TOKO',
      'profile_title': 'Profil Saya',
      'change_admin_photo': 'Ganti Foto Admin',
      'employee_list': 'Daftar Karyawan',
      'change_store_logo': 'Ubah Logo Toko',
      'backup_restore': 'Backup & Restore',
      'export_backup': 'Ekspor Backup Full',
      'import_backup': 'Impor Backup',
      'reset_store': 'Reset Toko',
      'danger_zone': 'ZONA BERBAHAYA',
      'reset_subtitle': 'Hapus semua penjualan & reset stok',
      'nav_cashier': 'Kasir',
      'nav_history': 'Riwayat',
      'nav_absent': 'Absen',
      'nav_printer': 'Printer',
      'nav_inventory': 'Produk',
      'nav_category': 'Kategori',
      'nav_analytics': 'Analitik',
      'nav_profit_loss': 'Laba Rugi',
      'nav_promotion': 'Promosi',
      'nav_data': 'Data & Stok',
      'payment_methods': 'Metode Pembayaran',
      'payment_services': 'LAYANAN PEMBAYARAN',
      'dashboard': 'Dashboard',
      'welcome_back': 'Selamat datang kembali',
      'total_sales': 'Total Penjualan',
      'transactions': 'Transaksi',
      'items': 'Barang',
      'stock': 'Stok',
      'search_hint': 'Cari...',
      'all': 'Semua',
      'income': 'Pendapatan',
      'today_summary': 'RINGKASAN HARI INI',
      'lifetime_revenue': 'PERFORMA PENDAPATAN (LIFETIME)',
      'growth_indicators': 'INDIKATOR PERTUMBUHAN',
      'recent_transactions': 'TRANSAKSI TERAKHIR',
      'view_all': 'Lihat Semua',
      'navigation': 'NAVIGASI',
      'beranda': 'Beranda',
      'absen_staff': 'Absensi Staff',
      'admin_panel': 'Panel Admin',
      'administration': 'ADMINISTRASI',
      'logout_app': 'Keluar Aplikasi',
      'business_analytics': 'Analitik Bisnis',
      'performance_summary': 'RINGKASAN PERFORMA',
      'business_growth': 'PERTUMBUHAN BISNIS',
      'revenue_distribution': 'DISTRIBUSI PENDAPATAN',
      'top_products': 'PRODUK TERLARIS',
      'revenue_chart': 'GRAFIK PENDAPATAN',
      'kelola_produk': 'Kelola Produk',
      'all_categories': 'Semua Kategori',
      'add_product': 'Tambah Produk',
      'import_export': 'Impor/Ekspor',
      'search_product': 'Cari produk...',
      'limited': 'Terbatas',
      'unlimited': 'Tidak Terbatas',
      'no_products': 'Belum ada produk',
      'product_not_found': 'Produk tidak ditemukan',
      'history_performance': 'Riwayat & Performa',
      'export_report': 'Ekspor Laporan',
      'performance_staff': 'PERFORMA STAF',
      'export_history_title': 'Ekspor Riwayat Transaksi',
      'export_pdf': 'Ekspor PDF',
      'export_excel': 'Ekspor Excel',
      'stock_max_reached': 'sudah mencapai batas maksimal di keranjang!',
      'stock_insufficient': 'tidak mencukupi',
      'weekly_trend': 'Trend Mingguan',
      'monthly_trend': 'Trend Bulanan',
    },
    'en': {
      'app_settings': 'APP SETTINGS',
      'language': 'Language',
      'text_size': 'Text Size',
      'dark_mode': 'Dark Mode',
      'save': 'Save',
      'cancel': 'Cancel',
      'logout': 'Logout',
      'confirm_logout': 'Confirm Logout',
      'logout_message': 'Are you sure you want to logout?',
      'edit_name': 'Edit Name',
      'edit_store_name': 'Edit Store Name',
      'admin_account': 'ADMIN ACCOUNT',
      'branding': 'STORE BRANDING',
      'profile_title': 'My Profile',
      'change_admin_photo': 'Change Admin Photo',
      'employee_list': 'Employee List',
      'change_store_logo': 'Change Store Logo',
      'backup_restore': 'Backup & Restore',
      'export_backup': 'Export Full Backup',
      'import_backup': 'Import Backup',
      'reset_store': 'Reset Store',
      'danger_zone': 'DANGER ZONE',
      'reset_subtitle': 'Delete all sales & reset stock',
      'nav_cashier': 'Cashier',
      'nav_history': 'History',
      'nav_absent': 'Attendance',
      'nav_printer': 'Printer',
      'nav_inventory': 'Products',
      'nav_category': 'Categories',
      'nav_analytics': 'Analytics',
      'nav_profit_loss': 'Profit & Loss',
      'nav_promotion': 'Promotions',
      'nav_data': 'Data & Stock',
      'payment_methods': 'Payment Methods',
      'payment_services': 'PAYMENT SERVICES',
      'dashboard': 'Dashboard',
      'welcome_back': 'Welcome back',
      'total_sales': 'Total Sales',
      'transactions': 'Transactions',
      'items': 'Items',
      'stock': 'Stock',
      'search_hint': 'Search...',
      'all': 'All',
      'income': 'Income',
      'today_summary': 'TODAY SUMMARY',
      'lifetime_revenue': 'LIFETIME REVENUE PERFORMANCE',
      'growth_indicators': 'GROWTH INDICATORS',
      'recent_transactions': 'RECENT TRANSACTIONS',
      'view_all': 'View All',
      'navigation': 'NAVIGATION',
      'beranda': 'Home',
      'absen_staff': 'Staff Attendance',
      'admin_panel': 'Admin Panel',
      'administration': 'ADMINISTRATION',
      'logout_app': 'Logout App',
      'business_analytics': 'Business Analytics',
      'performance_summary': 'PERFORMANCE SUMMARY',
      'business_growth': 'BUSINESS GROWTH',
      'revenue_distribution': 'REVENUE DISTRIBUTION',
      'top_products': 'TOP PRODUCTS',
      'revenue_chart': 'REVENUE CHART',
      'kelola_produk': 'Manage Products',
      'all_categories': 'All Categories',
      'add_product': 'Add Product',
      'import_export': 'Import/Export',
      'search_product': 'Search products...',
      'limited': 'Limited',
      'unlimited': 'Unlimited',
      'no_products': 'No products yet',
      'product_not_found': 'Product not found',
      'history_performance': 'History & Performance',
      'export_report': 'Export Report',
      'performance_staff': 'STAFF PERFORMANCE',
      'export_history_title': 'Export Transaction History',
      'export_pdf': 'Export PDF',
      'export_excel': 'Export Excel',
      'stock_max_reached': 'already reached maximum limit in cart!',
      'stock_insufficient': 'insufficient',
      'weekly_trend': 'Weekly Trend',
      'monthly_trend': 'Monthly Trend',
    },
  };

  String getString(String key) {
    return _localizedValues[locale.value.languageCode]?[key] ?? key;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Locale
    final langCode = prefs.getString(_localeKey) ?? 'id';
    locale.value = Locale(langCode);

    // Load Text Scale
    double scale = prefs.getDouble(_textScaleKey) ?? 0.85;
    if (scale > maxTextScale) scale = maxTextScale;
    textScale.value = scale;

    // Load Grid View Preference
    isGridView.value = prefs.getBool(_isGridViewKey) ?? true;

    // Load Tax Settings
    pajakEnabled.value = prefs.getBool(_pajakEnabledKey) ?? false;
    pajakName.value = prefs.getString(_pajakNameKey) ?? "PPN";
    pajakRate.value = prefs.getDouble(_pajakRateKey) ?? 10.0;

    // Load Sidebar state
    isSidebarExpanded.value = prefs.getBool(_isSidebarExpandedKey) ?? false;

    // Load Filter tabs visibility
    showFilterTabs.value = prefs.getBool(_showFilterTabsKey) ?? true;

    // Load Numpad visibility
    showNumpad.value = prefs.getBool(_showNumpadKey) ?? false;

    // Load Kasir Search auto focus
    autoFocusKasirSearch.value = prefs.getBool(_autoFocusKasirSearchKey) ?? false;

    // Load Feature Flags
    featureGrosirEnabled.value = prefs.getBool(_featureGrosirKey) ?? false;
    featureMejaEnabled.value = prefs.getBool(_featureMejaKey) ?? false;
    featureStokEnabled.value = prefs.getBool(_featureStokKey) ?? true;
    featureLoyaltyEnabled.value = prefs.getBool(_featureLoyaltyKey) ?? true;
    featureHutangEnabled.value = prefs.getBool(_featureHutangKey) ?? false;
    featurePelangganEnabled.value = prefs.getBool(_featurePelangganKey) ?? true;
    featurePisahBillEnabled.value = prefs.getBool(_featurePisahBillKey) ?? true;
    featureSplitPayEnabled.value = prefs.getBool(_featureSplitPayKey) ?? true;
    featureKaryawanEnabled.value = prefs.getBool(_featureKaryawanKey) ?? false;
    featureAntreanPesananEnabled.value = prefs.getBool(_featureAntreanPesananKey) ?? true;

    // Load Receipt Settings
    receiptShowLogo.value = prefs.getBool(_receiptShowLogoKey) ?? true;
    receiptShowStoreName.value = prefs.getBool(_receiptShowStoreNameKey) ?? true;
    receiptShowAddress.value = prefs.getBool(_receiptShowAddressKey) ?? true;
    receiptShowEmail.value = prefs.getBool(_receiptShowEmailKey) ?? true;
    receiptShowDate.value = prefs.getBool(_receiptShowDateKey) ?? true;
    receiptShowDetails.value = prefs.getBool(_receiptShowDetailsKey) ?? true;
    receiptShowThankYou.value = prefs.getBool(_receiptShowThankYouKey) ?? true;
    receiptShowTable.value = prefs.getBool(_receiptShowTableKey) ?? true;
    receiptThankYouMessage.value = prefs.getString(_receiptThankYouMessageKey) ?? "Terima kasih atas kunjungan Anda!";
  }

  Future<void> setLocale(String languageCode) async {
    locale.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  Future<void> setTextScale(double scale) async {
    final safeScale = scale.clamp(0.8, maxTextScale);
    textScale.value = safeScale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, safeScale);
  }

  Future<void> setGridView(bool value) async {
    isGridView.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGridViewKey, value);
  }

  Future<void> setPajakEnabled(bool value) async {
    pajakEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pajakEnabledKey, value);
  }

  Future<void> setPajakName(String value) async {
    pajakName.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pajakNameKey, value);
  }

  Future<void> setPajakRate(double value) async {
    pajakRate.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pajakRateKey, value);
  }

  Future<void> toggleSidebar() async {
    isSidebarExpanded.value = !isSidebarExpanded.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSidebarExpandedKey, isSidebarExpanded.value);
  }

  Future<void> setShowFilterTabs(bool value) async {
    showFilterTabs.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFilterTabsKey, value);
  }

  Future<void> setShowNumpad(bool value) async {
    showNumpad.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNumpadKey, value);
  }

  Future<void> setAutoFocusKasirSearch(bool value) async {
    autoFocusKasirSearch.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoFocusKasirSearchKey, value);
  }

  Future<void> setReceiptShowLogo(bool value) async {
    receiptShowLogo.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowLogoKey, value);
  }

  Future<void> setReceiptShowStoreName(bool value) async {
    receiptShowStoreName.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowStoreNameKey, value);
  }

  Future<void> setReceiptShowAddress(bool value) async {
    receiptShowAddress.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowAddressKey, value);
  }

  Future<void> setReceiptShowEmail(bool value) async {
    receiptShowEmail.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowEmailKey, value);
  }

  Future<void> setReceiptShowDate(bool value) async {
    receiptShowDate.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowDateKey, value);
  }

  Future<void> setReceiptShowDetails(bool value) async {
    receiptShowDetails.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowDetailsKey, value);
  }

  Future<void> setReceiptShowThankYou(bool value) async {
    receiptShowThankYou.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowThankYouKey, value);
  }

  Future<void> setReceiptShowTable(bool value) async {
    receiptShowTable.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_receiptShowTableKey, value);
  }

  Future<void> setReceiptThankYouMessage(String value) async {
    receiptThankYouMessage.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_receiptThankYouMessageKey, value);
  }

  // Feature Flag Setters
  Future<void> setFeatureGrosirEnabled(bool value) async {
    featureGrosirEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureGrosirKey, value);
  }

  Future<void> setFeatureMejaEnabled(bool value) async {
    featureMejaEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureMejaKey, value);
  }

  Future<void> setFeatureStokEnabled(bool value) async {
    featureStokEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureStokKey, value);
  }

  Future<void> setFeatureLoyaltyEnabled(bool value) async {
    featureLoyaltyEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureLoyaltyKey, value);
  }

  Future<void> setFeatureHutangEnabled(bool value) async {
    featureHutangEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureHutangKey, value);
  }

  Future<void> setFeaturePelangganEnabled(bool value) async {
    featurePelangganEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featurePelangganKey, value);
  }

  Future<void> setFeaturePisahBillEnabled(bool value) async {
    featurePisahBillEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featurePisahBillKey, value);
  }

  Future<void> setFeatureSplitPayEnabled(bool value) async {
    featureSplitPayEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureSplitPayKey, value);
  }

  Future<void> setFeatureKaryawanEnabled(bool value) async {
    featureKaryawanEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureKaryawanKey, value);
  }

  Future<void> setFeatureAntreanPesananEnabled(bool value) async {
    featureAntreanPesananEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureAntreanPesananKey, value);
  }

  bool get isIndonesian => locale.value.languageCode == 'id';
}
