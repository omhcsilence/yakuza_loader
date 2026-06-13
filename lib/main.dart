import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() => runApp(const YakuzaApp());

class YakuzaApp extends StatelessWidget {
  const YakuzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YakuzaXsilence',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF0F0A1F),
      ),
      home: const LoaderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
  double progress = 0;
  String status = "Initializing...";
  String? localPath;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final dir = await getApplicationDocumentsDirectory();
    localPath = dir.path;
    await _checkAndUpdate();
  }

  Future<void> _checkAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt('asset_version') ?? 0;

    setState(() => status = "Checking for updates...");

    try {
      final response = await _dio.get(
        'https://raw.githubusercontent.com/OmhcSilence/yakuza_assets/main/version.txt'
      );
      final remoteVersion = int.parse(response.data.toString().trim());

      if (remoteVersion > localVersion) {
        await _downloadAssets(remoteVersion, prefs);
      } else {
        setState(() => status = "Assets up to date!");
        await Future.delayed(const Duration(seconds: 1));
        _loadWebView();
      }
    } catch (e) {
      setState(() => status = "Loading offline...");
      await Future.delayed(const Duration(seconds: 2));
      _loadWebView();
    }
  }

  Future<void> _downloadAssets(int newVersion, SharedPreferences prefs) async {
    setState(() => status = "Downloading new assets...");

    final htmlPath = '$localPath/index.html';

    await _dio.download(
      'https://raw.githubusercontent.com/OmhcSilence/yakuza_assets/main/index.html',
      htmlPath,
      onReceiveProgress: (received, total) {
        setState(() {
          progress = received / total;
          status = "Downloading: ${(progress * 100).toStringAsFixed(0)}%";
        });
      },
    );

    await prefs.setInt('asset_version', newVersion);
    setState(() => status = "Download complete!");
    await Future.delayed(const Duration(seconds: 1));
    _loadWebView();
  }

  void _loadWebView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const YakuzaWebView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0A1F), Color(0xFF02000A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.games,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFA78BFA)],
                ).createShader(bounds),
                child: const Text(
                  "YakuzaXsilence",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Developer: OmhcSilence",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                status,
                style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (progress > 0)
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class YakuzaWebView extends StatelessWidget {
  const YakuzaWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..loadRequest(
            Uri.parse(
              'https://raw.githubusercontent.com/OmhcSilence/yakuza_assets/main/index.html',
            ),
          ),
      ),
    );
  }
}
