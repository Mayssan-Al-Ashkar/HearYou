import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_provider.dart';

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

  Color _getColorFromName(String colorName) {
    Map<String, Color> colorMap = {
      'blue': Colors.blue,
      'green': Colors.green,
      'red': Colors.red,
      'yellow': Colors.yellow,
    };

    return colorMap[colorName] ?? Colors.blue;
  }

  String _getColorName(Color color) {
    Map<Color, String> colorMap = {
      Colors.blue: 'blue',
      Colors.green: 'green',
      Colors.red: 'red',
      Colors.yellow: 'yellow',
    };

    return colorMap[color] ?? 'blue';
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

    return Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    title: Text(
      "Alerts Settings",
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  ),
  body: Container(
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.black : Colors.white,
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Select Alert Colors",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        ...tempSelectedColors.keys.map((action) {
                          return Column(
                            children: [
                              Card(
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDarkMode
                                          ? [Color(0xFF1F1A24), Color(0xFF2A2234)]
                                          : [Colors.white, Color(0xFFF7ECFF)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.deepPurpleAccent.withOpacity(0.25)
                                          : Color(0xFFE5D6F8),
                                    ),
                                  ),
                                  child: ListTile(
                                  title: Text(
                                    eventDisplayNames[action] ?? action,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  trailing: DropdownButton<String>(
                                    value: _getColorName(
                                      tempSelectedColors[action]!,
                                    ),
                                    icon: Icon(
                                      Icons.color_lens,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                    underline: Container(),
                                    dropdownColor:
                                        isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.white,
                                    onChanged: (String? newColorName) {
                                      if (newColorName != null) {
                                        changeTempColor(
                                          action,
                                          _getColorFromName(newColorName),
                                        );
                                      }
                                    },
                                    items:
                                        [
                                          'blue',
                                          'green',
                                          'red',
                                          'yellow',
                                        ].map<DropdownMenuItem<String>>((
                                          String colorName,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: colorName,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: _getColorFromName(
                                                  colorName,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                            ],
                          );
                        }),
                        SizedBox(height: 10),
                        SwitchListTile(
                          title: Text(
                            "Enable Vibration",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          value: isVibrationOn,
                          onChanged: (bool value) {
                            setState(() {
                              isVibrationOn = value;
                            });
                          },
                          activeColor: isDarkMode
                              ? Colors.deepPurpleAccent
                              : Color.fromARGB(255, 229, 172, 240),
                        ),
                        SizedBox(height: 32),
                        Center(
                          child: ElevatedButton(
                            onPressed: _saveSettingsToMongo,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 80,
                                vertical: 15,
                              ),
                              backgroundColor: isDarkMode
                                  ? Colors.deepPurpleAccent
                                  : Color(0xFFF0B8F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
