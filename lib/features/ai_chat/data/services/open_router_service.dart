import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String modelId;
  final String apiUrl;

  OpenRouterService({
    required this.apiKey,
    this.modelId = 'mistralai/mistral-7b-instruct',
    this.apiUrl = 'https://openrouter.ai/api/v1/chat/completions',
  });

  Stream<String> generateStreamingResponse(String prompt) async* {
    try {
      final url = Uri.parse(apiUrl);
      print('Making API call to: $url');
      print('With prompt: $prompt');

      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/yourusername/your-repo',
        'X-Title': 'Cosmos Viewer',
      };

      final body = jsonEncode({
        "model": modelId,
        "stream": true,
        "messages": [
          {"role": "user", "content": prompt}
        ]
      });

      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          // Split the chunk by newlines to handle multiple JSON objects
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            if (line.trim() == 'data: [DONE]') continue;

            try {
              // Remove the "data: " prefix if present
              final jsonStr =
                  line.startsWith('data: ') ? line.substring(6) : line;
              final jsonData = jsonDecode(jsonStr);

              if (jsonData['choices'] != null &&
                  jsonData['choices'].isNotEmpty &&
                  jsonData['choices'][0]['delta'] != null &&
                  jsonData['choices'][0]['delta']['content'] != null) {
                final content = jsonData['choices'][0]['delta']['content'];
                yield content;
              }
            } catch (e) {
              print('Error parsing chunk: $e');
              print('Problematic chunk: $line');
            }
          }
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        print('API Error: ${response.statusCode} - $errorBody');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in generateStreamingResponse: $e');
      throw Exception('Error generating response: $e');
    }
  }
}
