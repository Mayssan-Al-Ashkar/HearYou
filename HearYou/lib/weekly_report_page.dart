import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;
  final Set<String> _dismissedReportIds = <String>{};

  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Future<void> _fetch() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() { _reports = []; _loading = false; });
        return;
      }
      // Query by userId and email to be robust against field naming in Mongo
      final uri = Uri.parse('$apiBase/weekly_reports/?userId=${user.uid}&email=${Uri.encodeQueryComponent(user.email ?? '')}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List items = data['reports'] ?? [];
        setState(() { _reports = items.cast<Map<String, dynamic>>(); _loading = false; });
      } else {
        setState(() { _error = 'Failed to load reports'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load reports'; _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        title: Text(
          'Weekly Reports',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)))
              : (_reports.isEmpty
                  ? Center(
                      child: Text(
                        'No weekly reports yet',
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = _reports[index];
                          final summary = (data['summary'] ?? '').toString();
                          final recs = (data['recommendations'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                          final createdAt = (data['generatedAt'] ?? data['createdAt'] ?? '').toString();
                          final reportId = (data['id'] ?? data['_id'] ?? index.toString()).toString();
                          if (_dismissedReportIds.contains(reportId)) {
                            return const SizedBox.shrink();
                          }
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Weekly Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      if (summary.isNotEmpty) Text(summary, style: const TextStyle(fontSize: 14)),
                                      if (recs.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        ...recs.map((r) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              if ((r['detail'] ?? '').toString().isNotEmpty)
                                                Text(r['detail'] ?? '', style: const TextStyle(color: Colors.black54)),
                                            ],
                                          ),
                                        )),
                                      ],
                                      if (createdAt.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    tooltip: 'Mark report as read',
                                    onPressed: () {
                                      setState(() {
                                        _dismissedReportIds.add(reportId);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )),
    );
  }
}


