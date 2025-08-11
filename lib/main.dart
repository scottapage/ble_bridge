import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as sr;

BluetoothDevice? connectedDevice;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _startServer();
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('BLE Bridge Running')))));
}

Future<void> _startServer() async {
  final router = sr.Router();

  // /scan -> JSON list of {id, name, rssi}
  router.get('/scan', (shelf.Request req) async {
    // Ensure BT adapter is ON
    await FlutterBluePlus.adapterState
        .firstWhere((s) => s == BluetoothAdapterState.on);

    final Map<String, Map<String, dynamic>> found = {};
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        found[r.device.remoteId.str] = {
          'id': r.device.remoteId.str,
          'name': r.advertisementData.advName,
          'rssi': r.rssi,
        };
      }
    });
    FlutterBluePlus.cancelWhenScanComplete(sub);
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    final resp = jsonEncode(found.values.toList());
    return shelf.Response.ok(resp, headers: {'Content-Type': 'application/json'});
  });

  // /connect { "id": "<device_id>" }
  router.post('/connect', (shelf.Request req) async {
    final data = jsonDecode(await req.readAsString());
    final id = data['id'] as String;
    final dev = BluetoothDevice.fromId(id);
    await dev.connect(autoConnect: false);
    connectedDevice = dev;
    return shelf.Response.ok(jsonEncode({'status': 'connected'}),
        headers: {'Content-Type': 'application/json'});
  });

  // /write { "characteristic": "<uuid>", "value": "<base64-bytes>" }
  router.post('/write', (shelf.Request req) async {
    if (connectedDevice == null) {
      return shelf.Response.internalServerError(body: 'No device connected');
    }
    final data = jsonDecode(await req.readAsString());
    final charUuid = Guid(data['characteristic'] as String);
    final value = base64Decode(data['value'] as String);

    final services = await connectedDevice!.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid == charUuid) {
          await c.write(value, withoutResponse: false);
          return shelf.Response.ok(jsonEncode({'status': 'written'}),
              headers: {'Content-Type': 'application/json'});
        }
      }
    }
    return shelf.Response.internalServerError(body: 'Characteristic not found');
  });

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('BLE bridge listening on ${server.address.address}:${server.port}');
}
