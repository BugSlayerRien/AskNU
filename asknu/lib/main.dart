import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/image_analyzer_page.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment loaded successfully");
    
    // Check if API key is loaded
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("WARNING: GEMINI_API_KEY is empty or not found in .env file");
    } else {
      print("API Key loaded: ${apiKey.substring(0, 10)}...");
    }
  } catch (e) {
    print("Error loading .env file: $e");
    print("Please create a .env file with GEMINI_API_KEY");
  }
  
  // Error handling for the app
  runApp(const GeminiApp());
}

class GeminiApp extends StatelessWidget {
  const GeminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Image Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ImageAnalyzerPage(),
    );
  }
}