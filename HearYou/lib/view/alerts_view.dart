import 'package:flutter/material.dart';

class AlertsViewModel {
  final Map<String, String> eventDisplayNames;
  final Map<String, String> selectedColorNamesTemp; // action -> color name
  final Map<String, Color> colorPalette; // color name -> Color
  final bool isVibrationOn;

  const AlertsViewModel({
    required this.eventDisplayNames,
    required this.selectedColorNamesTemp,
    required this.colorPalette,
    required this.isVibrationOn,
  });
}

class AlertsScreenView extends StatelessWidget {
  final AlertsViewModel model;
  final bool isDarkMode;
  final VoidCallback onBack;
  final void Function(String action, String colorName) onChangeColorName;
  final ValueChanged<bool> onToggleVibration;
  final VoidCallback onSave;

  const AlertsScreenView({
    super.key,
    required this.model,
    required this.isDarkMode,
    required this.onBack,
    required this.onChangeColorName,
    required this.onToggleVibration,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final actions = model.selectedColorNamesTemp.keys.toList();
    final paletteNames = model.colorPalette.keys.toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Alerts Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: Container(
        decoration: BoxDecoration(color: isDarkMode ? Colors.black : Colors.white),
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
                        const SizedBox(height: 20),
                        Text(
                          'Select Alert Colors',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...actions.map((action) {
                          final selectedName = model.selectedColorNamesTemp[action] ?? paletteNames.first;
                          return Column(
                            children: [
                              Card(
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDarkMode
                                          ? const [Color(0xFF1F1A24), Color(0xFF2A2234)]
                                          : const [Colors.white, Color(0xFFF7ECFF)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.deepPurpleAccent.withOpacity(0.25)
                                          : const Color(0xFFE5D6F8),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      model.eventDisplayNames[action] ?? action,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w300,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    trailing: DropdownButton<String>(
                                      value: selectedName,
                                      icon: Icon(Icons.color_lens, color: isDarkMode ? Colors.white : Colors.black),
                                      underline: Container(),
                                      dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                                      onChanged: (String? newName) {
                                        if (newName != null) onChangeColorName(action, newName);
                                      },
                                      items: paletteNames.map((name) {
                                        final color = model.colorPalette[name] ?? Colors.blue;
                                        return DropdownMenuItem<String>(
                                          value: name,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDarkMode ? Colors.white : Colors.black,
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
                              const SizedBox(height: 15),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: Text(
                            'Enable Vibration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          value: model.isVibrationOn,
                          onChanged: onToggleVibration,
                          activeColor: isDarkMode ? Colors.deepPurpleAccent : const Color.fromARGB(255, 229, 172, 240),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton(
                            onPressed: onSave,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                              backgroundColor: isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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


