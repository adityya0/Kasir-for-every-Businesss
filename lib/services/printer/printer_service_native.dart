import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

export 'package:blue_thermal_printer/blue_thermal_printer.dart'
    show BluetoothDevice;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../controllers/settings_controller.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  static const String _prefKeyAddress = 'printer_address';
  static const String _prefKeyName = 'printer_name';

  Future<void> init() async {
    if (kIsWeb || Platform.isWindows) return;
    try {
      _isConnected = (await _printer.isConnected.timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          )) ??
          false;
      if (!_isConnected) {
        await _tryAutoConnect().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
    } catch (e) {
      debugPrint("Printer init error: $e");
    }
  }

  Future<bool?> get isConnectedStatus async {
    if (Platform.isWindows) return false;
    return await _printer.isConnected;
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    if (Platform.isWindows) return [];
    return await _printer.getBondedDevices();
  }

  Future<List<BluetoothDevice>> getDevices() => getBondedDevices();

  Future<bool> connect(BluetoothDevice device) async {
    if (Platform.isWindows) return false;
    try {
      if (await _printer.isConnected ?? false) {
        await _printer.disconnect();
      }
      await _printer.connect(device);
      _selectedDevice = device;
      _isConnected = true;
      await _savePrinter(device);
      return true;
    } catch (e) {
      debugPrint("Error connecting to printer: $e");
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    if (Platform.isWindows) return;
    await _printer.disconnect();
    _isConnected = false;
    _selectedDevice = null;
    await _clearPrinter();
  }

  Future<void> _savePrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyAddress, device.address!);
    await prefs.setString(_prefKeyName, device.name!);
  }

  Future<void> _clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyAddress);
    await prefs.remove(_prefKeyName);
  }

  Future<void> _tryAutoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_prefKeyAddress);
    if (address != null) {
      final devices = await getDevices();
      final device = devices.firstWhere(
        (d) => d.address == address,
        orElse: () => BluetoothDevice("Unknown", address),
      );
      if (device.name != "Unknown") {
        await connect(device);
      }
    }
  }

  Future<void> testPrint() => printTest();

  Future<void> printTest() async {
    if (Platform.isWindows) return;
    if (!(await _printer.isConnected ?? false)) return;

    _printer.printNewLine();
    _printer.printCustom("TEST PRINT", 3, 1); // Size 3, Align 1 (Center)
    _printer.printNewLine();
    _printer.printCustom("Printer Bluetooth Berhasil Terhubung", 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();
  }

  Future<void> printReceipt({
    required String storeName,
    required String transactionId,
    required DateTime createdAt,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double cashReceived,
    required double change,
    required String paymentMethod,
    double? subtotal,
    double? discount,
    double? pajakAmount,
    String? pajakName,
    String? tableNumber,
    String? customerName,
    String? discountLabel,
    bool isDebt = false,
    bool? showStoreName,
    bool? showAddress,
    bool? showDate,
    bool? showDetails,
    bool? showThankYou,
    bool? showEmail,
    bool? showTable,
    String? storeAddress,
    String? storeEmail,
    String? thankYouMessage,
  }) async {
    if (Platform.isWindows) return;
    if (!(await _printer.isConnected ?? false)) return;

    final settings = SettingsController.instance;

    final effectiveShowStoreName =
        showStoreName ?? settings.receiptShowStoreName.value;
    final effectiveShowAddress =
        showAddress ?? settings.receiptShowAddress.value;
    final effectiveShowDate = showDate ?? settings.receiptShowDate.value;
    final effectiveShowDetails =
        showDetails ?? settings.receiptShowDetails.value;
    final effectiveShowThankYou =
        showThankYou ?? settings.receiptShowThankYou.value;
    final effectiveShowEmail = showEmail ?? settings.receiptShowEmail.value;
    final effectiveShowTable = showTable ?? settings.receiptShowTable.value;
    final effectiveThankYouMessage =
        thankYouMessage ?? settings.receiptThankYouMessage.value;

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final displayId = (transactionId.length > 8)
        ? transactionId.substring(0, 8).toUpperCase()
        : transactionId.toUpperCase();

    _printer.printNewLine();

    // 1. HEADER (STORE INFO)
    if (effectiveShowStoreName) {
      _printer.printCustom(storeName.toUpperCase(), 2, 1);
    }
    if (effectiveShowAddress &&
        storeAddress != null &&
        storeAddress.trim().isNotEmpty) {
      _printer.printCustom(storeAddress.trim(), 1, 1);
    }
    if (effectiveShowEmail &&
        storeEmail != null &&
        storeEmail.trim().isNotEmpty) {
      _printer.printCustom(storeEmail.trim(), 1, 1);
    }

    _printer.printCustom("--------------------------------", 1, 1);

    // 2. TRANSACTION INFO
    _printer.printLeftRight("ID Trans", "#$displayId", 1);
    if (effectiveShowDate) {
      _printer.printLeftRight(
        "Tanggal",
        DateFormat('dd/MM/yyyy').format(createdAt),
        1,
      );
      _printer.printLeftRight(
        "Waktu",
        DateFormat('HH:mm').format(createdAt),
        1,
      );
    }

    _printer.printCustom("--------------------------------", 1, 1);

    if (effectiveShowTable && tableNumber != null && tableNumber.isNotEmpty) {
      _printer.printLeftRight("Meja", tableNumber, 1);
      _printer.printCustom("--------------------------------", 1, 1);
    }

    if (customerName != null && customerName.trim().isNotEmpty) {
      _printer.printLeftRight("Pelanggan", customerName.trim(), 1);
      _printer.printCustom("--------------------------------", 1, 1);
    }

    // 3. ITEMS LIST
    if (effectiveShowDetails) {
      _printer.printLeftRight("ITEM", "TOTAL", 1);
      for (var item in items) {
        final name = (item['name'] ?? item['productName'] ?? 'Produk')
            .toString()
            .toUpperCase();
        final qty = item['quantity'] ?? 1;
        final totalPrice = (item['total_price'] ?? 0 as num).toDouble();
        final unitPrice = item['unit_price'] != null
            ? (item['unit_price'] as num).toDouble()
            : (qty > 0 ? totalPrice / qty : totalPrice);

        _printer.printCustom(name, 1, 0);
        _printer.printLeftRight(
          "$qty x ${currencyFormat.format(unitPrice)}",
          currencyFormat.format(totalPrice),
          1,
        );
        if (item['notes'] != null && item['notes'].toString().isNotEmpty) {
          _printer.printCustom("(${item['notes']})", 0, 0);
        }
      }
      _printer.printCustom("--------------------------------", 1, 1);
    }

    // 4. FINANCIAL SUMMARY
    final calcSubtotal = subtotal ?? (totalAmount + (discount ?? 0));
    _printer.printLeftRight("SUBTOTAL", currencyFormat.format(calcSubtotal), 1);
    if (discount != null && discount > 0) {
      final label = (discountLabel != null && discountLabel.trim().isNotEmpty)
          ? discountLabel.trim().toUpperCase()
          : "DISKON";
      _printer.printLeftRight(
        label,
        "-${currencyFormat.format(discount)}",
        1,
      );
    }
    if (pajakAmount != null && pajakAmount > 0) {
      final pName = (pajakName != null && pajakName.isNotEmpty)
          ? pajakName.toUpperCase()
          : "PAJAK";
      _printer.printLeftRight(pName, currencyFormat.format(pajakAmount), 1);
    }

    _printer.printCustom("--------------------------------", 1, 1);
    _printer.printLeftRight("TOTAL", currencyFormat.format(totalAmount), 2);
    _printer.printCustom("--------------------------------", 1, 1);

    // 5. PAYMENT DETAILS
    _printer.printLeftRight(
      "METODE PEMBAYARAN",
      paymentMethod.toUpperCase(),
      1,
    );
    _printer.printLeftRight("DIBAYAR", currencyFormat.format(cashReceived), 1);
    if (isDebt) {
      _printer.printLeftRight(
        "HUTANG",
        currencyFormat.format(totalAmount - cashReceived),
        1,
      );
    } else if (change > 0) {
      _printer.printLeftRight("KEMBALI", currencyFormat.format(change), 1);
    }

    _printer.printCustom("--------------------------------", 1, 1);

    // 6. FOOTER
    if (effectiveShowThankYou) {
      _printer.printCustom("TERIMA KASIH", 2, 1);
      final msg = effectiveThankYouMessage.isNotEmpty
          ? effectiveThankYouMessage
          : "ATAS KUNJUNGAN ANDA";
      _printer.printCustom(msg.toUpperCase(), 1, 1);
      _printer.printNewLine();
    }

    if (effectiveShowTable && tableNumber != null && tableNumber.isNotEmpty) {
      _printer.printCustom("================================", 1, 1);
      _printer.printCustom("NOMOR MEJA", 1, 1);
      _printer.printCustom(tableNumber.toUpperCase(), 3, 1);
      _printer.printCustom("================================", 1, 1);
      _printer.printNewLine();
    }

    _printer.printCustom("DIHASILKAN OLEH SISTEM OMNI POS", 0, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.printNewLine();
  }
}
