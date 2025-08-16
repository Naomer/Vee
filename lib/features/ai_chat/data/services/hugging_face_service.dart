import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  final String apiKey;
  final String modelId;
  final String apiUrl;

  HuggingFaceService({
    required this.apiKey,
    this.modelId = 'mistralai/Mistral-7B-Instruct-v0.3',
    this.apiUrl = 'https://api-inference.huggingface.co/models',
  });

  Future<String> generateResponse(String prompt) async {
    try {
      final url = '$apiUrl/$modelId';
      print('Making API call to: $url');
      print('With prompt: $prompt');

      // Format the prompt for Mistral
      final formattedPrompt =
          '''<s>[INST] You are a helpful AI assistant. Please provide a clear and concise response to the following question or request:

$prompt [/INST]''';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': formattedPrompt,
          'parameters': {
            'max_new_tokens': 250,
            'temperature': 0.7,
            'top_p': 0.95,
            'do_sample': true,
            'return_full_text': false,
          },
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        if (responseData.isNotEmpty &&
            responseData[0] is Map<String, dynamic>) {
          final generatedText = responseData[0]['generated_text'] ??
              'Sorry, I could not generate a response.';
          // Clean up the response by removing any remaining prompt markers
          return generatedText
              .replaceAll(RegExp(r'\[/INST\]|\[INST\]'), '')
              .trim();
        }
        return 'Sorry, I could not generate a response.';
      } else if (response.statusCode == 503) {
        // Model is loading
        return 'The AI model is currently loading. Please try again in a few seconds.';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in generateResponse: $e');
      throw Exception('Error generating response: $e');
    }
  }
}
