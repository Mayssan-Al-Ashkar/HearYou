import 'api_client.dart';

class EventsService {
  final ApiClient _client;
  EventsService(this._client);

  Future<List<Map<String, dynamic>>> listEvents() async {
    final data = await _client.getJson('/events/');
    final items = (data['events'] as List<dynamic>? ) ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> postEvent(String title, {bool isImportant = false, DateTime? at}) async {
    await _client.postJson('/events/', {
      'title': title,
      'isImportant': isImportant,
      if (at != null) 'eventAt': at.toUtc().toIso8601String(),
    });
  }

  Future<void> toggleImportant(String eventId, bool next) async {
    await _client.patchJson('/events/$eventId', {
      'isImportant': next,
    });
  }
}


