import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'alerts.dart';
import 'events.dart';
import 'sos.dart';
import 'camera.dart';
import 'settings.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'dart:async';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/events_service.dart';
import 'services/api_client.dart';
import 'view/home_view.dart';

const platform = MethodChannel('com.example.call/audio');

void _startCallWithAudio() async {
  try {
    await platform.invokeMethod('startCall');
  } on PlatformException catch (e) {
    print("Failed to start call: '${e.message}'.");
  }
}

class HomeScreen extends StatefulWidget {
  final bool showTutorialOnOpen;
  const HomeScreen({super.key, this.showTutorialOnOpen = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userPhotoUrl = '';
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int sosTapCount = 0;
  DateTime? firstSosTapTime;
  final Duration sosTriggerDuration = Duration(milliseconds: 1500);

  final GlobalKey cameraKey = GlobalKey();
  final GlobalKey alertsKey = GlobalKey();
  final GlobalKey eventsKey = GlobalKey();
  final GlobalKey sosKey = GlobalKey();
  final GlobalKey sliderKey = GlobalKey();

  List<TargetFocus> targets = [];

  final List<Map<String, dynamic>> items = [
    {'image': 'images/camera.png', 'title': 'Camera', 'page': CameraPage()},
    {
      'image': 'images/alertSetting.png',
      'title': 'Alerts',
      'page': AlertsPage(),
    },
    {'image': 'images/eventlog1.png', 'title': 'Events', 'page': EventsPage()},
    {'image': 'images/SOS.png', 'title': 'SOS', 'page': SOSPage()},
  ];

  final List<String> sliderImages = [
    'images/image1.jpg',
    'images/image2.jpg',
    'images/image3.jpg',
    'images/image4.jpg',
  ];

  int currentImageIndex = 0;
  Timer? sliderTimer;

  final TextEditingController _agentController = TextEditingController();
  bool _agentLoading = false;
  String? _agentAnswer;
  late final EventsService _eventsService;

  final List<String> _agentSuggestions = [
    'turn off vibration',
    'set door knocking color to blue',
    'set quiet hours from 21:00 to 07:00',
    'prioritize baby crying',
  ];

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );

  @override
  void initState() {
    super.initState();
    _eventsService = EventsService(ApiClient());
    _loadUserData();
    _listenToPhoneCalls();
    _startImageSlider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createTutorialTargets();
      if (widget.showTutorialOnOpen) {
        _showTutorial();
      }
    });
  }

  HomeViewModel _toModel() {
    return HomeViewModel(
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      items: items,
      sliderImages: sliderImages,
      currentImageIndex: currentImageIndex,
      agentSuggestions: _agentSuggestions,
      agentController: _agentController,
      agentLoading: _agentLoading,
      agentAnswer: _agentAnswer,
      cameraKey: cameraKey,
      alertsKey: alertsKey,
      eventsKey: eventsKey,
      sosKey: sosKey,
      sliderKey: sliderKey,
    );
  }

  Widget _buildAssistantPanel(bool isDarkMode) {
    return HomeAssistantPanel(
      isDarkMode: isDarkMode,
      model: _toModel(),
      onSendAgentCommand: (String? text) => _sendAgentCommand(text),
    );
  }

  void _startImageSlider() {
    sliderTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      setState(() {
        currentImageIndex = (currentImageIndex + 1) % sliderImages.length;
      });
    });
  }

  @override
  void dispose() {
    sliderTimer?.cancel();
    _agentController.dispose();
    super.dispose();
  }

  Future<void> _listenToPhoneCalls() async {
    final phonePermission = await Permission.phone.request();

    if (phonePermission.isGranted) {
      PhoneState.stream.listen((event) {
        print("Phone state event: ${event.status}");

        if (event.status == PhoneStateStatus.CALL_INCOMING) {
          print(" Incoming call detected");
          _updateRealtimeDatabase("PHONE CALLING");
          _postEventToMongo("phone call");
        } else if (event.status == PhoneStateStatus.CALL_ENDED) {
          print(" Call ended, resetting message to NULL");
          _updateRealtimeDatabase("NULL");
        }
      });
    } else {
      print("Phone permission not granted.");
    }
  }

  Future<void> _postEventToMongo(String title) async {
    try {
      await _eventsService.postEvent(title, at: DateTime.now());
    } catch (_) {}
  }

  Future<void> _sendAgentCommand([String? textOverride]) async {
    final text = (textOverride ?? _agentController.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _agentLoading = true;
      _agentAnswer = null;
    });
    try {
      final resp = await http.post(
        Uri.parse('$apiBase/agent/command'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": text}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _agentAnswer = (data['answer'] ?? '').toString();
        });
      } else {
        setState(() {
          _agentAnswer = 'Request failed (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _agentAnswer = 'Network error';
      });
    } finally {
      setState(() {
        _agentLoading = false;
      });
    }
  }

  Future<void> _updateRealtimeDatabase(String message) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child("Notifications").update({"message": message});
      print(" Realtime Database updated: $message");
    } catch (e) {
      print("Error updating Realtime Database: $e");
    }
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .get();

      if (userData.exists) {
        final firestorePhotoUrl = userData.data()?['photoURL'];
        setState(() {
          userName = userData.data()?['name'] ?? '';
          userPhotoUrl = currentUser!.photoURL ?? firestorePhotoUrl ?? '';
        });
      }

      await currentUser!.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser?.photoURL != null &&
          refreshedUser!.photoURL!.isNotEmpty) {
        setState(() {
          userPhotoUrl = refreshedUser.photoURL!;
        });
      }
    }
  }

  void _createTutorialTargets() {
    targets = [
      TargetFocus(
        identify: "Camera",
        keyTarget: cameraKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              children: [
                Text(
                  "Camera",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Here you can monitor your child during sleep.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Alerts",
        keyTarget: alertsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              children: [
                Text(
                  "Alerts",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "You can here choose the specific color to the specific action.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Events",
        keyTarget: eventsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              children: [
                Text(
                  "Events",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Here you can see all recent happened events.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "SOS",
        keyTarget: sosKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              children: [
                Text(
                  "SOS",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Tap 5 times to handle an emergency call.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Slider",
        keyTarget: sliderKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              children: [
                Text(
                  "Gallery",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Swipe or wait to see different images.",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    return HomeScreenView(
      model: _toModel(),
      isDarkMode: isDarkMode,
      onToggleTheme: () => themeProvider.toggleTheme(),
      onOpenSettings: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
      },
      onGridTap: (index) async {
        final item = items[index];
        if (item['title'] == 'SOS') {
          DateTime now = DateTime.now();
          if (firstSosTapTime == null ||
              now.difference(firstSosTapTime!) > sosTriggerDuration) {
            firstSosTapTime = now;
            sosTapCount = 1;
          } else {
            sosTapCount++;
          }
          if (sosTapCount == 5) {
            sosTapCount = 0;
            firstSosTapTime = null;
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SOSPage()),
            );
          }
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item['page']),
          );
        }
      },
      onOpenAssistantPanel: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _buildAssistantPanel(isDarkMode),
        );
      },
    );
  }
}
