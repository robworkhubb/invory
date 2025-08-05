import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _deviceIdKey = 'device_id';
  static const Uuid _uuid = Uuid();

  /// Genera o recupera l'ID univoco del dispositivo
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Ottiene la piattaforma corrente
  static String getPlatform() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Web';
  }

  /// Rimuove l'ID del dispositivo (per logout)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}
