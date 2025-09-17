import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_provider.dart';
import 'view/alerts_view.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Map<String, Color> selectedColors = {
    'baby_crying': Colors.blue,
    'door_knocking': Colors.green,
    'phone_call': Colors.red,
    'baby_movement': Colors.yellow,
  };

  Map<String, String> eventDisplayNames = {
    'baby_crying': 'Baby Crying',
    'door_knocking': 'Door Knocking',
    'phone_call': 'Phone Call',
    'baby_movement': 'Baby Movement',
  };

  Map<String, Color> tempSelectedColors = {};
  bool isVibrationOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/settings/'));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final Map<String, dynamic> settings = data['settings'] ?? {};
        final Map<String, dynamic> colors = settings['colors'] ?? {};
        setState(() {
          colors.forEach((key, value) {
            selectedColors[key] = _getColorFromName(value.toString());
          });
          isVibrationOn = settings['vibration'] == true;
          tempSelectedColors = Map.from(selectedColors);
        });
      }
    } catch (_) {}
  }

  final Map<String, Color> _palette = const {
    'blue': Colors.blue,
    'green': Colors.green,
    'red': Colors.red,
    'yellow': Colors.yellow,
  };

  Color _getColorFromName(String name) => _palette[name] ?? Colors.blue;

  String _getColorName(Color color) {
    for (final entry in _palette.entries) {
      if (entry.value == color) return entry.key;
    }
    return 'blue';
  }

  void changeTempColor(String action, Color color) {
    setState(() {
      tempSelectedColors[action] = color;
    });
  }

  Future<void> _saveSettingsToMongo() async {
    try {
      final colors = tempSelectedColors.map((k, v) => MapEntry(k, _getColorName(v)));
      final res = await http.post(
        Uri.parse('$apiBase/settings/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'colors': colors,
          'vibration': isVibrationOn,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          selectedColors = Map.from(tempSelectedColors);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (_) {}
  }

  // removed old realtime database update

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.isDarkMode;

    if (tempSelectedColors.isEmpty) {
      tempSelectedColors = Map.from(selectedColors);
    }

    final model = AlertsViewModel(
      eventDisplayNames: eventDisplayNames,
      selectedColorNamesTemp: tempSelectedColors.map((k, v) => MapEntry(k, _getColorName(v))),
      colorPalette: _palette,
      isVibrationOn: isVibrationOn,
    );

    return AlertsScreenView(
      model: model,
      isDarkMode: isDarkMode,
      onBack: () => Navigator.pop(context),
      onChangeColorName: (action, name) {
        changeTempColor(action, _getColorFromName(name));
      },
      onToggleVibration: (v) => setState(() { isVibrationOn = v; }),
      onSave: _saveSettingsToMongo,
    );
  }
}
