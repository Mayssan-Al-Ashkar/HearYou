import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class TempOverviewPage extends StatefulWidget {
  const TempOverviewPage({super.key});

  @override
  _TempOverviewPageState createState() => _TempOverviewPageState();
}

class _TempOverviewPageState extends State<TempOverviewPage> {
  final _realtimeRef = FirebaseDatabase.instance.ref();
  double? temp, maxTemp, minTemp;
  List<FlSpot> tempHistorySpots = [];
  List<String> timeLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchRealtimeData();
    _fetchFirestoreLogs();
  }

  void _fetchRealtimeData() {
    _realtimeRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final rawMax = data['maxtemp'];
      final rawMin = data['mintemp'];
      final rawTemp = data['temp'];

      setState(() {
        temp = rawTemp is num ? rawTemp.toDouble() : double.tryParse(rawTemp.toString()) ?? 0;
        maxTemp = rawMax is num ? rawMax.toDouble() : double.tryParse(rawMax.toString()) ?? 0;
        minTemp = rawMin is num ? rawMin.toDouble() : double.tryParse(rawMin.toString()) ?? 0;
      });
    });
  }

  void _fetchFirestoreLogs() async {
    final snapshot = await FirebaseFirestore.instance.collection('temp_and_humidity').get();

    List<Map<String, dynamic>> sortedData = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final tempValue = data['temperature'];
      final String? time = data['time'];
      final String? date = data['date'];

      if (tempValue is num && time != null && date != null) {
        try {
          final combinedDateTime = _parseDateTime(date, time);
          sortedData.add({
            'datetime': combinedDateTime,
            'temperature': tempValue,
            'label': "$time\n${date.split("/").take(2).join("/")}",
          });
        } catch (e) {
          print("❌ Skipping invalid date/time: $date $time");
        }
      }
    }

    sortedData.sort((a, b) => a['datetime'].compareTo(b['datetime']));

    final List<FlSpot> spots = [];
    final List<String> labels = [];

    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedData[i]['temperature'].toDouble()));
      labels.add(sortedData[i]['label']);
    }

    setState(() {
      tempHistorySpots = spots;
      timeLabels = labels;
    });
  }

  DateTime _parseDateTime(String date, String time) {
    final parts = date.split('/');
    final timeParts = time.split(':');
    if (parts.length != 3 || timeParts.length != 2) throw FormatException();

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(year, month, day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final double currentTemp = temp ?? 0;
    final double min = minTemp ?? 0;
    final double max = maxTemp ?? 0;

    final double progress = ((currentTemp - min) / (max - min)).clamp(0.0, 1.0);
    final double arcRadius = 125;
    final double startAngle = 3 * pi / 4;
    final double sweepAngle = 3 * pi / 2;
    final double endAngle = startAngle + sweepAngle;

    const Offset center = Offset(125, 125);
    Offset getLabelPos(double angle, {double padding = 16}) => Offset(
          center.dx + (arcRadius + padding) * cos(angle),
          center.dy + (arcRadius + padding) * sin(angle),
        );

    final Offset minPos = getLabelPos(startAngle);
    final Offset maxPos = getLabelPos(endAngle);

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Color(0xFFC39BEF), Color(0xFFF1A6D3)],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            "Temperature Overview",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? LinearGradient(
                  colors: [Colors.black, Colors.grey[900]!, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [
                    Color.fromARGB(255, 236, 184, 201),
                    Colors.white,
                    Color.fromARGB(255, 212, 184, 243),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text("Temperature Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 250,
                child: tempHistorySpots.isEmpty
                    ? Center(child: Text("Loading graph..."))
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 50,
                          lineBarsData: [
                            LineChartBarData(
                              spots: tempHistorySpots,
                              isCurved: true,
                              color: Colors.green,
                              dotData: FlDotData(show: false),
                              barWidth: 2,
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < timeLabels.length - 1) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 6,
                                      child: Text(
                                        timeLabels[index],
                                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },

                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 10,
                                getTitlesWidget: (value, _) => Text('${value.toInt()}°C'),
                                reservedSize: 40,
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingVerticalLine: (_) => FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                            drawHorizontalLine: true,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
              ),
              SizedBox(height: 32),
              Text("Current Temperature", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: TemperatureArcPainter(progress: progress),
                        ),
                      ),
                    ),
                    Positioned(
                      left: minPos.dx - 10,
                      top: minPos.dy - 10,
                      child: Text(
                        "❄️ ${min.toInt()}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      left: maxPos.dx - 10,
                      top: maxPos.dy - 10,
                      child: Text(
                        "${max.toInt()} 🔥",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          currentTemp.toInt().toString(),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 69, 68, 68),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemperatureArcPainter extends CustomPainter {
  final double progress;
  final Color startColor;
  final Color endColor;

  TemperatureArcPainter({
    required this.progress,
    this.startColor = Colors.blue,
    this.endColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 20.0;

    final startAngle = 3 * pi / 4;
    final sweepAngle = 3 * pi / 2;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, bgPaint);

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 3 * pi / 2,
      colors: [Colors.blue, Colors.red, Colors.transparent],
      stops: [0.0, 1.0, 1.0],
      transform: GradientRotation(startAngle),
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    final pointerAngle = startAngle + sweepAngle * progress;
    final pointerOffset = Offset(
      center.dx + radius * cos(pointerAngle),
      center.dy + radius * sin(pointerAngle),
    );

    final pointerPaint = Paint()..color = const Color.fromARGB(255, 216, 208, 208);
    canvas.drawCircle(pointerOffset, 12.0, pointerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
