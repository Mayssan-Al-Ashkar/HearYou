import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventsViewModel {
  final List<EventVM> items;
  final Map<String, String> eventColors; // key -> color name

  const EventsViewModel({
    required this.items,
    required this.eventColors,
  });
}

class EventVM {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final bool isImportant;
  final DateTime fullDateTime;

  const EventVM({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.isImportant,
    required this.fullDateTime,
  });
}

enum FilterType { all, today, yesterday, before, favorite }

class EventsScreenView extends StatelessWidget {
  final EventsViewModel model;
  final bool isDarkMode;
  final FilterType selectedFilter;
  final void Function(FilterType) onChangeFilter;
  final Color Function(String colorName) parseColor;
  final void Function(String eventId) onToggleImportant;

  const EventsScreenView({
    super.key,
    required this.model,
    required this.isDarkMode,
    required this.selectedFilter,
    required this.onChangeFilter,
    required this.parseColor,
    required this.onToggleImportant,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    List<EventVM> filtered = model.items.where((e) {
      final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
      switch (selectedFilter) {
        case FilterType.today:
          return eventDate.isAtSameMomentAs(today);
        case FilterType.yesterday:
          return eventDate.isAtSameMomentAs(yesterday);
        case FilterType.before:
          return eventDate.isBefore(yesterday);
        case FilterType.favorite:
          return e.isImportant;
        case FilterType.all:
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color.fromARGB(255, 195, 155, 239),
              Color.fromARGB(255, 241, 166, 211),
            ],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Events',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode ? const [Color(0xFF1F1A24), Color(0xFF2A2234)] : const [Colors.white, Color(0xFFF7ECFF)],
                ),
                border: Border.all(color: isDarkMode ? Colors.deepPurpleAccent.withOpacity(0.25) : const Color(0xFFE5D6F8)),
              ),
              child: Row(
                children: [
                  Expanded(child: Center(child: _chip('All', FilterType.all))),
                  Expanded(child: Center(child: _chip('Today', FilterType.today))),
                  Expanded(child: Center(child: _chip('Yesterday', FilterType.yesterday))),
                  Expanded(child: Center(child: _chip('Before', FilterType.before))),
                  Expanded(child: Center(child: _chip('Important', FilterType.favorite))),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: isDarkMode ? Colors.black : Colors.white),
              child: filtered.isEmpty
                  ? const Center(child: Text('No events available.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final e = filtered[index];
                        final key = _normalizeKey(e.title);
                        final color = parseColor(model.eventColors[key] ?? 'grey');
                        return _EventCard(
                          event: e,
                          lineColor: color,
                          onToggleImportant: () => onToggleImportant(e.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeKey(String title) {
    switch (title.toLowerCase()) {
      case 'high temperature':
      case 'low temperature':
      case 'other sound':
        return 'additional_event';
      case 'door knocking':
      case 'doorbell':
        return 'door_knocking';
      case 'baby crying':
        return 'baby_crying';
      case 'phone call':
        return 'phone_call';
      case 'baby movement':
        return 'baby_movement';
      default:
        return 'additional_event';
    }
  }

  Widget _chip(String label, FilterType type) {
    final bool isActive = selectedFilter == type;
    return GestureDetector(
      onTap: () => onChangeFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? (isDarkMode ? Colors.deepPurpleAccent : const Color(0xFFF0B8F6)) : Colors.transparent,
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
              color: isActive ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventVM event;
  final VoidCallback onToggleImportant;
  final Color lineColor;

  const _EventCard({required this.event, required this.onToggleImportant, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(event.isImportant ? Icons.favorite : Icons.favorite_border, color: event.isImportant ? Colors.red[700] : Colors.grey),
                        onPressed: onToggleImportant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Date: ${DateFormat("MM/dd/yyyy").format(event.date)}', style: const TextStyle(color: Colors.grey)),
                  Text('Time: ${DateFormat("HH:mm").format(event.fullDateTime.toLocal())}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


