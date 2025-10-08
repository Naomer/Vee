import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String modelId;
  final String apiUrl;

  OpenRouterService({
    required this.apiKey,
    this.modelId = 'google/gemini-2.0-flash-001',
    this.apiUrl = 'https://openrouter.ai/api/v1/chat/completions',
  });

  Stream<String> generateStreamingResponse(
    String prompt, {
    List<Map<String, String>>? conversationHistory,
    String? preferredModelId, // if provided, try this first
    void Function(String usedModelId)?
        onModelSelected, // reports actual model used
  }) async* {
    try {
      if (apiKey.trim().isEmpty) {
        throw Exception('OpenRouter API key is empty.');
      }

      final url = Uri.parse(apiUrl);
      print('Making API call to: $url');
      print('With prompt: $prompt');
      print('Using API key: ${apiKey.substring(0, 10)}...');

      final headers = {
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'HTTP-Referer': 'https://github.com/yourusername/your-repo',
        'X-Title': 'Cosmos Viewer',
        'User-Agent': 'Cosmos-Viewer/1.0',
      };

      // Build conversation history once, avoid duplicating the latest user prompt
      final baseMessages = <Map<String, String>>[];
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        baseMessages.addAll(conversationHistory);
      }
      final bool lastIsSameUserPrompt = baseMessages.isNotEmpty &&
          baseMessages.last['role'] == 'user' &&
          baseMessages.last['content'] == prompt;
      if (!lastIsSameUserPrompt) {
        baseMessages.add({"role": "user", "content": prompt});
      }

      // Try preferred model (if provided), then sensible fallbacks
      final candidateModels = <String>[];
      if (preferredModelId != null && preferredModelId.trim().isNotEmpty) {
        // User selected a specific model - try it first, then fallback to working models
        candidateModels.add(preferredModelId.trim());
        candidateModels.addAll({
          'google/gemini-2.0-flash-001',
          'google/gemini-flash-1.5',
          'google/gemini-pro-1.5',
          'mistralai/mistral-7b-instruct',
          'meta-llama/llama-3.1-8b-instruct',
          'qwen/qwen2.5-7b-instruct',
          'microsoft/phi-3-mini-128k-instruct',
        });
      } else {
        // Auto mode - use default order
        candidateModels.addAll({
          modelId,
          'google/gemini-2.0-flash-001',
          'google/gemini-flash-1.5',
          'google/gemini-pro-1.5',
          'mistralai/mistral-7b-instruct',
          'meta-llama/llama-3.1-8b-instruct',
          'qwen/qwen2.5-7b-instruct',
          'microsoft/phi-3-mini-128k-instruct',
        });
      }

      http.StreamedResponse? response;
      http.Client? activeClient;
      String? usedModel;
      for (final candidate in candidateModels) {
        usedModel = candidate;
        final body = jsonEncode({
          "model": usedModel,
          "stream": true,
          "messages": baseMessages,
        });
        print('Request body: $body');

        final request = http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = body;

        final client = http.Client();
        response = await client.send(request);
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        if (response.statusCode == 200) {
          // Keep this client open while we consume the SSE stream
          activeClient = client;
          break;
        }

        final errorBody = await response.stream.bytesToString();
        print('API Error: ${response.statusCode} - $errorBody');

        // If invalid model or no endpoint, try next candidate
        final lowerError = errorBody.toLowerCase();
        if (response.statusCode == 400 &&
            lowerError.contains('not a valid model id')) {
          print('Model $usedModel invalid on OpenRouter, trying next...');
          continue;
        }
        if (response.statusCode == 404 &&
            lowerError.contains('no endpoints found')) {
          print('No endpoints for $usedModel, trying next...');
          continue;
        }

        // Close client before throwing/continuing on errors
        try {
          client.close();
        } catch (_) {}

        // Other errors: throw immediately
        if (response.statusCode == 401) {
          throw Exception(
              'Failed to generate response: 401 Unauthorized. Check your API key.');
        }
        throw Exception('Failed to generate response: ${response.statusCode}');
      }

      if (response == null || response.statusCode != 200) {
        throw Exception('Failed to generate response: no working model found');
      }

      print('Using model: $usedModel');
      print('User selected: ${preferredModelId ?? "auto"}');
      if (usedModel != null && onModelSelected != null) {
        onModelSelected(usedModel);
      }

      if (response.statusCode == 200) {
        print('Starting to read streaming response...');
        int chunkCount = 0;
        bool receivedDone = false;
        try {
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            chunkCount++;
            print('Received chunk $chunkCount: ${chunk.length} characters');

            // Split the chunk by newlines to handle multiple JSON objects
            final lines = chunk.split('\n');
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              if (line.trim() == 'data: [DONE]') {
                print('Received [DONE] signal');
                receivedDone = true;
                break; // stop processing more lines
              }

              // Skip OpenRouter processing status messages
              if (line.startsWith(': OPENROUTER PROCESSING') ||
                  line.startsWith(': OPENROUTER')) {
                print('Skipping status: $line');
                continue;
              }

              try {
                // Remove the "data: " prefix if present
                final jsonStr =
                    line.startsWith('data: ') ? line.substring(6) : line;
                print('Parsing JSON: $jsonStr');
                final jsonData = jsonDecode(jsonStr);
                if (jsonData['choices'] != null &&
                    jsonData['choices'].isNotEmpty &&
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  final content = jsonData['choices'][0]['delta']['content'];
                  if (content is String && content.trim().isNotEmpty) {
                    print('Yielding content: $content');
                    yield content;
                  } else {
                    // Skip empty/whitespace-only deltas
                    continue;
                  }
                }
              } catch (e) {
                // Only print errors for non-status lines
                if (!line.startsWith(':')) {
                  print('Error parsing chunk: $e');
                  print('Problematic chunk: $line');
                }
              }
            }

            if (receivedDone) {
              break; // exit the stream loop
            }
          }
        } catch (e) {
          // Treat premature connection close as natural end of stream
          final isClientException =
              e.runtimeType.toString() == 'ClientException';
          if (isClientException) {
            print('Stream closed by server, finishing gracefully.');
          } else {
            rethrow;
          }
        } finally {
          // Now it's safe to close the active client used for streaming
          try {
            activeClient?.close();
          } catch (_) {}
        }
        print('Finished reading streaming response. Total chunks: $chunkCount');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('API Error: ${response.statusCode} - $errorBody');
        if (response.statusCode == 401) {
          throw Exception(
              'Failed to generate response: 401 Unauthorized. Check your API key.');
        }
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in generateStreamingResponse: $e');
      throw Exception('Error generating response: $e');
    }
  }
}
