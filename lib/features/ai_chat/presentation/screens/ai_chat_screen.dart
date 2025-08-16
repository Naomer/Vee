import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/open_router_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isRecording = false;
  bool isSpeechAvailable = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastWords = '';
  final String _currentLocaleId = 'en_US';
  late final OpenRouterService openRouterService;
  String _currentStreamingResponse = '';
  bool _isStreaming = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {}); // Rebuild when text changes
    });
    _initSpeech();
    openRouterService = OpenRouterService(
      apiKey:
          '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',
    );

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
    controller.dispose();
    scrollController.dispose();
    _speech.stop();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({'text': text, 'isUser': true});
      messages.add({'text': '', 'isUser': false});
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
      await for (final chunk
          in openRouterService.generateStreamingResponse(text)) {
        setState(() {
          _currentStreamingResponse += chunk;
          // Update the last message with the current streaming response
          messages.last = {'text': _currentStreamingResponse, 'isUser': false};
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
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      setState(() {
        messages.last = {
          'text': 'Sorry, I encountered an error. Please try again.',
          'isUser': false
        };
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

  Widget buildMessage(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF2F2F2))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? Radius.zero : null,
                  bottomLeft: !isUser ? Radius.zero : null,
                ),
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
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.blueAccent),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
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
                    title: const Text(
                      'Vee AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                title: const Text(
                  'Vee AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 80, bottom: 16),
              itemCount: messages.length,
              itemBuilder: (_, index) => buildMessage(messages[index]),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onSubmitted: sendMessage,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText:
                                isRecording ? "Listening..." : "Ask anything",
                            hintStyle: TextStyle(
                              color: isRecording
                                  ? Colors.red
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (controller.text.isNotEmpty) {
                            sendMessage(controller.text);
                          } else if (isSpeechAvailable) {
                            toggleRecording();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isRecording
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !isSpeechAvailable || controller.text.isNotEmpty
                                ? Icons.arrow_upward_rounded
                                : (isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded),
                            color: isRecording
                                ? Colors.white
                                : (isDark ? Colors.black87 : Colors.white),
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
    );
  }
}
