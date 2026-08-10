import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/gemini_dart_response.dart';

class GeminiServices {
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final String _model = 'gemini-1.5-flash-latest';

  Future<GeminiResponse> analyzeImage(XFile imageFile) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      print("API Key present: ${apiKey.isNotEmpty}");

      if (apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found. Please check your .env file');
      }

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');
      print("Request URL: ${url.toString().replaceRange(url.toString().indexOf('key=')+4, url.toString().length, '***')}");

      final bytes = await imageFile.readAsBytes();
      print("Image size: ${bytes.length} bytes");
      
      final base64Image = base64Encode(bytes);
      
      // Determine MIME type
      String mimeType = 'image/jpeg';
      final name = imageFile.name.toLowerCase();
      if (name.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (name.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (name.endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      print("MIME Type: $mimeType");

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              },
              {
                'text': 'Analyze this image and provide a detailed description.'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 1024,
        }
      });

      print("Sending request to Gemini API...");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("Response received successfully");
        return GeminiResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Bad request: ${error['error']['message']}');
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or has insufficient permissions');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to analyze image. Status: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      print('Error in analyzeImage: $e');
      rethrow;
    }
  }
}