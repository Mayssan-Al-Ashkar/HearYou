import 'package:flutter/material.dart';

class AppConfig {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );
}

class AppConstants {
  static const String eventBabyCrying = 'baby_crying';
  static const String eventDoorKnocking = 'door_knocking';
  static const String eventPhoneCall = 'phone_call';
  static const String eventBabyMovement = 'baby_movement';

  static const Map<String, String> eventDisplayNames = {
    eventBabyCrying: 'Baby Crying',
    eventDoorKnocking: 'Door Knocking',
    eventPhoneCall: 'Phone Call',
    eventBabyMovement: 'Baby Movement',
  };
}

class AppGradients {
  static const List<Color> badgeDark = [Colors.deepPurpleAccent, Color(0xFF7E57C2)];
  static const List<Color> badgeLight = [Color(0xFFF0B8F6), Color(0xFFE0C4FF)];
  static const List<Color> cardDark = [Color(0xFF1F1A24), Color(0xFF2A2234)];
  static const List<Color> cardLight = [Colors.white, Color(0xFFF7ECFF)];
}


