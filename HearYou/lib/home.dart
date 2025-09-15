import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'alerts.dart';
import 'events.dart';
import 'sos.dart';
import 'camera.dart';
import 'settings.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'dart:async';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

 

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

  Widget _buildAssistantPanel(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.6,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Color(0xFF1F1A24), Color(0xFF2A2234)]
                  : [Color(0xFFF7F3FF), Color(0xFFEDE6FF)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDarkMode
                  ? Colors.deepPurpleAccent.withOpacity(0.25)
                  : Color(0xFFE5D6F8),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : Color(0xFFB388FF).withOpacity(0.12),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent,
                          Color(0xFF7E57C2),
                        ],
                      ),
                    ),
                    child: Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Spacer(),
                  if (_agentLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _agentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendAgentCommand(),
                      decoration: InputDecoration(
                        hintText: 'Ask to change settings... ',
                        filled: true,
                        fillColor: isDarkMode ? Color(0xFF2B2234) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _agentLoading ? null : () => _sendAgentCommand(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.send),
                    label: Text('Send'),
                  ),
                ],
              ),
              if (_agentAnswer != null && _agentAnswer!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Color(0xFF2B2234) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.deepPurpleAccent.withOpacity(0.25)
                          : Color(0xFFE5D6F8),
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Text(
                    _agentAnswer!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _agentSuggestions.map((s) {
                  return ActionChip(
                    label: Text(s),
                    onPressed: _agentLoading ? null : () => _sendAgentCommand(s),
                    backgroundColor: isDarkMode ? Color(0xFF2B2234) : Colors.white,
                    shape: StadiumBorder(side: BorderSide(color: isDarkMode ? Colors.deepPurpleAccent.withOpacity(0.25) : Color(0xFFE5D6F8))),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
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



// phone calling 
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
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await http.post(
        Uri.parse('$apiBase/events/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'title': title,
          'eventAt': nowIso,
          'source': 'phone_state',
        }),
      );
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(extendBodyBehindAppBar: true, 
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0, 
    titleSpacing: 16,
    automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child:
                  userPhotoUrl.isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          userPhotoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, color: Colors.grey[600]);
                          },
                        ),
                      )
                      : Icon(Icons.person, color: Colors.grey[600]),
            ),
            SizedBox(width: 8),
            if (userName.isNotEmpty)
              Text(
                userName,
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              var themeProvider = Provider.of<ThemeProvider>(context);
              bool isDarkMode = themeProvider.isDarkMode;

              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.all(50.0)),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Card(
                      key: sliderKey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          sliderImages[currentImageIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final key =
                      item['title'] == 'Camera'
                          ? cameraKey
                          : item['title'] == 'Alerts'
                          ? alertsKey
                          : item['title'] == 'Events'
                          ? eventsKey
                          : item['title'] == 'SOS'
                          ? sosKey
                          : null;

                  return InkWell(
                    onTap: () async {
                      if (item['title'] == 'SOS') {
                        DateTime now = DateTime.now();
                        if (firstSosTapTime == null ||
                            now.difference(firstSosTapTime!) >
                                sosTriggerDuration) {
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
                    child: Card(
                      key: key,
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
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.transparent
                                  : Color(0xFFB388FF).withOpacity(0.08),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isDarkMode
                                      ? [Colors.deepPurpleAccent, Color(0xFF7E57C2)]
                                      : [Color(0xFFF0B8F6), Color(0xFFE0C4FF)],
                                ),
                              ),
                              child: Icon(
                                item['title'] == 'Camera'
                                    ? Icons.photo_camera
                                    : item['title'] == 'Alerts'
                                    ? Icons.notifications_active
                                    : item['title'] == 'Events'
                                    ? Icons.event_note
                                    : Icons.emergency,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Material(
                color: isDarkMode ? Colors.deepPurpleAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                elevation: 6,
                child: isDarkMode
                    ? InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => _buildAssistantPanel(isDarkMode),
                          );
                        },
                        child: Center(
                          child: Icon(Icons.auto_awesome, color: Colors.white),
                        ),
                      )
                    : Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Color(0xFFF0B8F6),
                              Color(0xFFE0C4FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => _buildAssistantPanel(isDarkMode),
                            );
                          },
                          child: Center(
                            child: Icon(Icons.auto_awesome, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
