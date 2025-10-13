import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/services/open_router_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isRecording = false;
  bool isSpeechAvailable = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  String _lastWords = '';
  late final OpenRouterService openRouterService;
  bool _isSpeaking = false;
  String _currentStreamingResponse = '';
  bool _isStreaming = false;
  StreamSubscription<String>? _currentStreamSubscription;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  String _modelSelection = 'auto';
  String? _activeModelId;
  bool _showScrollToBottom = false;
  Timer? _scrollDebounceTimer;
  final List<Map<String, String>> _modelOptions = [
    {'label': 'Auto', 'id': 'auto'},
    {'label': 'Gemini 2.0 Flash', 'id': 'google/gemini-2.0-flash-001'},
    {'label': 'Gemini Flash 1.5', 'id': 'google/gemini-flash-1.5'},
    {'label': 'Gemini Pro 1.5', 'id': 'google/gemini-pro-1.5'},
    {'label': 'Llama 3.1 8B', 'id': 'meta-llama/llama-3.1-8b-instruct'},
    {'label': 'Mistral 7B', 'id': 'mistralai/mistral-7b-instruct'},
    {'label': 'Qwen 2.5 7B', 'id': 'qwen/qwen2.5-7b-instruct'},
    {'label': 'Phi-3 Mini', 'id': 'microsoft/phi-3-mini-128k-instruct'},
  ];
  final FocusNode inputFocusNode = FocusNode();

  // Action button functions
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareText(String text) {
    // Simple share implementation using clipboard for now
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard for sharing'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _likeMessage(int index) {
    // Toggle like status
    setState(() {
      if (messages[index]['isLiked'] == true) {
        messages[index]['isLiked'] = false;
      } else {
        messages[index]['isLiked'] = true;
        messages[index]['isDisliked'] = false; // Remove dislike if liked
      }
    });
  }

  void _dislikeMessage(int index) {
    // Toggle dislike status
    setState(() {
      if (messages[index]['isDisliked'] == true) {
        messages[index]['isDisliked'] = false;
      } else {
        messages[index]['isDisliked'] = true;
        messages[index]['isLiked'] = false; // Remove like if disliked
      }
    });
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      await _flutterTts.speak(text);
    }
  }

  void _closeKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    inputFocusNode.unfocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Close keyboard when returning to the app
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeKeyboard();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(() {
      setState(() {}); // Rebuild when text changes
    });
    _initSpeech();
    _initTts();
    final key =
        dotenv.isInitialized ? (dotenv.env['OPENROUTER_API_KEY'] ?? '') : '';
    openRouterService = OpenRouterService(apiKey: key);

    // Initialize typing animation
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Ensure keyboard is closed on screen start or hot restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeKeyboard();
    });

    // Add scroll listener to track scroll position with debouncing
    scrollController.addListener(() {
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          final isAtBottom = scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100;
          if (_showScrollToBottom != !isAtBottom) {
            setState(() {
              _showScrollToBottom = !isAtBottom;
            });
          }
        }
      });
    });
  }

  Future<void> _initSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() {
          isSpeechAvailable = false;
        });
        return;
      }

      bool available = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            isSpeechAvailable = false;
            isRecording = false;
          });
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done') {
            setState(() {
              isRecording = false;
            });
          }
        },
        debugLogging: true,
      );

      setState(() {
        isSpeechAvailable = available;
      });
    } catch (e) {
      print('Error initializing speech recognition: $e');
      setState(() {
        isSpeechAvailable = false;
      });
    }
  }

  void toggleRecording() async {
    if (!isSpeechAvailable) {
      // Just focus the text field if speech is not available
      FocusScope.of(context).requestFocus(FocusNode());
      return;
    }

    try {
      if (!isRecording) {
        setState(() {
          isRecording = true;
          _lastWords = '';
        });

        await _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                controller.text = _lastWords;
                isRecording = false;
              }
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US',
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } else {
        setState(() {
          isRecording = false;
        });
        await _speech.stop();
      }
    } catch (e) {
      print('Error in speech recognition: $e');
      setState(() {
        isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounceTimer?.cancel();
    controller.dispose();
    inputFocusNode.dispose();
    scrollController.dispose();
    _speech.stop();
    _flutterTts.stop();
    _typingAnimationController.dispose();
    _currentStreamSubscription?.cancel();
    super.dispose();
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // If already streaming, cancel the current stream first
    if (_isStreaming) {
      _currentStreamSubscription?.cancel();
      setState(() {
        _isStreaming = false;
        _currentStreamingResponse = '';
      });
    }

    // Dismiss keyboard on send
    FocusScope.of(context).unfocus();
    setState(() {
      messages.add({'text': text, 'isUser': true});
      messages.add(
          {'text': '', 'isUser': false, 'isLiked': false, 'isDisliked': false});
      _isStreaming = true;
      _currentStreamingResponse = '';
    });

    controller.clear();

    // Scroll to bottom after adding messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      print('Starting to listen for streaming response...');

      // Convert messages to conversation history format for the API
      List<Map<String, String>> conversationHistory = [];
      String? lastRole;
      String? lastContent;
      for (int i = 0; i < messages.length - 1; i++) {
        // Exclude the empty AI message we just added
        final message = messages[i];
        final rawText = (message['text'] ?? '').toString();
        final text = rawText.trim();
        if (text.isEmpty) continue; // skip empty/whitespace messages

        final role = message['isUser'] == true ? 'user' : 'assistant';

        // Dedupe consecutive identical messages
        if (lastRole == role && lastContent == text) continue;

        conversationHistory.add({"role": role, "content": text});
        lastRole = role;
        lastContent = text;
      }

      print(
          'Sending conversation history: ${conversationHistory.length} messages');

      final preferred = _modelSelection == 'auto' ? null : _modelSelection;
      _currentStreamSubscription = openRouterService.generateStreamingResponse(
          text,
          conversationHistory: conversationHistory,
          preferredModelId: preferred, onModelSelected: (m) {
        if (_activeModelId != m) {
          setState(() => _activeModelId = m);
        }
      }).listen(
        (chunk) {
          if (!_isStreaming) return; // Cancel if streaming was stopped
          print('Received chunk in UI: $chunk');
          setState(() {
            _currentStreamingResponse += chunk;
            // Update the last message with the current streaming response
            messages.last = {
              'text': _currentStreamingResponse,
              'isUser': false,
              'isLiked': messages.last['isLiked'] ?? false
            };
          });

          // Scroll to bottom as new content arrives
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (error) {
          if (!_isStreaming) return; // Cancel if streaming was stopped
          print('Error in stream: $error');
          setState(() {
            if (_currentStreamingResponse.trim().isEmpty) {
              messages.last = {
                'text':
                    'Sorry, I encountered an error: ${error.toString()}. Please try again.',
                'isUser': false,
                'isLiked': false,
                'isDisliked': false
              };
            }
          });
        },
        onDone: () {
          if (!_isStreaming) return; // Cancel if streaming was stopped
          print('Stream completed');
        },
      );

      // Wait for the stream to complete
      await _currentStreamSubscription?.asFuture();
      print('Finished receiving streaming response');
    } catch (e) {
      print('Error in sendMessage: $e');
      setState(() {
        // If we already showed some content, keep it; otherwise, show error
        if (_currentStreamingResponse.trim().isEmpty) {
          messages.last = {
            'text':
                'Sorry, I encountered an error: ${e.toString()}. Please try again.',
            'isUser': false,
            'isLiked': false
          };
        }
      });
    } finally {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  Widget buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: _typingAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget buildMessage(Map<String, dynamic> msg, int index) {
    bool isUser = msg['isUser'];
    bool isLiked = msg['isLiked'] ?? false;
    bool isDisliked = msg['isDisliked'] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isUser
                        ? 29 * 8.0
                        : double.infinity, // 30 chars * ~8px per char
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: isUser ? 14 : 5, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark ? Colors.grey[900] : Colors.grey[200])
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: !isUser && msg['text'].isEmpty && _isStreaming
                      ? buildTypingIndicator()
                      : Text(
                          msg['text'],
                          style: TextStyle(
                            color: isUser
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white : Colors.black),
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
          // Action buttons for AI responses
          if (!isUser && msg['text'].isNotEmpty && !_isStreaming) ...[
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _copyToClipboard(msg['text']),
                    child: Transform.translate(
                      offset: const Offset(0, -17),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: PhosphorIcon(
                          PhosphorIcons.copySimple(),
                          size: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  // Like button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _likeMessage(index),
                    child: Transform.translate(
                      offset: const Offset(0, -17),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: PhosphorIcon(
                          PhosphorIcons.thumbsUp(),
                          size: 14,
                          color: isLiked
                              ? Colors.blue
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  // Dislike button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _dislikeMessage(index),
                    child: Transform.translate(
                      offset: const Offset(0, -17),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: PhosphorIcon(
                          PhosphorIcons.thumbsDown(),
                          size: 14,
                          color: isDisliked
                              ? Colors.red
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  // Speak button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _speakText(msg['text']),
                    child: Transform.translate(
                      offset: const Offset(0, -17),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: PhosphorIcon(
                          _isSpeaking
                              ? PhosphorIcons.stop()
                              : PhosphorIcons.speakerHigh(),
                          size: 14,
                          color: _isSpeaking
                              ? Colors.blue
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
        onWillPop: () async {
          _closeKeyboard();
          return true;
        },
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(40.0),
            child: isDark
                ? ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AppBar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        elevation: 0,
                        centerTitle: true,
                        toolbarHeight: 40,
                        titleSpacing: 0,
                        automaticallyImplyLeading: false,
                        title: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _modelSelection,
                                  isDense: true,
                                  icon: const SizedBox.shrink(),
                                  dropdownColor: Colors.black87,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  alignment: Alignment.center,
                                  selectedItemBuilder: (context) {
                                    return _modelOptions.map((opt) {
                                      final label = opt['label']!;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const _CaretIcon(
                                            color: Colors.white,
                                            down: true,
                                            size: 13,
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                  items: _modelOptions
                                      .map(
                                        (opt) => DropdownMenuItem<String>(
                                          value: opt['id'],
                                          child: Text(
                                            opt['label']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() => _modelSelection = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.white,
                    centerTitle: true,
                    toolbarHeight: 40,
                    titleSpacing: 0,
                    automaticallyImplyLeading: false,
                    title: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _modelSelection,
                              isDense: true,
                              icon: const SizedBox.shrink(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              alignment: Alignment.center,
                              selectedItemBuilder: (context) {
                                return _modelOptions.map((opt) {
                                  final label = opt['label']!;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const _CaretIcon(
                                        color: Colors.black,
                                        down: true,
                                        size: 14,
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                              items: _modelOptions
                                  .map(
                                    (opt) => DropdownMenuItem<String>(
                                      value: opt['id'],
                                      child: Text(
                                        opt['label']!,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _modelSelection = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          body: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(top: 80, bottom: 16),
                        itemCount: messages.length,
                        itemBuilder: (_, index) =>
                            buildMessage(messages[index], index),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 70),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 18),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end, // Align to bottom
                              children: [
                                // Controls moved to AppBar; keep only input row
                                Expanded(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 4 * 16 * 1.4 +
                                          24, // 4 lines max (fontSize * height * lines + padding)
                                      minHeight:
                                          1 * 16 * 1.4 + 24, // 1 line min
                                    ),
                                    child: SingleChildScrollView(
                                      child: TextField(
                                        controller: controller,
                                        focusNode: inputFocusNode,
                                        maxLines: null, // Allow unlimited lines
                                        minLines: 1, // Start with 1 line
                                        textInputAction: TextInputAction
                                            .newline, // Enter creates new line
                                        onSubmitted: (text) {
                                          // Only send on Ctrl+Enter or Cmd+Enter
                                          // For now, we'll handle this in the send button
                                        },
                                        onTapOutside: (_) {
                                          FocusScope.of(context).unfocus();
                                          SystemChannels.textInput
                                              .invokeMethod('TextInput.hide');
                                        },
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16,
                                            height: 1.4), // Better line height
                                        decoration: InputDecoration(
                                          hintText: isRecording
                                              ? "Listening..."
                                              : "Ask anything...",
                                          hintStyle: TextStyle(
                                            color: isRecording
                                                ? Colors.red
                                                : (isDark
                                                    ? Colors.white60
                                                    : Colors.black54),
                                            fontSize: 16,
                                            height: 1.4,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  onTap: () {
                                    if (_isStreaming) {
                                      // Stop current generation
                                      _currentStreamSubscription?.cancel();
                                      setState(() {
                                        _isStreaming = false;
                                      });
                                    } else if (controller.text.isNotEmpty) {
                                      sendMessage(controller.text);
                                    } else if (isSpeechAvailable) {
                                      toggleRecording();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isStreaming
                                          ? Colors.grey
                                          : (isRecording
                                              ? Colors.red
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isStreaming
                                          ? Icons.stop_rounded
                                          : (!isSpeechAvailable ||
                                                  controller.text.isNotEmpty
                                              ? Icons.arrow_upward_rounded
                                              : (isRecording
                                                  ? Icons.stop_rounded
                                                  : Icons.mic_rounded)),
                                      color: (_isStreaming || isRecording)
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.black87
                                              : Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating scroll to bottom button
              if (_showScrollToBottom)
                Positioned(
                  bottom: 160,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.caretDown(),
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }
}

class _CaretIcon extends StatelessWidget {
  final Color color;
  final bool down; // true = down caret, false = up caret
  final double size;

  const _CaretIcon({
    required this.color,
    required this.down,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Draw a simple chevron using CustomPaint to mimic Twitter/Cursor style
    return CustomPaint(
      size: Size.square(size),
      painter: _CaretPainter(color: color, down: down),
    );
  }
}

class _CaretPainter extends CustomPainter {
  final Color color;
  final bool down;

  _CaretPainter({required this.color, required this.down});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // Chevron points
    final Path path = Path();
    if (down) {
      // Draw a down-facing chevron: like "v"
      path.moveTo(w * 0.2, h * 0.35);
      path.lineTo(w * 0.5, h * 0.65);
      path.lineTo(w * 0.8, h * 0.35);
    } else {
      // Up-facing chevron: like "^"
      path.moveTo(w * 0.2, h * 0.65);
      path.lineTo(w * 0.5, h * 0.35);
      path.lineTo(w * 0.8, h * 0.65);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.down != down;
  }
}
