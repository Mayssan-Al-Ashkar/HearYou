import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'view/events_view.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

// keep using the same FilterType as in view

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
    final items = _events
        .map((e) => EventVM(
              id: e.id,
              title: e.title,
              description: e.description,
              date: e.date,
              time: e.time,
              isImportant: e.isImportant,
              fullDateTime: e.fullDateTime,
            ))
        .toList();

    return EventsScreenView(
      model: EventsViewModel(items: items, eventColors: _eventColors),
      isDarkMode: isDarkMode,
      selectedFilter: _selectedFilter,
      onChangeFilter: (f) => setState(() => _selectedFilter = f),
      parseColor: _parseColorName,
      onToggleImportant: (id) async {
        try {
          final target = _events.firstWhere((e) => e.id == id);
          await http.patch(
            Uri.parse('$apiBase/events/$id'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'isImportant': !target.isImportant}),
          );
          await _listenToEvents();
        } catch (_) {}
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, FilterType type, bool isDarkMode) {
    final bool isActive = _selectedFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        constraints: const BoxConstraints(minHeight: 32),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
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

// EventCard UI moved into view/_EventCard
