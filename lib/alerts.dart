import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme_provider.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  _AlertsPageState createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    "colors",
  );
  final DatabaseReference _switchStateRef = FirebaseDatabase.instance.ref(
    "vibration",
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
    _loadColorsFromFirebase();
    _loadSwitchStateFromFirebase();
  }

  void _loadColorsFromFirebase() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          data.forEach((key, value) {
            selectedColors[key] = _getColorFromName(value.toString());
          });
          tempSelectedColors = Map.from(selectedColors);
        });
      }
    });
  }

  void _loadSwitchStateFromFirebase() {
    _switchStateRef.onValue.listen((event) {
      final value = event.snapshot.value;
      setState(() {
        isVibrationOn = value == true;
      });
    });
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

  void _saveColorsToFirebase() {
    tempSelectedColors.forEach((action, color) {
      _databaseRef.child(action).set(_getColorName(color));
    });

    setState(() {
      selectedColors = Map.from(tempSelectedColors);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Colors saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateSwitchState(bool value) {
    setState(() {
      isVibrationOn = value;
    });

    _switchStateRef.set(value);
  }

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
      gradient: isDarkMode
          ? LinearGradient(
              colors: [Colors.black, Colors.grey[900]!, Colors.black87],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                Color.fromARGB(255, 236, 184, 201),
                Colors.white,
                Color.fromARGB(255, 212, 184, 243),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                                color:
                                    isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
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
                              SizedBox(
                                height: 15,
                              ),
                            ],
                          );
                        }),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _saveColorsToFirebase,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              backgroundColor: Color.fromARGB(
                                255,
                                243,
                                175,
                                244,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Save Colors",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
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
                            _updateSwitchState(value);
                          },
                          activeColor: Color.fromARGB(255, 229, 172, 240),
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
