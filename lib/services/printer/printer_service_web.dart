import 'package:flutter/foundation.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  BluetoothDevice? _selectedDevice;
  final bool _isConnected = false;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  Future<void> init() async {
    // Web implementation: does nothing
  }

  Future<bool?> get isConnectedStatus async => false;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return [];
  }

  Future<List<BluetoothDevice>> getDevices() => getBondedDevices();

  Future<bool> connect(BluetoothDevice device) async {
    return false;
  }

  Future<void> disconnect() async {}

  Future<void> testPrint() async {}
  Future<void> printTest() async {}

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
    debugPrint("Printing not supported on web");
  }
}

class BluetoothDevice {
  final String? name;
  final String? address;
  final int type;
  bool connected = false;

  BluetoothDevice(this.name, this.address, {this.type = 0});
}
