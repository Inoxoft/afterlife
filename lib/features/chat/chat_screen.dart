import 'package:flutter/material.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import 'package:afterlife/features/character_interview/chat_service.dart';
import 'package:afterlife/features/character_interview/chat_bubble.dart';
import 'package:afterlife/features/character_interview/message_model.dart';
import 'package:afterlife/features/character_storage/character_storage.dart';
import 'package:afterlife/features/models/character_model.dart';

class ChatScreen extends StatefulWidget {
  final String characterId;
  final String characterName;

  const ChatScreen({
    Key? key,
    required this.characterId,
    required this.characterName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  CharacterModel? _character;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize chat service
      await ChatService.initialize();

      // Load character data
      if (widget.characterId.isNotEmpty) {
        _character = await CharacterStorage.getCharacter(widget.characterId);
      }

      // Add initial greeting
      _addAIMessage(_getGreeting());

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          Message(text: "Error initializing chat: $e", isUser: false),
        );
      });
    }
  }

  String _getGreeting() {
    if (_character != null) {
      return "Hello! I'm ${_character!.name}. What would you like to talk about today?";
    } else if (widget.characterId == 'einstein') {
      return "Hello there! I'm Albert Einstein. What aspect of physics or life philosophy would you like to discuss today?";
    } else if (widget.characterId == 'frida') {
      return "Hola! I'm Frida Kahlo. Would you like to discuss art, my life experiences, or my perspective on pain and beauty?";
    } else if (widget.characterId == 'jobs') {
      return "Hi, I'm Steve Jobs. Let's talk about innovation, design, or how to think differently.";
    } else if (widget.characterId == 'curie') {
      return "Greetings! I'm Marie Curie. I'd be happy to discuss science, radioactivity, or my experiences as a woman in science during my time.";
    } else {
      return "Hello! I'm ${widget.characterName}. How can I help you today?";
    }
  }

  void _addAIMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Add user message
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      String systemPrompt = "";

      if (_character != null) {
        systemPrompt = _character!.systemPrompt;
      } else {
        // Hard-coded system prompts for famous characters
        if (widget.characterId == 'einstein') {
          systemPrompt =
              "You are Albert Einstein, the renowned physicist and Nobel Prize winner. You speak with a German accent and frequently use scientific metaphors. You're curious, brilliant, and have a wry sense of humor. You simplify complex ideas without talking down to people. You're passionate about pacifism and humanitarian causes.";
        } else if (widget.characterId == 'frida') {
          systemPrompt =
              "You are Frida Kahlo, the Mexican painter known for your self-portraits and works inspired by Mexico. You speak directly and passionately, often using colorful language and vivid imagery. Your perspective is shaped by physical suffering, your Mexican heritage, and your strong political convictions. You're bold, unapologetic, and deeply introspective.";
        } else if (widget.characterId == 'jobs') {
          systemPrompt =
              "You are Steve Jobs, co-founder of Apple and Pixar. You speak with conviction and intensity. You value simplicity, craftsmanship, and innovation above all. You're opinionated, demanding, and have little patience for mediocrity. You believe in pushing boundaries and thinking differently. You often speak in short, powerful sentences and aren't afraid to be controversial.";
        } else if (widget.characterId == 'curie') {
          systemPrompt =
              "You are Marie Curie, pioneering physicist and chemist who conducted groundbreaking research on radioactivity. You're the first woman to win a Nobel Prize and the only person to win in multiple scientific fields. You speak with precision and thoughtfulness. You're dedicated, persistent, and humble about your achievements. You believe in the pursuit of knowledge above recognition.";
        } else {
          systemPrompt =
              "You are ${widget.characterName}, having a conversation with a user.";
        }
      }

      final response = await ChatService.sendMessage(
        messages: [
          {"role": "user", "content": text},
        ],
        systemPrompt: systemPrompt,
      );

      if (response != null) {
        _addAIMessage(response);
      } else {
        _addAIMessage("I'm sorry, I couldn't process your message.");
      }
    } catch (e) {
      _addAIMessage("I apologize, but there was an error: $e");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _character?.name ?? widget.characterName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundStart,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            const Opacity(
              opacity: 0.5,
              child: AnimatedParticles(
                particleCount: 30,
                particleColor: Colors.white,
                minSpeed: 0.01,
                maxSpeed: 0.03,
              ),
            ),
            Column(
              children: [
                // Chat messages
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ChatBubble(
                                message: message,
                                showAvatar: !message.isUser,
                                avatarText:
                                    message.isUser
                                        ? "You"
                                        : (_character?.name.isNotEmpty ?? false
                                            ? _character!.name[0].toUpperCase()
                                            : widget.characterName[0]
                                                .toUpperCase()),
                              );
                            },
                          ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isSending ? Colors.grey : AppTheme.accentColor,
                        ),
                        child: IconButton(
                          icon:
                              _isSending
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.send),
                          color: Colors.white,
                          onPressed: _isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
