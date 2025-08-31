import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

enum FilterType { all, today, yesterday, before, favorite }

class _EventsPageState extends State<EventsPage> {
  List<Event> _events = [];
  FilterType _selectedFilter = FilterType.all;
  Map<String, String> _eventColors = {}; // Holds data from Realtime DB
  bool isNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchEventColors();
    _fetchNotificationSetting();
    _listenToEvents();
    _initializeNotifications();
  }

  Future<void> _fetchEventColors() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref().child(
      'colors',
    );

    try {
      DatabaseEvent event = await ref.once();
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          // Store the original keys without modification
          _eventColors = data.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        });
        print('Fetched colors: $_eventColors');
      }
    } catch (e) {
      print('Error fetching colors: $e');
    }
  }

  void _fetchNotificationSetting() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref(
      "notification_control",
    );

    final snapshot = await ref.get();
    if (snapshot.exists) {
      final value = snapshot.value.toString();
      setState(() {
        isNotificationsEnabled = value == "enable";
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Future<void> _listenToEvents() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/events/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List<dynamic> items = data['events'] ?? [];
        final currentEvents = items.map((e) => Event.fromJson(e)).toList()
          ..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime));

        if (_events.isNotEmpty && currentEvents.length > _events.length) {
          final newEvents = currentEvents
              .where((e) => !_events.any((old) => old.id == e.id))
              .toList();
          if (newEvents.isNotEmpty) {
            _showNotification(newEvents.first);
          }
        }

        setState(() {
          _events = currentEvents;
        });
      }
    } catch (_) {}
  }

  void _showNotification(Event event) async {
    if (!isNotificationsEnabled) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'event_channel_id',
          'Event Notifications',
          channelDescription: 'Notifies when a new event is added',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Event: ${event.title}',
      event.description,
      platformDetails,
    );
  }

  List<Event> getFilteredEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return _events.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      switch (_selectedFilter) {
        case FilterType.today:
          return eventDate.isAtSameMomentAs(today);
        case FilterType.yesterday:
          return eventDate.isAtSameMomentAs(yesterday);
        case FilterType.before:
          return eventDate.isBefore(yesterday);
        case FilterType.favorite:
          return event.isImportant;
        case FilterType.all:
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredEvents = getFilteredEvents();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [
                  Color.fromARGB(255, 195, 155, 239),
                  Color.fromARGB(255, 241, 166, 211),
                ],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleButtons(
              isSelected: [
                _selectedFilter == FilterType.all,
                _selectedFilter == FilterType.today,
                _selectedFilter == FilterType.yesterday,
                _selectedFilter == FilterType.before,
                _selectedFilter == FilterType.favorite,
              ],
              onPressed: (index) {
                setState(() {
                  _selectedFilter = FilterType.values[index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Today'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Yesterday'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Before'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('Favorite'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDarkMode
                          ? [Colors.black, Colors.grey[900]!, Colors.black87]
                          : [
                            const Color.fromARGB(255, 236, 184, 201),
                            Colors.white,
                            const Color.fromARGB(255, 212, 184, 243),
                          ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child:
                  filteredEvents.isEmpty
                      ? const Center(child: Text('No events available.'))
                      : RefreshIndicator(
                        onRefresh: () async {
                          _listenToEvents();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            // Convert the event title to match the database format
                            String eventKey = '';
                            switch (event.title.toLowerCase()) {
                              case 'high temperature':
                                eventKey = 'additional_event';
                                break;
                              case 'low temperature':
                                eventKey = 'additional_event';
                                break;
                              case 'door knocking':
                                eventKey = 'door_knocking';
                                break;
                              case 'baby crying':
                                eventKey = 'baby_crying';
                                break;
                              case 'phone call':
                                eventKey = 'phone_call';
                                break;
                              default:
                                eventKey = 'additional_event';
                            }

                            final colorName = _eventColors[eventKey] ?? 'grey';
                            print(
                              'Event: ${event.title}, Key: $eventKey, Color: $colorName',
                            );
                            final color = _parseColorName(colorName);

                            return EventCard(
                              event: event,
                              lineColor: color,
                              onToggleImportant: () async {
                                try {
                                  await http.patch(
                                    Uri.parse('$apiBase/events/${event.id}'),
                                    headers: {"Content-Type": "application/json"},
                                    body: jsonEncode({
                                      'isImportant': !event.isImportant,
                                    }),
                                  );
                                  await _listenToEvents();
                                } catch (_) {}
                              },
                            );
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColorName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final bool isImportant;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.isImportant,
  });

  factory Event.fromJson(Map<String, dynamic> data) {
    final dateString = data['date'] ?? '';
    DateTime parsedDate;
    try {
      parsedDate = DateFormat("MM/dd/yyyy").parse(dateString);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: parsedDate,
      time: data['time'] ?? '',
      isImportant: data['isImportant'] ?? false,
    );
  }

  DateTime get fullDateTime {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onToggleImportant;
  final Color lineColor;

  const EventCard({
    super.key,
    required this.event,
    required this.onToggleImportant,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        event.isImportant ? Icons.favorite : Icons.favorite_border,
                        color:
                            event.isImportant
                                ? Colors.red[700]
                                : Colors.grey,
                      ),
                      onPressed: onToggleImportant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat("MM/dd/yyyy").format(event.date)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Time: ${event.time}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
