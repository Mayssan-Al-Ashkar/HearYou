import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final String videoUrl = 'http://192.168.0.10:5000/video_feed';
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(videoUrl));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetZoom();
    });
  }

  Future<void> moveCamera(String direction) async {
    try {
      final url = Uri.parse('http://192.168.0.10:5000/control/$direction');
      await http.get(url);
    } catch (e) {
      print("Move camera failed: $e");
    }
  }

  Future<void> zoom(String action) async {
    try {
      final url = Uri.parse('http://192.168.0.10:5000/control/$action');
      await http.get(url);
    } catch (e) {
      print("Zoom failed: $e");
    }
  }

  Future<void> resetZoom() async {
    try {
      final url = Uri.parse('http://192.168.0.10:5000/reset_zoom');
      await http.get(url);
      print("Zoom reset to default");
    } catch (e) {
      print("Reset zoom failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final buttonBgColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final buttonFgColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: Column(
        children: [
          const SizedBox(height: 100),
          
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: WebViewWidget(controller: _controller),
          ),
          
          const SizedBox(height: 70),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 30), 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 40),
                  onPressed: () => moveCamera("up"),
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => zoom("zoom_in"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        backgroundColor: buttonBgColor,
                        foregroundColor: buttonFgColor,
                      ),
                      child: const Icon(Icons.zoom_in, size: 24),
                    ),
                    
                    const SizedBox(width: 15),
                    
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_left, size: 40),
                      onPressed: () => moveCamera("left"),
                    ),
                    
                    const SizedBox(width: 40),
                    
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_right, size: 40),
                      onPressed: () => moveCamera("right"),
                    ),
                    
                    const SizedBox(width: 15), 
                    
                    ElevatedButton(
                      onPressed: () => zoom("zoom_out"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        backgroundColor: buttonBgColor,
                        foregroundColor: buttonFgColor,
                      ),
                      child: const Icon(Icons.zoom_out, size: 24),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 40),
                  onPressed: () => moveCamera("down"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}