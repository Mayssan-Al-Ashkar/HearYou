import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchEventColors();
    _fetchNotificationSetting();
    _listenToEvents();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _listenToEvents());
    _initializeNotifications();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEventColors() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/settings/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final settings = data['settings'] as Map<String, dynamic>?;
        final colors = (settings?['colors'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _eventColors = colors.map((k, v) => MapEntry(k, v.toString()));
        });
      }
    } catch (_) {}
  }

  void _fetchNotificationSetting() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/settings/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final settings = data['settings'] as Map<String, dynamic>?;
        setState(() {
          isNotificationsEnabled = (settings?['vibration'] == true);
        });
      }
    } catch (_) {}
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
    defaultValue: 'http://192.168.0.5:5000',
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
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [const Color(0xFF1F1A24), const Color(0xFF2A2234)]
                      : [Colors.white, const Color(0xFFF7ECFF)],
                ),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.deepPurpleAccent.withOpacity(0.25)
                      : const Color(0xFFE5D6F8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFilterChip(context, 'All', FilterType.all, isDarkMode),
                  _buildFilterChip(context, 'Today', FilterType.today, isDarkMode),
                  _buildFilterChip(context, 'Yesterday', FilterType.yesterday, isDarkMode),
                  _buildFilterChip(context, 'Before', FilterType.before, isDarkMode),
                  _buildFilterChip(context, 'Favorite', FilterType.favorite, isDarkMode),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
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
                              case 'doorbell':
                                eventKey = 'door_knocking';
                                break;
                              case 'baby crying':
                                eventKey = 'baby_crying';
                                break;
                              case 'phone call':
                                eventKey = 'phone_call';
                                break;
                              case 'other sound':
                                eventKey = 'additional_event';
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

  Widget _buildFilterChip(BuildContext context, String label, FilterType type, bool isDarkMode) {
    final bool isActive = _selectedFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? (isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
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
  final DateTime? eventAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.isImportant,
    this.eventAt,
  });

  factory Event.fromJson(Map<String, dynamic> data) {
    final dateString = data['date'] ?? '';
    DateTime parsedDate;
    try {
      parsedDate = DateFormat("MM/dd/yyyy").parse(dateString);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    DateTime? eventAt;
    try {
      if (data['eventAt'] != null) {
        eventAt = DateTime.parse(data['eventAt']).toLocal();
      }
    } catch (_) {}
    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: parsedDate,
      time: data['time'] ?? '',
      isImportant: data['isImportant'] ?? false,
      eventAt: eventAt,
    );
  }

  DateTime get fullDateTime {
    if (eventAt != null) return eventAt!;
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
