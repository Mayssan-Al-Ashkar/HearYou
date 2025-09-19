import 'api_client.dart';
import 'package:flutter/material.dart';

class SettingsService {
  final ApiClient _client;
  SettingsService(this._client);

  Future<(Map<String, String> colors, bool vibration, Map<String, String> displayNames)> loadSettings() async {
    final data = await _client.getJson('/settings/');
    final s = (data['settings'] as Map<String, dynamic>? ) ?? {};
    final raw = (s['colors'] as Map<String, dynamic>? ) ?? {};
    final colors = <String, String>{ for (final e in raw.entries) e.key: e.value.toString() };
    final vibration = s['vibration'] == true;
    // Default display names
    final display = <String, String>{
      'baby_crying': 'Baby Crying',
      'door_knocking': 'Door Knocking',
      'phone_call': 'Phone Call',
      'baby_movement': 'Baby Movement',
    };
    return (colors, vibration, display);
  }

  Future<void> saveSettings({required Map<String, String> colorNames, required bool vibration}) async {
    await _client.postJson('/settings/', {
      'colors': colorNames,
      'vibration': vibration,
    });
  }

  static const Map<String, Color> palette = {
    'blue': Colors.blue,
    'green': Colors.green,
    'red': Colors.red,
    'yellow': Colors.yellow,
  };
}


